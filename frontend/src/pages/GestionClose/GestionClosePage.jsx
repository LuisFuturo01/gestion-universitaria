import { useMemo, useState } from "react";
import { useData } from "../../context/DataContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { generarReporteCierreGestion } from "../../utils/pdfReports";
import { NOTA_APROBACION } from "../../data/mockData";

export default function GestionClosePage() {
  const data = useData();
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
      const persona = data.getPersona(insc.id_estudiante);
      const materia = data.getMateria(d.id_materia);
      const notaProyectada = d.estado === "Inscrito" ? data.calcularNotaFinal(d.id_materia, d.id_paralelo, d.id_detalle) : d.nota_final;
      const estadoProyectado = d.estado === "Inscrito" ? (notaProyectada >= NOTA_APROBACION ? "Aprobado" : "Reprobado") : d.estado;
      return { estudiante: `${persona.nombres} ${persona.apellidos}`, ru: data.estudiantes.find((e) => e.id_persona === insc.id_estudiante)?.ru, materia: `${materia.sigla} — ${materia.nombre}`, nota_final: notaProyectada, estado: estadoProyectado, yaCerrado: d.estado !== "Inscrito" };
    });
  }, [inscritosGestion, data]);

  const pendientes = previsualizacion.filter((p) => !p.yaCerrado);
  const aprobados = previsualizacion.filter((p) => p.estado === "Aprobado").length;
  const reprobados = previsualizacion.filter((p) => p.estado === "Reprobado").length;

  const confirmarCierre = () => {
    data.cerrarGestion(gestionActiva.id_gestion);
    setConfirmando(false);
  };

  const exportar = () => {
    generarReporteCierreGestion({
      periodo: gestionActiva.periodo,
      filas: previsualizacion,
      resumen: { aprobados, reprobados, total: previsualizacion.length },
    });
  };

  if (!gestionActiva) {
    return (
      <div>
        <SectionHeader title="Cierre de Gestión" />
        <EmptyState text="No hay una gestión activa en este momento." />
      </div>
    );
  }

  return (
    <div>
      <SectionHeader
        title="Cierre de Gestión"
        subtitle={`Gestión activa: ${gestionActiva.periodo}`}
        actions={
          <>
            <button className="link-button" onClick={exportar}>⬇ Exportar acta PDF</button>
            <button className="primary-button" onClick={() => setConfirmando(true)} disabled={pendientes.length === 0}>
              🔒 Cerrar gestión
            </button>
          </>
        }
      />

      <div className="page-card" style={{ marginBottom: 16 }}>
        <p>
          Al cerrar la gestión <strong>{gestionActiva.periodo}</strong>, el sistema calculará automáticamente la
          <strong> nota final</strong> de cada estudiante en base a los criterios de evaluación registrados por los
          docentes, asignará el estado <Badge>Aprobado</Badge> (nota ≥ {NOTA_APROBACION}) o <Badge>Reprobado</Badge>
          {" "}y bloqueará el registro de nuevas notas para este periodo. Esta acción no se puede deshacer.
        </p>
        <p className="activity-meta">Registros pendientes de cierre: {pendientes.length} de {previsualizacion.length}</p>
      </div>

      <div className="page-card">
        <SectionHeader title="Previsualización del acta de cierre" />
        {previsualizacion.length === 0 ? (
          <EmptyState text="No hay inscripciones registradas en esta gestión." />
        ) : (
          <table className="table">
            <thead><tr><th>Estudiante</th><th>RU</th><th>Materia</th><th>Nota proyectada</th><th>Estado proyectado</th></tr></thead>
            <tbody>
              {previsualizacion.map((p, idx) => (
                <tr key={idx}>
                  <td>{p.estudiante}</td>
                  <td>{p.ru}</td>
                  <td>{p.materia}</td>
                  <td>{p.nota_final}</td>
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
            <div className="modal-header"><h3>Confirmar cierre de gestión</h3></div>
            <p>
              ¿Está seguro de cerrar la gestión <strong>{gestionActiva.periodo}</strong>? Se finalizarán {pendientes.length} registros
              y no podrán modificarse las notas después de esta acción.
            </p>
            <div className="modal-actions">
              <button className="link-button" onClick={() => setConfirmando(false)}>Cancelar</button>
              <button className="primary-button" onClick={confirmarCierre}>Sí, cerrar gestión</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
