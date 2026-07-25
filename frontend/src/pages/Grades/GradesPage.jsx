import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { SectionHeader, EmptyState, Badge } from "../../components/Common/Common";

export default function GradesPage() {
  const { session } = useAuth();
  const data = useData();

  if (session.rolActivo === "DOCENTE") return <VistaDocente session={session} data={data} />;
  if (session.rolActivo === "ESTUDIANTE") return <VistaEstudianteNotas session={session} data={data} />;
  return <VistaSupervisor data={data} />;
}

function VistaDocente({ session, data }) {
  const gestionActiva = data.getGestionActiva();
  const misParalelos = data.paralelos.filter(
    (p) => p.id_docente === session.id_persona && p.id_gestion === gestionActiva?.id_gestion
  );
  const [seleccion, setSeleccion] = useState(misParalelos[0] || null);
  const [nuevoCriterio, setNuevoCriterio] = useState({ nombre: "", ponderacion: "" });

  if (!seleccion) return (
    <div>
      <SectionHeader title="Notas y Ponderaciones" subtitle="No tiene paralelos asignados en la gestión activa" />
      <EmptyState text="Cuando se le asigne un paralelo, podrá definir las ponderaciones y registrar notas aquí." />
    </div>
  );

  const materia = data.getMateria(seleccion.id_materia);
  const criterios = data.criterios.filter((c) => c.id_materia === seleccion.id_materia && c.id_paralelo === seleccion.id_paralelo);
  const sumaPonderacion = criterios.reduce((acc, c) => acc + c.ponderacion, 0);

  const inscritos = data.detalle
    .filter((d) => d.id_materia === seleccion.id_materia && d.id_paralelo === seleccion.id_paralelo)
    .map((d) => {
      const insc = data.inscripciones.find((i) => i.id_inscripcion === d.id_inscripcion);
      const persona = data.getPersona(insc.id_estudiante);
      return { detalle: d, persona };
    });

  const agregarCriterio = (e) => {
    e.preventDefault();
    const pond = Number(nuevoCriterio.ponderacion);
    if (!nuevoCriterio.nombre || !pond || pond <= 0) return alert("Complete nombre y ponderación válidos.");
    if (sumaPonderacion + pond > 100) return alert(`La suma de ponderaciones no puede superar 100 (actual: ${sumaPonderacion}).`);
    data.crearCriterio(seleccion.id_materia, seleccion.id_paralelo, nuevoCriterio.nombre, pond);
    setNuevoCriterio({ nombre: "", ponderacion: "" });
  };

  return (
    <div>
      <SectionHeader
        title="Notas y Ponderaciones"
        subtitle="Defina los criterios de evaluación de su paralelo y registre las notas obtenidas"
        actions={
          <select
            value={`${seleccion.id_materia}-${seleccion.id_paralelo}`}
            onChange={(e) => {
              const [im, ip] = e.target.value.split("-").map(Number);
              setSeleccion(misParalelos.find((p) => p.id_materia === im && p.id_paralelo === ip));
            }}
          >
            {misParalelos.map((p) => {
              const m = data.getMateria(p.id_materia);
              return <option key={`${p.id_materia}-${p.id_paralelo}`} value={`${p.id_materia}-${p.id_paralelo}`}>{m.sigla} - Paralelo {p.nombre}</option>;
            })}
          </select>
        }
      />

      <div className="page-card" style={{ marginBottom: 20 }}>
        <SectionHeader title={`Criterios de evaluación — ${materia.sigla}`} subtitle={`Suma actual: ${sumaPonderacion} / 100 puntos`} />
        <table className="table" style={{ marginBottom: 16 }}>
          <thead><tr><th>Criterio</th><th>Ponderación</th><th></th></tr></thead>
          <tbody>
            {criterios.map((c) => (
              <tr key={c.id_criterio}>
                <td>{c.nombre}</td>
                <td>{c.ponderacion} pts</td>
                <td><button className="link-button danger" onClick={() => data.eliminarCriterio(c.id_criterio)}>Eliminar</button></td>
              </tr>
            ))}
          </tbody>
        </table>
        <form className="inline-form" onSubmit={agregarCriterio}>
          <input placeholder="Nombre (ej. 1er Parcial)" value={nuevoCriterio.nombre} onChange={(e) => setNuevoCriterio({ ...nuevoCriterio, nombre: e.target.value })} />
          <input type="number" placeholder="Ponderación" value={nuevoCriterio.ponderacion} onChange={(e) => setNuevoCriterio({ ...nuevoCriterio, ponderacion: e.target.value })} min="1" max="100" />
          <button className="primary-button small" type="submit">+ Agregar criterio</button>
        </form>
      </div>

      <div className="page-card">
        <SectionHeader title="Registro de notas" />
        {inscritos.length === 0 || criterios.length === 0 ? (
          <EmptyState text={criterios.length === 0 ? "Defina al menos un criterio para registrar notas." : "No hay estudiantes inscritos."} />
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th>Estudiante</th>
                  {criterios.map((c) => <th key={c.id_criterio}>{c.nombre} ({c.ponderacion})</th>)}
                  <th>Nota final</th>
                </tr>
              </thead>
              <tbody>
                {inscritos.map(({ detalle, persona }) => (
                  <tr key={detalle.id_detalle}>
                    <td>{persona.nombres} {persona.apellidos}</td>
                    {criterios.map((c) => {
                      const nota = data.notas.find((n) => n.id_detalle === detalle.id_detalle && n.id_criterio === c.id_criterio);
                      return (
                        <td key={c.id_criterio}>
                          <input
                            type="number"
                            className="grade-input"
                            min="0"
                            max="100"
                            defaultValue={nota ? nota.puntaje_obtenido : ""}
                            onBlur={(e) => data.guardarNota(detalle.id_detalle, c.id_criterio, Number(e.target.value) || 0)}
                          />
                        </td>
                      );
                    })}
                    <td><strong>{data.calcularNotaFinal(seleccion.id_materia, seleccion.id_paralelo, detalle.id_detalle)}</strong></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function VistaEstudianteNotas({ session, data }) {
  const historial = data.getHistorialEstudiante(session.estudiante.id_persona);
  return (
    <div>
      <SectionHeader title="Mis Notas" subtitle="Detalle de calificaciones por criterio de evaluación" />
      {historial.map((h) => {
        const criterios = data.criterios.filter((c) => c.id_materia === h.id_materia && c.id_paralelo === h.id_paralelo);
        return (
          <div className="page-card" key={h.id_detalle} style={{ marginBottom: 16 }}>
            <div className="student-row-header">
              <strong>{h.materia.sigla} — {h.materia.nombre}</strong>
              <span className="activity-meta">{h.gestion.periodo}</span>
              <Badge>{h.estado}</Badge>
            </div>
            {criterios.length === 0 ? (
              <EmptyState text="El docente aún no registró criterios de evaluación." />
            ) : (
              <table className="table">
                <thead><tr>{criterios.map((c) => <th key={c.id_criterio}>{c.nombre} ({c.ponderacion})</th>)}<th>Nota final</th></tr></thead>
                <tbody>
                  <tr>
                    {criterios.map((c) => {
                      const nota = data.notas.find((n) => n.id_detalle === h.id_detalle && n.id_criterio === c.id_criterio);
                      return <td key={c.id_criterio}>{nota ? nota.puntaje_obtenido : "—"}</td>;
                    })}
                    <td><strong>{h.estado === "Inscrito" ? data.calcularNotaFinal(h.id_materia, h.id_paralelo, h.id_detalle) : h.nota_final}</strong></td>
                  </tr>
                </tbody>
              </table>
            )}
          </div>
        );
      })}
    </div>
  );
}

function VistaSupervisor({ data }) {
  const [idMateria, setIdMateria] = useState(data.materias[0]?.id_materia);
  const paralelosMateria = data.paralelos.filter((p) => p.id_materia === idMateria);
  return (
    <div>
      <SectionHeader
        title="Notas — Vista de supervisión"
        subtitle="Consulte las calificaciones registradas por los docentes"
        actions={
          <select value={idMateria} onChange={(e) => setIdMateria(Number(e.target.value))}>
            {data.materias.map((m) => <option key={m.id_materia} value={m.id_materia}>{m.sigla} — {m.nombre}</option>)}
          </select>
        }
      />
      {paralelosMateria.map((p) => {
        const criterios = data.criterios.filter((c) => c.id_materia === idMateria && c.id_paralelo === p.id_paralelo);
        const inscritos = data.detalle.filter((d) => d.id_materia === idMateria && d.id_paralelo === p.id_paralelo);
        return (
          <div className="page-card" key={p.id_paralelo} style={{ marginBottom: 16 }}>
            <SectionHeader title={`Paralelo ${p.nombre} — Docente: ${data.getDocenteNombre(p.id_docente)}`} />
            {inscritos.length === 0 ? <EmptyState text="Sin estudiantes inscritos." /> : (
              <table className="table">
                <thead><tr><th>Estudiante</th>{criterios.map((c) => <th key={c.id_criterio}>{c.nombre}</th>)}<th>Nota final</th><th>Estado</th></tr></thead>
                <tbody>
                  {inscritos.map((d) => {
                    const insc = data.inscripciones.find((i) => i.id_inscripcion === d.id_inscripcion);
                    const persona = data.getPersona(insc.id_estudiante);
                    return (
                      <tr key={d.id_detalle}>
                        <td>{persona.nombres} {persona.apellidos}</td>
                        {criterios.map((c) => {
                          const nota = data.notas.find((n) => n.id_detalle === d.id_detalle && n.id_criterio === c.id_criterio);
                          return <td key={c.id_criterio}>{nota ? nota.puntaje_obtenido : "—"}</td>;
                        })}
                        <td>{d.estado === "Inscrito" ? data.calcularNotaFinal(idMateria, p.id_paralelo, d.id_detalle) : d.nota_final}</td>
                        <td><Badge>{d.estado}</Badge></td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        );
      })}
    </div>
  );
}
