import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { SectionHeader, EmptyState } from "../../components/Common/Common";

const ESTADO_INFO = {
  aprobada: { label: "Aprobada", clase: "materia-green" },
  cursando: { label: "Cursando", clase: "materia-yellow" },
  reprobada: { label: "Reprobada", clase: "materia-red" },
  pendiente: { label: "Por cursar", clase: "materia-blue" },
};

export default function AcademicOfferPage() {
  const { session } = useAuth();
  const data = useData();
  const esEstudiante = session?.rolActivo === "ESTUDIANTE";

  const [idCarrera, setIdCarrera] = useState(null);
  const [idGestion, setIdGestion] = useState(null);
  const [seleccionada, setSeleccionada] = useState(null);

  const carreraSeleccionada = idCarrera || data.carreras[0]?.id_carrera || 1;
  const gestionSeleccionada = idGestion || data.getGestionActiva()?.id_gestion || data.gestiones[0]?.id_gestion || 1;

  const plan = data.planes.find((p) => p.id_carrera === carreraSeleccionada) || data.planes[0];
  const pensum = useMemo(() => (plan ? data.getPensumPlan(plan.id_plan) : []), [plan, data]);

  const porSemestre = useMemo(() => {
    const grupos = {};
    pensum.forEach((m) => {
      grupos[m.semestre] = grupos[m.semestre] || [];
      grupos[m.semestre].push(m);
    });
    return grupos;
  }, [pensum]);

  const paralelosSeleccionada = seleccionada
    ? data.getParalelosOferta(seleccionada.id_materia, gestionSeleccionada)
    : [];

  return (
    <div>
      <SectionHeader
        title="Oferta Académica"
        subtitle="Pensum por mención, gestión y semestre"
        actions={
          <>
            <select value={carreraSeleccionada} onChange={(e) => setIdCarrera(Number(e.target.value))}>
              {data.carreras.map((c) => (
                <option key={c.id_carrera} value={c.id_carrera}>{c.nombre}</option>
              ))}
            </select>
            <select value={gestionSeleccionada} onChange={(e) => setIdGestion(Number(e.target.value))}>
              {data.gestiones.map((g) => (
                <option key={g.id_gestion} value={g.id_gestion}>{g.periodo} {g.estado === "Activa" ? "(activa)" : ""}</option>
              ))}
            </select>
          </>
        }
      />

      {esEstudiante && (
        <div className="legend-row">
          {Object.entries(ESTADO_INFO).map(([key, info]) => (
            <span key={key} className={`legend-chip ${info.clase}`}>{info.label}</span>
          ))}
        </div>
      )}

      {Object.keys(porSemestre).length === 0 ? (
        <EmptyState text="Esta carrera aún no tiene materias asignadas en el pensum." />
      ) : (
        Object.entries(porSemestre)
          .sort(([a], [b]) => a - b)
          .map(([semestre, materias]) => (
            <div key={semestre} className="page-card semester-block">
              <h3 className="semester-title">Semestre {semestre}</h3>
              <div className="materia-grid">
                {materias.map((m) => {
                  const estado = esEstudiante
                    ? data.getEstadoMateriaParaEstudiante(session.estudiante.id_persona, m.id_materia)
                    : null;
                  const clase = estado ? ESTADO_INFO[estado].clase : "materia-neutral";
                  const oferta = data.getParalelosOferta(m.id_materia, gestionSeleccionada);
                  return (
                    <button
                      key={m.id_materia}
                      className={`materia-card ${clase}`}
                      onClick={() => setSeleccionada(m)}
                      type="button"
                    >
                      <strong>{m.materia.sigla}</strong>
                      <span>{m.materia.nombre}</span>
                      <small>{m.materia.creditos || m.materia.carga_horaria} hrs · {oferta.length} paralelo(s)</small>
                    </button>
                  );
                })}
              </div>
            </div>
          ))
      )}

      {seleccionada && (
        <div className="modal-backdrop" onClick={() => setSeleccionada(null)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{seleccionada.materia.sigla} — {seleccionada.materia.nombre}</h3>
              <button className="link-button" onClick={() => setSeleccionada(null)}>Cerrar ✕</button>
            </div>
            {paralelosSeleccionada.length === 0 ? (
              <EmptyState text="No hay paralelos ofertados para esta gestión." />
            ) : (
              <table className="table">
                <thead><tr><th>Paralelo</th><th>Docente</th><th>Horario</th><th>Cupo disponible</th></tr></thead>
                <tbody>
                  {paralelosSeleccionada.map((p) => (
                    <tr key={p.id_paralelo}>
                      <td>{p.nombre}</td>
                      <td>{p.docenteNombre}</td>
                      <td>
                        {p.horario
                          ? `${data.horarios.find((h) => h.id_horario === p.horario.id_horario)?.dia || ''} ${data.horarios.find((h) => h.id_horario === p.horario.id_horario)?.hora_inicio || ''}`
                          : "Por definir"}
                      </td>
                      <td>{p.cupo_disponible} / {p.cupo_maximo}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
