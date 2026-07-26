import { useEffect, useState, useMemo } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { useToast } from "../../context/ToastContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { generarReporteCierreGestion } from "../../utils/pdfReports";
import { NOTA_APROBACION } from "../../data/mockData";

export default function GestionClosePage() {
  const { session } = useAuth();
  const data = useData();
  const { showSuccess, showError } = useToast();

  const esDirector = session?.rolActivo === "DIRECTOR";
  const esAdmin = session?.rolActivo === "ADMINISTRADOR";
  const tienePermiso = esDirector || esAdmin;

  const carrera = data.getCarrera(data.idCarreraActiva);
  const gestionActiva = data.getGestionActiva();

  // Estados del Formulario de Apertura de Gestión
  const [tipoPeriodo, setTipoPeriodo] = useState("II");
  const [anioPeriodo, setAnioPeriodo] = useState(2026);
  const [ejecutandoInicio, setEjecutandoInicio] = useState(false);

  // Estados de Cierre de Gestión
  const [confirmando, setConfirmando] = useState(false);
  const [previewData, setPreviewData] = useState(null);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [ejecutandoCierre, setEjecutandoCierre] = useState(false);

  // Cargar previsualización de cierre desde sp_preview_cierre_gestion al montar
  useEffect(() => {
    if (!gestionActiva || !tienePermiso || gestionActiva.estado === "Cerrada") return;
    let cancelado = false;

    const cargarPreview = async () => {
      setLoadingPreview(true);
      try {
        const resultado = await data.previewCierreGestion(gestionActiva.id_gestion);
        if (!cancelado) setPreviewData(resultado);
      } catch (e) {
        console.warn("Preview cierre:", e.message);
      } finally {
        if (!cancelado) setLoadingPreview(false);
      }
    };

    cargarPreview();
    return () => {
      cancelado = true;
    };
  }, [gestionActiva?.id_gestion, tienePermiso]);

  const resumen = previewData?.resumen || {};
  const previsualizacion = previewData?.detalle || [];
  const aprobados = resumen.aprobados || previsualizacion.filter((p) => p.estado_proyectado === "Aprobado").length;
  const reprobados = resumen.reprobados || previsualizacion.filter((p) => p.estado_proyectado === "Reprobado").length;

  // Validación de Fecha del Sistema en tiempo real
  const periodoTarget = `${tipoPeriodo}/${anioPeriodo}`;
  const hoy = new Date();
  const mesActual = hoy.getMonth() + 1; // 1=Enero, 2=Febrero, 7=Julio, 8=Agosto
  const anioActual = hoy.getFullYear();

  const mesesNombres = [
    "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ];

  const validacionApertura = useMemo(() => {
    // 1. Hay gestión activa sin cerrar
    if (gestionActiva && gestionActiva.estado === "Activa") {
      return {
        valido: false,
        motivo: `Existe la gestión '${gestionActiva.periodo}' actualmente activa. Debe ejecutar el Cierre de Gestión antes de aperturar una nueva.`,
      };
    }

    // 2. Ya existe la gestión con el mismo código de periodo
    const yaExiste = data.gestiones.some((g) => g.periodo === periodoTarget);
    if (yaExiste) {
      return {
        valido: false,
        motivo: `La gestión '${periodoTarget}' ya ha sido registrada anteriormente en la carrera ${carrera.nombre}.`,
      };
    }

    // 3. Validación Cronológica según la fecha del sistema
    if (tipoPeriodo === "I" && mesActual < 2 && anioPeriodo <= anioActual) {
      return {
        valido: false,
        motivo: `El primer semestre (I/${anioPeriodo}) solo puede aperturarse a partir de FEBRERO (Mes actual: ${mesesNombres[mesActual]}).`,
      };
    }
    if (tipoPeriodo === "II" && mesActual < 8 && anioPeriodo <= anioActual) {
      return {
        valido: false,
        motivo: `El segundo semestre (II/${anioPeriodo}) solo puede aperturarse a partir de AGOSTO (Mes actual: ${mesesNombres[mesActual]}).`,
      };
    }
    if (tipoPeriodo === "Verano" && mesActual !== 1 && anioPeriodo <= anioActual) {
      return {
        valido: false,
        motivo: `La temporada de Verano (${periodoTarget}) solo se puede aperturar en ENERO (Mes actual: ${mesesNombres[mesActual]}).`,
      };
    }
    if (tipoPeriodo === "Invierno" && mesActual !== 7 && anioPeriodo <= anioActual) {
      return {
        valido: false,
        motivo: `La temporada de Invierno (${periodoTarget}) solo se puede aperturar en JULIO (Mes actual: ${mesesNombres[mesActual]}).`,
      };
    }

    return {
      valido: true,
      motivo: `Cumple los requisitos cronológicos y la oferta de paralelos (Paralelo A por materia) está lista para ser creada automáticamente.`,
    };
  }, [gestionActiva, periodoTarget, tipoPeriodo, anioPeriodo, mesActual, anioActual, data.gestiones, carrera.nombre]);

  // Ejecutar Apertura de Gestión y Generación Automática de Paralelos
  const handleIniciarGestion = async () => {
    if (!validacionApertura.valido) {
      showError(validacionApertura.motivo);
      return;
    }

    setEjecutandoInicio(true);
    try {
      const res = await data.iniciarGestion(periodoTarget);
      showSuccess(res.message || `¡Gestión ${periodoTarget} iniciada con éxito! Se aperturó automáticamente 1 paralelo por materia.`);
    } catch (err) {
      showError(err?.response?.data?.error || err.message || "Error al iniciar la gestión.");
    } finally {
      setEjecutandoInicio(false);
    }
  };

  // Ejecutar Cierre Definitivo de Gestión
  const confirmarCierre = async () => {
    if (!tienePermiso) {
      showError("Acceso denegado: Acción reservada exclusivamente para Dirección de Carrera.");
      return;
    }
    setEjecutandoCierre(true);
    try {
      await data.cerrarGestion(gestionActiva.id_gestion);
      showSuccess(`¡La gestión ${gestionActiva.periodo} ha sido cerrada de forma irreversible!`);
      setConfirmando(false);
      setPreviewData(null);
    } catch (e) {
      showError(`Error al cerrar la gestión: ${e?.response?.data?.error || e.message}`);
    } finally {
      setEjecutandoCierre(false);
    }
  };

  const exportar = () => {
    generarReporteCierreGestion({
      periodo: gestionActiva?.periodo || "I/2026",
      filas: previsualizacion.map((p) => ({
        estudiante: p.estudiante,
        ru: p.ru,
        materia: `${p.sigla_materia} — ${p.materia}`,
        nota_final: p.nota_final_proyectada,
        estado: p.estado_proyectado,
      })),
      resumen: { aprobados, reprobados, total: previsualizacion.length },
    });
  };

  if (!tienePermiso) {
    return (
      <div>
        <SectionHeader title="Acceso Restringido — Gestión Académica" />
        <div className="page-card" style={{ background: "#fdeaea", color: "#b3271f", border: "1px solid #f3c4c1" }}>
          <p style={{ margin: 0, fontWeight: 600 }}>
            ⛔ La Apertura y Cierre de Gestión Académica es potestad exclusiva del Director de Carrera o Administrador del sistema.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <SectionHeader
        title="Apertura y Cierre de Gestión Académica"
        subtitle={`Dirección y Coordinación Académica — Carrera: ${carrera.nombre}`}
        actions={
          <div style={{ display: "flex", gap: 8 }}>
            {gestionActiva && (
              <button className="link-button" onClick={exportar} disabled={previsualizacion.length === 0}>
                ⬇ Exportar Acta Cierre (PDF)
              </button>
            )}
          </div>
        }
      />

      {/* Banner de Estado de la Gestión Actual */}
      <div
        className="page-card"
        style={{
          marginBottom: 20,
          background: gestionActiva?.estado === "Activa"
            ? "linear-gradient(135deg, #0b2239 0%, #154577 100%)"
            : "linear-gradient(135deg, #2d1810 0%, #632617 100%)",
          color: "#fff",
          boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
          <div>
            <span style={{ fontSize: "0.8rem", textTransform: "uppercase", tracking: 1, opacity: 0.85, fontWeight: 700 }}>
              Estado Actual del Periodo Lectivo
            </span>
            <h2 style={{ margin: "4px 0 2px", fontSize: "1.5rem", fontWeight: 800 }}>
              {gestionActiva ? `Gestión Académica ${gestionActiva.periodo}` : "Sin Gestión Activa en Curso"}
            </h2>
            <p style={{ margin: 0, fontSize: "0.88rem", opacity: 0.9 }}>
              {gestionActiva?.estado === "Activa"
                ? "Las inscripciones, calificaciones y registro de ponderaciones se encuentran abiertos."
                : "No existe una gestión activa actualmente. Habilite un nuevo periodo lectivo a continuación."}
            </p>
          </div>
          <div>
            <Badge style={{ fontSize: "0.9rem", padding: "6px 14px", background: gestionActiva?.estado === "Activa" ? "#2ecc71" : "#e74c3c" }}>
              {gestionActiva?.estado || "Sin gestión"}
            </Badge>
          </div>
        </div>
      </div>

      {/* SECCIÓN 1: APERTURA Y HABILITACIÓN DE NUEVA GESTIÓN */}
      <div className="page-card" style={{ marginBottom: 24, borderLeft: "4px solid #1a5fb4" }}>
        <SectionHeader
          title="🚀 Apertura de Nueva Gestión y Habilitación de Paralelos"
          subtitle="Permite aperturar una nueva gestión y generar automáticamente un Paralelo A para cada asignatura respetando el cupo de aula"
        />

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", gap: 16, marginTop: 16 }}>
          <div>
            <label style={{ fontSize: "0.85rem", fontWeight: 700, color: "#3a4c66", display: "block", marginBottom: 6 }}>
              Tipo de Periodo Lectivo:
            </label>
            <select
              value={tipoPeriodo}
              onChange={(e) => setTipoPeriodo(e.target.value)}
              style={{ width: "100%", padding: "10px 12px", borderRadius: 8, border: "1px solid #cbd5e1", fontSize: "0.95rem" }}
            >
              <option value="I">I — Primer Semestre (Min. Febrero)</option>
              <option value="II">II — Segundo Semestre (Min. Agosto)</option>
              <option value="Verano">Verano — Temporada de Enero</option>
              <option value="Invierno">Invierno — Temporada de Julio</option>
            </select>
          </div>

          <div>
            <label style={{ fontSize: "0.85rem", fontWeight: 700, color: "#3a4c66", display: "block", marginBottom: 6 }}>
              Año Académico:
            </label>
            <input
              type="number"
              value={anioPeriodo}
              onChange={(e) => setAnioPeriodo(Number(e.target.value))}
              min={2026}
              max={2035}
              style={{ width: "100%", padding: "10px 12px", borderRadius: 8, border: "1px solid #cbd5e1", fontSize: "0.95rem" }}
            />
          </div>

          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <button
              className="primary-button"
              onClick={handleIniciarGestion}
              disabled={!validacionApertura.valido || ejecutandoInicio}
              style={{ width: "100%", height: 42, fontSize: "0.92rem", fontWeight: 700, background: validacionApertura.valido ? "#1a5fb4" : "#94a3b8" }}
            >
              {ejecutandoInicio ? "Iniciando y Creando Paralelos..." : `🚀 Iniciar Gestión ${periodoTarget}`}
            </button>
          </div>
        </div>

        {/* Panel Informativo de Validación Cronológica en Tiempo Real */}
        <div
          style={{
            marginTop: 16,
            padding: 14,
            borderRadius: 8,
            background: validacionApertura.valido ? "#f0fdf4" : "#fef2f2",
            border: `1px solid ${validacionApertura.valido ? "#bbf7d0" : "#fecaca"}`,
            color: validacionApertura.valido ? "#166534" : "#991b1b",
          }}
        >
          <div style={{ display: "flex", alignItems: "flex-start", gap: 10 }}>
            <span style={{ fontSize: "1.2rem" }}>{validacionApertura.valido ? "✅" : "⚠️"}</span>
            <div>
              <strong style={{ fontSize: "0.9rem", display: "block" }}>
                {validacionApertura.valido ? "Requisitos de Apertura Cumplidos" : "Restricción de Apertura de Gestión"}
              </strong>
              <span style={{ fontSize: "0.85rem" }}>{validacionApertura.motivo}</span>
              <div style={{ fontSize: "0.78rem", marginTop: 4, opacity: 0.85 }}>
                📅 Fecha de verificación del sistema: <strong>{mesesNombres[mesActual]} {anioActual}</strong>.
                Regla: <em>Semestre I (Febrero+), Semestre II (Agosto+), Verano (Enero), Invierno (Julio).</em>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* SECCIÓN 2: CIERRE DE GESTIÓN ACTIVA */}
      {gestionActiva && gestionActiva.estado === "Activa" && (
        <div className="page-card" style={{ borderLeft: "4px solid #d97706" }}>
          <SectionHeader
            title={`🔒 Cierre de Gestión Académica Activa — ${gestionActiva.periodo}`}
            subtitle="Concluye la gestión, calcula notas finales ponderadas congelando actas y actualiza los historiales de los estudiantes"
            actions={
              <button
                className="primary-button"
                onClick={() => setConfirmando(true)}
                disabled={ejecutandoCierre}
                style={{ background: "#dc2626" }}
              >
                🔒 Ejecutar Cierre Definitivo
              </button>
            }
          />

          <div style={{ marginBottom: 16, fontSize: "0.88rem", color: "#475569" }}>
            Al ejecutar el cierre de la gestión <strong>{gestionActiva.periodo}</strong>, el procedimiento transaccional de MySQL
            (<code>sp_cerrar_gestion</code>) asentará automáticamente el estado <Badge>Aprobado</Badge> (nota ≥ {NOTA_APROBACION}) o
            {" "}<Badge>Reprobado</Badge> para todos los estudiantes inscritos.
          </div>

          <SectionHeader title="Previsualización del Acta Final de Notas (sp_preview_cierre_gestion)" />

          {loadingPreview ? (
            <p className="activity-meta">Cargando previsualización del acta desde la base de datos...</p>
          ) : previsualizacion.length === 0 ? (
            <EmptyState text="No existen estudiantes inscritos en esta gestión activa." />
          ) : (
            <table className="table" style={{ marginTop: 8 }}>
              <thead>
                <tr>
                  <th>Estudiante</th>
                  <th>RU</th>
                  <th>Asignatura</th>
                  <th>Nota Proyectada</th>
                  <th>Estado Final</th>
                </tr>
              </thead>
              <tbody>
                {previsualizacion.map((p, idx) => (
                  <tr key={idx}>
                    <td><strong>{p.estudiante}</strong></td>
                    <td>{p.ru}</td>
                    <td>{p.sigla_materia} — {p.materia}</td>
                    <td><strong>{Math.round((p.nota_final_proyectada || 0) * 100) / 100} pts</strong></td>
                    <td>
                      <span className={`badge ${p.estado_proyectado === "Aprobado" ? "materia-green" : "materia-red"}`}>
                        {p.estado_proyectado}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Modal de Confirmación de Cierre */}
      {confirmando && (
        <div className="modal-backdrop" onClick={() => setConfirmando(false)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Confirmar Cierre Definitivo de Gestión</h3>
            </div>
            <p>
              ¿Está completamente seguro de ejecutar el cierre de la gestión <strong>{gestionActiva?.periodo}</strong>?
              Esta acción es irreversible y asentará las notas finales calculadas en el historial académico de todos los estudiantes.
            </p>
            <div className="modal-actions">
              <button className="link-button" onClick={() => setConfirmando(false)} disabled={ejecutandoCierre}>
                Cancelar
              </button>
              <button className="primary-button" onClick={confirmarCierre} disabled={ejecutandoCierre} style={{ background: "#dc2626" }}>
                {ejecutandoCierre ? "Cerrando gestión en MySQL..." : "Sí, Ejecutar Cierre Definitivo"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
