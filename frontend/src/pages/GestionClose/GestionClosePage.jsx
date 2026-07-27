import { useEffect, useState, useMemo } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { useToast } from "../../context/ToastContext";
import { SectionHeader, EmptyState } from "../../components/Common/Common";
import { generarReporteCierreGestion } from "../../utils/pdfReports";
import { NOTA_APROBACION } from "../../data/mockData";

export default function GestionClosePage() {
  const { session } = useAuth();
  const data = useData();
  const { showSuccess, showError } = useToast();

  const esDirector = session?.rolActivo === "DIRECTOR";
  const esAdmin = session?.rolActivo === "ADMINISTRADOR" || session?.rolActivo === "ADMIN";
  const tienePermiso = esDirector || esAdmin;

  const carrera = data.getCarrera(data.idCarreraActiva);
  const gestionActiva = data.getGestionActiva();

  // Formulario de Apertura de Gestión
  const [tipoPeriodo, setTipoPeriodo] = useState("II");
  const [anioPeriodo, setAnioPeriodo] = useState(2026);
  const [ejecutandoInicio, setEjecutandoInicio] = useState(false);

  // Cierre de Gestión
  const [confirmando, setConfirmando] = useState(false);
  const [previewData, setPreviewData] = useState(null);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [ejecutandoCierre, setEjecutandoCierre] = useState(false);

  // Forzar recarga de datos al montar la página para asegurar gestiones actualizadas
  useEffect(() => {
    data.reloadFromBackend();
  }, []);

  // Cargar previsualización de cierre al estar activa la gestión
  useEffect(() => {
    if (!gestionActiva || !tienePermiso || (gestionActiva.estado || '').toLowerCase() === "cerrada") return;
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

  // Validación cronológica en tiempo real
  const periodoTarget = `${tipoPeriodo}/${anioPeriodo}`;
  const hoy = new Date();
  const mesActual = hoy.getMonth() + 1; // 1=Enero, 2=Febrero, 7=Julio, 8=Agosto
  const anioActual = hoy.getFullYear();

  const mesesNombres = [
    "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ];

  const validacionApertura = useMemo(() => {
    const estadoActiva = (gestionActiva?.estado || '').toLowerCase() === 'activa';
    if (gestionActiva && estadoActiva) {
      return {
        valido: false,
        motivo: `Existe la gestión '${gestionActiva.periodo}' actualmente activa. Debe ejecutar el Cierre de Gestión antes de aperturar un nuevo periodo lectivo.`,
      };
    }

    const yaExisteActiva = (data.gestiones || []).some(
      (g) => g.periodo === periodoTarget && (g.estado || '').toLowerCase() === 'activa'
    );
    if (yaExisteActiva) {
      return {
        valido: false,
        motivo: `La gestión '${periodoTarget}' ya se encuentra actualmente activa en el sistema.`,
      };
    }

    return {
      valido: true,
      motivo: `Requisitos validados correctamente. Se aperturará la gestión '${periodoTarget}' y se generarán automáticamente los paralelos A en todas las materias.`,
    };
  }, [gestionActiva, periodoTarget, data.gestiones]);

  // Ejecutar Apertura de Gestión
  const handleIniciarGestion = async () => {
    if (!validacionApertura.valido) {
      showError(validacionApertura.motivo);
      return;
    }

    setEjecutandoInicio(true);
    try {
      const res = await data.iniciarGestion(periodoTarget);
      showSuccess(res.message || `¡Gestión ${periodoTarget} aperturada exitosamente!`);
    } catch (err) {
      showError(err?.response?.data?.error || err.message || "Error al aperturar la gestión.");
    } finally {
      setEjecutandoInicio(false);
    }
  };

  // Ejecutar Cierre Definitivo
  const confirmarCierre = async () => {
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
        <div className="page-card" style={{ background: "#fee2e2", color: "#991b1b", border: "1px solid #fca5a5" }}>
          <p style={{ margin: 0, fontWeight: 700 }}>
            ⛔ La Apertura y Cierre de Gestión Académica es potestad exclusiva de la Dirección de Carrera o Administración del Sistema.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <SectionHeader
        title="Apertura y Cierre de Gestión Académica"
        subtitle={`Panel de Control Académico — Carrera: ${carrera.nombre}`}
        actions={
          gestionActiva && (
            <button
              className="button secondary"
              onClick={exportar}
              disabled={previsualizacion.length === 0}
              style={{ fontWeight: 600 }}
            >
              📄 Exportar Acta Oficial (PDF)
            </button>
          )
        }
      />

      {/* BANNER PRINCIPAL: Estado del Periodo Lectivo Activo */}
      <div
        className="page-card"
        style={{
          marginBottom: 20,
          background: (gestionActiva?.estado || '').toLowerCase() === "activa"
            ? "linear-gradient(135deg, #0b223d, #1d4ed8)"
            : "linear-gradient(135deg, #334155, #0f172a)",
          color: "#ffffff",
          padding: 24,
          boxShadow: "0 10px 25px rgba(11, 34, 61, 0.25)",
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 16 }}>
          <div>
            <span style={{ fontSize: "0.78rem", textTransform: "uppercase", letterSpacing: "0.08em", color: "#93c5fd", fontWeight: 800 }}>
              ESTADO DEL PERIODO LECTIVO ACTUAL
            </span>
            <h2 style={{ margin: "4px 0 6px", fontSize: "1.6rem", fontWeight: 800, color: "#ffffff" }}>
              {gestionActiva ? `Gestión Académica ${gestionActiva.periodo}` : "Sin Gestión Activa en Curso"}
            </h2>
            <p style={{ margin: 0, fontSize: "0.9rem", color: "#e2e8f0", maxWidth: 620 }}>
              {(gestionActiva?.estado || '').toLowerCase() === "activa"
                ? "El periodo lectivo se encuentra habilitado para auto-inscripciones, registro de materias y carga de ponderaciones por los docentes."
                : "No existe una gestión activa actualmente. Seleccione el nuevo periodo lectivo a continuación para realizar la apertura."}
            </p>
          </div>

          <div>
            <span
              style={{
                background: (gestionActiva?.estado || '').toLowerCase() === "activa" ? "#10b981" : "#ef4444",
                color: "#ffffff",
                fontWeight: 800,
                fontSize: "0.95rem",
                padding: "8px 18px",
                borderRadius: 30,
                display: "inline-block",
                boxShadow: "0 4px 12px rgba(0,0,0,0.2)"
              }}
            >
              {(gestionActiva?.estado || '').toLowerCase() === "activa" ? "● PERIODO ACTIVO" : "● GESTIÓN CERRADA"}
            </span>
          </div>
        </div>
      </div>

      {/* BLOQUE 1: APERTURA DE NUEVA GESTIÓN */}
      <div className="page-card" style={{ marginBottom: 24, borderTop: "4px solid #1d4ed8" }}>
        <SectionHeader
          title="🚀 Aperturar Nuevo Periodo Lectivo"
          subtitle="Aperture una nueva gestión académica con creación automática del Paralelo A para todas las materias del pensum"
        />

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 16, marginTop: 14 }}>
          <div>
            <label style={{ fontSize: "0.85rem", fontWeight: 700, color: "#334155", display: "block", marginBottom: 6 }}>
              Tipo de Periodo Académico:
            </label>
            <select
              value={tipoPeriodo}
              onChange={(e) => setTipoPeriodo(e.target.value)}
              style={{ width: "100%", padding: "10px 12px", borderRadius: 8, border: "1px solid #cbd5e1", fontSize: "0.92rem", fontWeight: 600 }}
            >
              <option value="I">I — Primer Semestre (Min. Febrero)</option>
              <option value="II">II — Segundo Semestre (Min. Agosto)</option>
              <option value="Verano">Verano — Temporada Enero</option>
              <option value="Invierno">Invierno — Temporada Julio</option>
            </select>
          </div>

          <div>
            <label style={{ fontSize: "0.85rem", fontWeight: 700, color: "#334155", display: "block", marginBottom: 6 }}>
              Año Lectivo:
            </label>
            <input
              type="number"
              value={anioPeriodo}
              onChange={(e) => setAnioPeriodo(Number(e.target.value))}
              min={2026}
              max={2035}
              style={{ width: "100%", padding: "10px 12px", borderRadius: 8, border: "1px solid #cbd5e1", fontSize: "0.92rem", fontWeight: 600 }}
            />
          </div>

          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <button
              className="button primary"
              onClick={handleIniciarGestion}
              disabled={!validacionApertura.valido || ejecutandoInicio}
              style={{
                width: "100%",
                height: 42,
                fontSize: "0.95rem",
                fontWeight: 700,
                background: validacionApertura.valido ? "#1d4ed8" : "#94a3b8",
                borderColor: validacionApertura.valido ? "#1d4ed8" : "#94a3b8"
              }}
            >
              {ejecutandoInicio ? "Aperturando y Generando Paralelos..." : `🚀 Iniciar Gestión ${periodoTarget}`}
            </button>
          </div>
        </div>

        {/* Notificación Contextual de Validación */}
        <div
          style={{
            marginTop: 16,
            padding: "14px 18px",
            borderRadius: 10,
            background: validacionApertura.valido ? "#f0fdf4" : "#fef2f2",
            border: `1px solid ${validacionApertura.valido ? "#86efac" : "#fca5a5"}`,
            color: validacionApertura.valido ? "#166534" : "#991b1b",
          }}
        >
          <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
            <span style={{ fontSize: "1.3rem" }}>{validacionApertura.valido ? "✅" : "⚠️"}</span>
            <div style={{ flex: 1 }}>
              <strong style={{ fontSize: "0.92rem", display: "block", marginBottom: 2 }}>
                {validacionApertura.valido ? "Apertura Lista para Ejecutarse" : "Restricción de Apertura de Gestión"}
              </strong>
              <span style={{ fontSize: "0.88rem", lineHeight: 1.4 }}>{validacionApertura.motivo}</span>
              <div style={{ fontSize: "0.8rem", marginTop: 6, opacity: 0.85, borderTop: "1px dashed rgba(0,0,0,0.1)", paddingTop: 4 }}>
                📅 Verificación de calendario del sistema: <strong>{mesesNombres[mesActual]} {anioActual}</strong>.
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* BLOQUE 2: CIERRE DE GESTIÓN ACTIVA */}
      {gestionActiva && (gestionActiva.estado || '').toLowerCase() === "activa" && (
        <div className="page-card" style={{ borderTop: "4px solid #dc2626" }}>
          <SectionHeader
            title={`🔒 Cierre Definitivo de Gestión — ${gestionActiva.periodo}`}
            subtitle="Concluya el periodo lectivo, congele actas de notas y actualice automáticamente el expediente de todos los estudiantes"
            actions={
              <button
                className="button danger"
                onClick={() => setConfirmando(true)}
                disabled={ejecutandoCierre}
                style={{ fontWeight: 700 }}
              >
                🔒 Ejecutar Cierre Definitivo
              </button>
            }
          />

          {/* Tarjetas de Resumen Previo */}
          <div className="stats-grid" style={{ marginTop: 16, marginBottom: 20 }}>
            <div className="stat-card tone-blue">
              <div className="stat-icon">👥</div>
              <div>
                <p className="stat-value">{previsualizacion.length}</p>
                <p className="stat-label">Inscripciones Evaluadas</p>
              </div>
            </div>

            <div className="stat-card tone-green">
              <div className="stat-icon">🎓</div>
              <div>
                <p className="stat-value">{aprobados}</p>
                <p className="stat-label">Estudiantes Promovidos (≥ {NOTA_APROBACION} pts)</p>
              </div>
            </div>

            <div className="stat-card tone-red">
              <div className="stat-icon">⚠️</div>
              <div>
                <p className="stat-value">{reprobados}</p>
                <p className="stat-label">Estudiantes Reprobados</p>
              </div>
            </div>
          </div>

          <SectionHeader title="📋 Previsualización del Acta Consolidada de Notas" />

          {loadingPreview ? (
            <p className="activity-meta">Cargando borrador consolidado desde la base de datos...</p>
          ) : previsualizacion.length === 0 ? (
            <EmptyState text="No existen estudiantes matriculados con notas registradas en esta gestión activa." />
          ) : (
            <div className="table-responsive">
              <table className="table">
                <thead>
                  <tr>
                    <th>Estudiante</th>
                    <th>RU</th>
                    <th>Asignatura</th>
                    <th>Nota Final Proyectada</th>
                    <th>Estado Proyectado</th>
                  </tr>
                </thead>
                <tbody>
                  {previsualizacion.map((p, idx) => (
                    <tr key={idx}>
                      <td><strong>{p.estudiante}</strong></td>
                      <td>{p.ru}</td>
                      <td><strong>{p.sigla_materia}</strong> — {p.materia}</td>
                      <td><strong>{Math.round((p.nota_final_proyectada || 0) * 100) / 100} pts</strong></td>
                      <td>
                        <span className={`badge ${p.estado_proyectado === "Aprobado" ? "badge-success" : "badge-danger"}`}>
                          {p.estado_proyectado}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Modal de Confirmación de Cierre */}
      {confirmando && (
        <div className="modal-backdrop" onClick={() => setConfirmando(false)}>
          <div className="modal-card" style={{ maxWidth: 500 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ color: "#dc2626" }}>⚠️ Confirmar Cierre Definitivo de Gestión</h3>
            </div>
            <p style={{ fontSize: "0.92rem", color: "#334155", lineHeight: 1.5 }}>
              ¿Está completamente seguro de ejecutar el cierre irreversible de la gestión <strong>{gestionActiva?.periodo}</strong>?
            </p>
            <div style={{ padding: 12, borderRadius: 8, background: "#fef2f2", border: "1px solid #fca5a5", color: "#991b1b", fontSize: "0.85rem", marginBottom: 16 }}>
              Al confirmar, las notas proyectadas se congelarán en el expediente académico de todos los estudiantes y el periodo lectivo cambiará a estado <strong>Cerrado</strong>.
            </div>
            <div className="modal-actions">
              <button className="button secondary" onClick={() => setConfirmando(false)} disabled={ejecutandoCierre}>
                Cancelar
              </button>
              <button className="button danger" onClick={confirmarCierre} disabled={ejecutandoCierre} style={{ fontWeight: 700 }}>
                {ejecutandoCierre ? "Cerrando en Base de Datos..." : "Sí, Ejecutar Cierre Definitivo"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
