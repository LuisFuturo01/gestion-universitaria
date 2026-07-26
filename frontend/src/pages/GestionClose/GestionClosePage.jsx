import { useMemo, useState } from "react";
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

  const inscritosGestion = useMemo(() => {
    if (!gestionActiva) return [];
    const idsIns = data.inscripciones.filter((i) => i.id_gestion === gestionActiva.id_gestion).map((i) => i.id_inscripcion);
    return data.detalle.filter((d) => idsIns.includes(d.id_inscripcion));
  }, [data, gestionActiva]);

  const previsualizacion = useMemo(() => {
    return inscritosGestion.map((d) => {
      const insc = data.inscripciones.find((i) => i.id_inscripcion === d.id_inscripcion);
      const persona = data.getPersona(insc?.id_estudiante);
      const materia = data.getMateria(d.id_materia);
      const notaProyectada = d.estado === "Inscrito" ? data.calcularNotaFinal(d.id_materia, d.id_paralelo, d.id_detalle) : d.nota_final;
      const estadoProyectado = d.estado === "Inscrito" ? (notaProyectada >= NOTA_APROBACION ? "Aprobado" : "Reprobado") : d.estado;
      return { estudiante: `${persona.nombres} ${persona.apellidos}`, ru: `RU-${insc?.id_estudiante || 1}`, materia: `${materia?.sigla} — ${materia?.nombre}`, nota_final: notaProyectada, estado: estadoProyectado, yaCerrado: d.estado !== "Inscrito" };
    });
  }, [inscritosGestion, data]);

  const pendientes = previsualizacion.filter((p) => !p.yaCerrado);
  const aprobados = previsualizacion.filter((p) => p.estado === "Aprobado").length;
  const reprobados = previsualizacion.filter((p) => p.estado === "Reprobado").length;

  const confirmarCierre = () => {
    if (!esDirector) {
      showError("Acceso denegado: El Cierre de Gestión es potestad exclusiva del Director de Carrera.");
      return;
    }
    data.cerrarGestion(gestionActiva.id_gestion);
    showSuccess(`¡La gestión ${gestionActiva.periodo} ha sido cerrada de forma irreversible!`);
    setConfirmando(false);
  };

  const exportar = () => {
    generarReporteCierreGestion({
      periodo: gestionActiva?.periodo || "I/2026",
      filas: previsualizacion,
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
            <button className="link-button" onClick={exportar}>⬇ Exportar Acta Final PDF</button>
            <button className="primary-button" onClick={() => setConfirmando(true)} disabled={gestionActiva.estado === "Cerrada"}>
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
        <p className="activity-meta">Registros pendientes de cierre final: {pendientes.length} de {previsualizacion.length}</p>
      </div>

      <div className="page-card">
        <SectionHeader title="Previsualización del acta de cierre de notas" />
        {previsualizacion.length === 0 ? (
          <EmptyState text="No hay inscripciones registradas en esta gestión." />
        ) : (
          <table className="table">
            <thead><tr><th>Estudiante</th><th>RU</th><th>Materia</th><th>Nota Proyectada</th><th>Estado Final</th></tr></thead>
            <tbody>
              {previsualizacion.map((p, idx) => (
                <tr key={idx}>
                  <td>{p.estudiante}</td>
                  <td>{p.ru}</td>
                  <td>{p.materia}</td>
                  <td><strong>{p.nota_final} pts</strong></td>
                  <td><Badge>{p.estado}</Badge></td>
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
              <button className="link-button" onClick={() => setConfirmando(false)}>Cancelar</button>
              <button className="primary-button" onClick={confirmarCierre}>Sí, ejecutar cierre</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
