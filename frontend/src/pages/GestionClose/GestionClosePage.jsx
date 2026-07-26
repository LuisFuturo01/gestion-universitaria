import { useEffect, useState } from "react";
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

  const gestionActiva = data.getGestionActiva();
  const [confirmando, setConfirmando] = useState(false);
  const [previewData, setPreviewData] = useState(null);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [ejecutandoCierre, setEjecutandoCierre] = useState(false);

  // Cargar previsualización desde sp_preview_cierre_gestion al montar
  useEffect(() => {
    if (!gestionActiva || !esDirector || gestionActiva.estado === "Cerrada") return;
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
    return () => { cancelado = true; };
  }, [gestionActiva?.id_gestion, esDirector]);

  const resumen = previewData?.resumen || {};
  const previsualizacion = previewData?.detalle || [];
  const aprobados = resumen.aprobados || previsualizacion.filter((p) => p.estado_proyectado === "Aprobado").length;
  const reprobados = resumen.reprobados || previsualizacion.filter((p) => p.estado_proyectado === "Reprobado").length;

  const confirmarCierre = async () => {
    if (!esDirector) {
      showError("Acceso denegado: El Cierre de Gestión es potestad exclusiva del Director de Carrera.");
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

  if (!esDirector) {
    return (
      <div>
        <SectionHeader title="Acceso Restringido — Cierre de Gestión" />
        <div className="page-card" style={{ background: "#fdeaea", color: "#b3271f", border: "1px solid #f3c4c1" }}>
          <p style={{ margin: 0, fontWeight: 600 }}>
            ⛔ El cierre de gestión académica es potestad académica exclusiva del Director de Carrera. El rol Administrador no posee permisos de acceso a este módulo.
          </p>
        </div>
      </div>
    );
  }

  if (!gestionActiva) {
    return (
      <div>
        <SectionHeader title="Cierre de Gestión Académica" />
        <EmptyState text="No hay una gestión activa en este momento." />
      </div>
    );
  }

  return (
    <div>
      <SectionHeader
        title="Cierre de Gestión y Generación de Actas"
        subtitle={`Autorización académica exclusiva del Director de Carrera — Gestión: ${gestionActiva.periodo}`}
        actions={
          <>
            <button className="link-button" onClick={exportar} disabled={previsualizacion.length === 0}>⬇ Exportar Acta Final PDF</button>
            <button className="primary-button" onClick={() => setConfirmando(true)} disabled={gestionActiva.estado === "Cerrada" || ejecutandoCierre}>
              {gestionActiva.estado === "Cerrada" ? "Gestión ya cerrada" : "🔒 Ejecutar Cierre de Gestión"}
            </button>
          </>
        }
      />

      <div className="page-card" style={{ marginBottom: 16 }}>
        <p>
          Al ejecutar el cierre de la gestión <strong>{gestionActiva.periodo}</strong>, el sistema calculará automáticamente la
          <strong> nota final</strong> de cada estudiante en base a los criterios de evaluación registrados por los
          docentes, asignará el estado <Badge>Aprobado</Badge> (nota ≥ {NOTA_APROBACION}) o <Badge>Reprobado</Badge>
          {" "}y bloqueará irreversiblemente el registro de nuevas notas.
        </p>
        <p className="activity-meta">
          Resumen proyectado: <strong>{resumen.total || previsualizacion.length}</strong> estudiantes — <strong>{aprobados}</strong> aprobados, <strong>{reprobados}</strong> reprobados
        </p>
      </div>

      <div className="page-card">
        <SectionHeader title="Previsualización del acta de cierre de notas (sp_preview_cierre_gestion)" />
        {loadingPreview ? (
          <p className="activity-meta">Cargando previsualización desde MySQL...</p>
        ) : previsualizacion.length === 0 ? (
          <EmptyState text="No hay inscripciones registradas en esta gestión." />
        ) : (
          <table className="table">
            <thead><tr><th>Estudiante</th><th>RU</th><th>Materia</th><th>Nota Proyectada</th><th>Estado Final</th></tr></thead>
            <tbody>
              {previsualizacion.map((p, idx) => (
                <tr key={idx}>
                  <td>{p.estudiante}</td>
                  <td>{p.ru}</td>
                  <td>{p.sigla_materia} — {p.materia}</td>
                  <td><strong>{Math.round((p.nota_final_proyectada || 0) * 100) / 100} pts</strong></td>
                  <td><Badge>{p.estado_proyectado}</Badge></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {confirmando && (
        <div className="modal-backdrop" onClick={() => setConfirmando(false)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header"><h3>Confirmar cierre definitivo de gestión</h3></div>
            <p>
              ¿Está seguro de cerrar la gestión <strong>{gestionActiva.periodo}</strong>? Se congelará el periodo
              y los estudiantes con nota ≥ 51 quedarán asentados como Aprobados en el historial académico.
            </p>
            <div className="modal-actions">
              <button className="link-button" onClick={() => setConfirmando(false)} disabled={ejecutandoCierre}>Cancelar</button>
              <button className="primary-button" onClick={confirmarCierre} disabled={ejecutandoCierre}>
                {ejecutandoCierre ? "Cerrando gestión..." : "Sí, ejecutar cierre"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
