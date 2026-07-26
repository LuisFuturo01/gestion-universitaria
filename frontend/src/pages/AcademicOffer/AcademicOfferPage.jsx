import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { SectionHeader, EmptyState } from "../../components/Common/Common";

export const getTipoMateria = (sigla = "", nombre = "") => {
  if (!sigla || !nombre) return "Corriente";
  
  if (/^(TSI|TCS|TVD|TIE|TAW|TAM|TAR|TIOT|TRC|TAT|TCP|TSS)-/.test(sigla)) {
    return "Técnico Superior";
  }
  
  if (nombre.startsWith("Electiva ") || /-3[123]/.test(sigla) || /^(PER|AUD|RRPP)-E/.test(sigla)) {
    return "Optativa";
  }
  
  return "Corriente";
};

const TIPO_MATERIA_STYLES = {
  "Técnico Superior": { clase: "materia-tecnico", label: "Técnico Superior" },
  "Optativa": { clase: "materia-optativa", label: "Optativa" },
  "Corriente": { clase: "materia-corriente", label: "Corriente" },
};

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
  const esDocente = session?.rolActivo === "DOCENTE";

  const carrera = data.getCarrera(data.idCarreraActiva);
  const planesCarrera = data.getPlanesPorCarrera(carrera.id_carrera);

  const [idPlan, setIdPlan] = useState(planesCarrera[0]?.id_plan || 1);
  const [seleccionada, setSeleccionada] = useState(null);

  const gestionActiva = data.getGestionActiva();
  const planActual = planesCarrera.find((p) => p.id_plan === idPlan) || planesCarrera[0];

  const pensumCompleto = useMemo(() => (planActual ? data.getPensumPlan(planActual.id_plan) : []), [planActual, data]);

  // Clasificación de materias del pensum incorporando tipo_materia (Técnico Superior, Optativa, Corriente)
  const pensumClasificado = useMemo(() => {
    return pensumCompleto.map((pm) => ({
      ...pm,
      tipo_materia: getTipoMateria(pm.materia?.sigla, pm.materia?.nombre),
    }));
  }, [pensumCompleto]);

  // Si es docente, filtra las materias asignadas bajo su dictado
  const pensum = useMemo(() => {
    if (esDocente) {
      const misMateriaIds = data.paralelos
        .filter((p) => p.id_docente === session?.id_persona)
        .map((p) => p.id_materia);
      return pensumClasificado.filter((pm) => misMateriaIds.includes(pm.id_materia));
    }
    return pensumClasificado;
  }, [esDocente, pensumClasificado, data.paralelos, session]);

  const porSemestre = useMemo(() => {
    const grupos = {};
    pensum.forEach((m) => {
      grupos[m.semestre] = grupos[m.semestre] || [];
      grupos[m.semestre].push(m);
    });
    return grupos;
  }, [pensum]);

  const paralelosSeleccionada = seleccionada
    ? data.getParalelosOferta(seleccionada.id_materia, gestionActiva?.id_gestion || 1)
    : [];

  return (
    <div>
      <SectionHeader
        title={`Oferta Académica y Menciones — ${carrera.nombre}`}
        subtitle={
          esDocente
            ? `Malla curricular y asignaturas asignadas en ${carrera.nombre}`
            : esEstudiante
            ? `Plan de estudios por mención y mapa de avance curricular en ${carrera.nombre}`
            : `Mapeo estructural de Menciones y Malla Curricular Escalable en ${carrera.nombre}`
        }
        actions={
          <>
            {!esDocente && planesCarrera.length > 0 && (
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <label style={{ fontSize: "0.85rem", fontWeight: 600, color: "#3a4c66" }}>Seleccionar Mención:</label>
                <select value={planActual?.id_plan} onChange={(e) => setIdPlan(Number(e.target.value))}>
                  {planesCarrera.map((p) => (
                    <option key={p.id_plan} value={p.id_plan}>{p.nombre}</option>
                  ))}
                </select>
              </div>
            )}
          </>
        }
      />

      <div className="page-card" style={{ marginBottom: 16, background: "linear-gradient(90deg, #0d2748, #1a5fb4)", color: "#fff" }}>
        <h3 style={{ margin: "0 0 4px", fontSize: "1.1rem" }}>🎓 Mención: {planActual?.nombre || "Mención General de Carrera"}</h3>
        <p style={{ margin: 0, fontSize: "0.85rem", opacity: 0.9 }}>
          Carrera perteneciente: <strong>{carrera.nombre}</strong>
        </p>
      </div>

      {/* Leyenda de Clasificación por Tipo de Materia (Cuadros de Color Completo) */}
      <div className="legend-row" style={{ marginBottom: 16 }}>
        <span style={{ fontSize: "0.82rem", fontWeight: 700, color: "#7c8ba3", alignSelf: "center", marginRight: 6 }}>Tipos de Asignatura:</span>
        <span className="legend-chip materia-corriente">📘 Corriente</span>
        <span className="legend-chip materia-tecnico">🟣 Técnico Superior</span>
        <span className="legend-chip materia-optativa">📙 Optativa</span>
      </div>

      {esEstudiante && (
        <div className="legend-row" style={{ marginBottom: 16 }}>
          <span style={{ fontSize: "0.82rem", fontWeight: 700, color: "#7c8ba3", alignSelf: "center", marginRight: 6 }}>Estado personal:</span>
          {Object.entries(ESTADO_INFO).map(([key, info]) => (
            <span key={key} className={`legend-chip ${info.clase}`}>{info.label}</span>
          ))}
        </div>
      )}

      {Object.keys(porSemestre).length === 0 ? (
        <EmptyState text={esDocente ? "No tiene asignaturas registradas para dictar en esta carrera." : "Esta mención aún no tiene asignaturas en el pensum."} />
      ) : (
        Object.entries(porSemestre)
          .sort(([a], [b]) => a - b)
          .map(([semestre, materias]) => (
            <div key={semestre} className="page-card semester-block">
              <h3 className="semester-title">Semestre {semestre}</h3>
              <div className="materia-grid">
                {materias.map((m) => {
                  const estadoEstudiante = esEstudiante
                    ? data.getEstadoMateriaParaEstudiante(session.id_persona, m.id_materia)
                    : null;
                  const claseEstado = estadoEstudiante ? ESTADO_INFO[estadoEstudiante].clase : "";
                  const tipoStyle = TIPO_MATERIA_STYLES[m.tipo_materia] || TIPO_MATERIA_STYLES["Corriente"];
                  const oferta = data.getParalelosOferta(m.id_materia, gestionActiva?.id_gestion || 1);

                  return (
                    <button
                      key={m.id_materia}
                      className={`materia-card ${tipoStyle.clase} ${claseEstado}`}
                      onClick={() => setSeleccionada(m)}
                      type="button"
                    >
                      <span className={`tipo-tag ${tipoStyle.clase}`}>
                        {m.tipo_materia}
                      </span>
                      <strong>{m.materia?.sigla}</strong>
                      <span>{m.materia?.nombre}</span>
                      <small>{m.materia?.creditos || m.materia?.carga_horaria} hrs · {oferta.length} paralelo(s)</small>
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
              <h3>{seleccionada.materia?.sigla} — {seleccionada.materia?.nombre}</h3>
              <button className="link-button" onClick={() => setSeleccionada(null)}>Cerrar ✕</button>
            </div>
            <div style={{ marginBottom: 12 }}>
              <span className={`tipo-tag ${TIPO_MATERIA_STYLES[getTipoMateria(seleccionada.materia?.sigla, seleccionada.materia?.nombre)].clase}`}>
                Tipo: {getTipoMateria(seleccionada.materia?.sigla, seleccionada.materia?.nombre)}
              </span>
              <p className="activity-meta" style={{ marginTop: 6, margin: 0 }}>
                Mención: <strong>{planActual?.nombre}</strong> · Carrera: <strong>{carrera.nombre}</strong>
              </p>
            </div>
            {paralelosSeleccionada.length === 0 ? (
              <EmptyState text="No hay paralelos aperturados para esta asignatura." />
            ) : (
              <table className="table">
                <thead><tr><th>Paralelo</th><th>Docente Asignado</th><th>Horario y Aula</th><th>Cupo</th></tr></thead>
                <tbody>
                  {paralelosSeleccionada.map((p) => (
                    <tr key={p.id_paralelo}>
                      <td><strong>Paralelo {p.nombre}</strong></td>
                      <td>{p.docenteNombre}</td>
                      <td>
                        {p.horario
                          ? `${data.horarios.find((h) => h.id_horario === p.horario.id_horario)?.dia || ''} ${data.horarios.find((h) => h.id_horario === p.horario.id_horario)?.hora_inicio || ''}`
                          : "Aula / Horario a definir"}
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
