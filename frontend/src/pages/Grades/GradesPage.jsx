import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { useToast } from "../../context/ToastContext";
import { SectionHeader, EmptyState, Badge } from "../../components/Common/Common";
import { SkeletonCard } from "../../components/Common/SkeletonLoader";

export default function GradesPage() {
  const { session } = useAuth();
  const data = useData();

  if (data.loadingBackend) {
    return (
      <div style={{ padding: 20 }}>
        <SectionHeader title="Cargando Planilla de Calificaciones..." />
        <SkeletonCard count={2} height={180} />
      </div>
    );
  }

  if (session?.rolActivo === "DOCENTE") return <VistaDocente session={session} data={data} />;
  if (session?.rolActivo === "ESTUDIANTE") return <VistaEstudianteNotas session={session} data={data} />;
  return <VistaSupervisor data={data} />;
}

function VistaDocente({ session, data }) {
  const { showSuccess, showError, showWarning, showInfo } = useToast();
  const gestionActiva = data.getGestionActiva();
  const misParalelos = data.paralelos.filter(
    (p) => p.id_docente === session.id_persona && p.id_gestion === gestionActiva?.id_gestion
  );
  const [seleccion, setSeleccion] = useState(misParalelos[0] || null);
  const [nuevoCriterio, setNuevoCriterio] = useState({ nombre: "", ponderacion: "" });

  if (!seleccion) {
    return (
      <div>
        <SectionHeader title="Notas y Ponderaciones" subtitle="No tiene paralelos asignados en la gestión activa" />
        <EmptyState text="Cuando se le asigne un paralelo en esta gestión, podrá definir las ponderaciones y registrar calificaciones." />
      </div>
    );
  }

  const materia = data.getMateria(seleccion.id_materia);
  const criterios = data.criterios.filter((c) => c.id_materia === seleccion.id_materia && c.id_paralelo === seleccion.id_paralelo);
  const sumaPonderacion = criterios.reduce((acc, c) => acc + Number(c.ponderacion), 0);

  const inscritos = data.detalle
    .filter((d) => d.id_materia === seleccion.id_materia && d.id_paralelo === seleccion.id_paralelo)
    .map((d) => {
      const insc = data.inscripciones.find((i) => i.id_inscripcion === d.id_inscripcion);
      const persona = data.getPersona(insc?.id_estudiante);
      return { detalle: d, persona };
    });

  const agregarCriterio = async (e) => {
    e.preventDefault();
    const pond = Number(nuevoCriterio.ponderacion);
    if (!nuevoCriterio.nombre || !pond || pond <= 0) {
      showWarning("Ingrese un nombre de criterio y una ponderación válida mayor a 0.");
      return;
    }
    if (sumaPonderacion + pond > 100) {
      showError(`La suma total de ponderaciones no puede superar el 100% (actual: ${sumaPonderacion}%).`);
      return;
    }

    try {
      await data.crearCriterio(seleccion.id_materia, seleccion.id_paralelo, nuevoCriterio.nombre, pond);
      showSuccess(`Criterio '${nuevoCriterio.nombre}' agregado (${pond} pts).`);
      setNuevoCriterio({ nombre: "", ponderacion: "" });
    } catch (err) {
      showError(`Error al crear el criterio: ${err.message}`);
    }
  };

  const handleNotaBlur = async (id_detalle, id_criterio, valor) => {
    try {
      await data.guardarNota(id_detalle, id_criterio, Number(valor) || 0);
      showInfo("Borrador de calificación guardado automáticamente.");
    } catch (err) {
      showError("Error al guardar la nota.");
    }
  };

  return (
    <div>
      <SectionHeader
        title="Planilla de Notas y Criterios"
        subtitle={`Paralelo ${seleccion.nombre} — ${materia?.sigla}`}
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
              return <option key={`${p.id_materia}-${p.id_paralelo}`} value={`${p.id_materia}-${p.id_paralelo}`}>{m?.sigla} - Paralelo {p.nombre}</option>;
            })}
          </select>
        }
      />

      <div className="page-card" style={{ marginBottom: 20 }}>
        <SectionHeader
          title={`Criterios de Evaluación (${materia?.sigla})`}
          subtitle={`Ponderación Acumulada: ${sumaPonderacion} / 100% ${sumaPonderacion === 100 ? "✅ (Completa)" : "⚠️ (Incompleta)"}`}
        />
        <table className="table" style={{ marginBottom: 16 }}>
          <thead><tr><th>Criterio</th><th>Ponderación</th><th>Acción</th></tr></thead>
          <tbody>
            {criterios.map((c) => (
              <tr key={c.id_criterio}>
                <td>{c.nombre}</td>
                <td><strong>{c.ponderacion}%</strong></td>
                <td>
                  <button
                    className="link-button danger"
                    onClick={async () => {
                      await data.eliminarCriterio(c.id_criterio);
                      showInfo("Criterio de evaluación eliminado.");
                    }}
                  >
                    Eliminar
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <form className="inline-form" onSubmit={agregarCriterio}>
          <input placeholder="Nombre del criterio (ej. Examen Parcial)" value={nuevoCriterio.nombre} onChange={(e) => setNuevoCriterio({ ...nuevoCriterio, nombre: e.target.value })} />
          <input type="number" placeholder="Ponderación (%)" value={nuevoCriterio.ponderacion} onChange={(e) => setNuevoCriterio({ ...nuevoCriterio, ponderacion: e.target.value })} min="1" max="100" />
          <button className="primary-button small" type="submit">+ Agregar criterio</button>
        </form>
      </div>

      <div className="page-card">
        <SectionHeader title="Registro y llenado de planilla" subtitle="Las notas ingresadas se guardan automáticamente al cambiar de casilla" />
        {inscritos.length === 0 || criterios.length === 0 ? (
          <EmptyState text={criterios.length === 0 ? "Defina al menos un criterio para habilitar el registro de calificaciones." : "No hay estudiantes inscritos en este paralelo."} />
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th>Estudiante</th>
                  {criterios.map((c) => <th key={c.id_criterio}>{c.nombre} ({c.ponderacion}%)</th>)}
                  <th>Nota Final Calculada</th>
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
                            defaultValue={nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : ""}
                            onBlur={(e) => handleNotaBlur(detalle.id_detalle, c.id_criterio, e.target.value)}
                          />
                        </td>
                      );
                    })}
                    <td><strong>{data.calcularNotaFinal(seleccion.id_materia, seleccion.id_paralelo, detalle.id_detalle)} pts</strong></td>
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
  const historial = data.getHistorialEstudiante(session?.id_persona);
  return (
    <div>
      <SectionHeader title="Mis Calificaciones" subtitle="Detalle acumulado por materia y criterio de evaluación" />
      {historial.length === 0 ? (
        <EmptyState text="Aún no tienes asignaturas inscritas con calificaciones registradas." />
      ) : (
        historial.map((h) => {
          const criterios = data.criterios.filter((c) => c.id_materia === h.id_materia && c.id_paralelo === h.id_paralelo);
          return (
            <div className="page-card" key={h.id_detalle} style={{ marginBottom: 16 }}>
              <div className="student-row-header">
                <strong>{h.materia?.sigla} — {h.materia?.nombre}</strong>
                <span className="activity-meta">{h.gestion?.periodo || 'I/2026'}</span>
                <Badge>{h.estado}</Badge>
              </div>
              {criterios.length === 0 ? (
                <EmptyState text="El docente aún no ha registrado la ponderación de criterios." />
              ) : (
                <table className="table">
                  <thead><tr>{criterios.map((c) => <th key={c.id_criterio}>{c.nombre} ({c.ponderacion}%)</th>)}<th>Nota Final</th></tr></thead>
                  <tbody>
                    <tr>
                      {criterios.map((c) => {
                        const nota = data.notas.find((n) => n.id_detalle === h.id_detalle && n.id_criterio === c.id_criterio);
                        return <td key={c.id_criterio}>{nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : "—"}</td>;
                      })}
                      <td><strong>{h.estado === "Inscrito" ? data.calcularNotaFinal(h.id_materia, h.id_paralelo, h.id_detalle) : h.nota_final} pts</strong></td>
                    </tr>
                  </tbody>
                </table>
              )}
            </div>
          );
        })
      )}
    </div>
  );
}

function VistaSupervisor({ data }) {
  const [idMateria, setIdMateria] = useState(data.materias[0]?.id_materia || 1);
  const paralelosMateria = data.paralelos.filter((p) => p.id_materia === idMateria);
  return (
    <div>
      <SectionHeader
        title="Notas — Vista de Supervisión y Auditoría"
        subtitle="Monitoreo en tiempo real de planillas de docentes"
        actions={
          <select value={idMateria} onChange={(e) => setIdMateria(Number(e.target.value))}>
            {data.materias.map((m) => <option key={m.id_materia} value={m.id_materia}>{m.sigla} — {m.nombre}</option>)}
          </select>
        }
      />
      {paralelosMateria.length === 0 ? (
        <EmptyState text="Sin paralelos programados para esta materia." />
      ) : (
        paralelosMateria.map((p) => {
          const criterios = data.criterios.filter((c) => c.id_materia === idMateria && c.id_paralelo === p.id_paralelo);
          const inscritos = data.detalle.filter((d) => d.id_materia === idMateria && d.id_paralelo === p.id_paralelo);
          return (
            <div className="page-card" key={p.id_paralelo} style={{ marginBottom: 16 }}>
              <SectionHeader title={`Paralelo ${p.nombre} — Docente: ${data.getDocenteNombre(p.id_docente)}`} />
              {inscritos.length === 0 ? <EmptyState text="Sin estudiantes inscritos." /> : (
                <table className="table">
                  <thead><tr><th>Estudiante</th>{criterios.map((c) => <th key={c.id_criterio}>{c.nombre}</th>)}<th>Nota Final</th><th>Estado</th></tr></thead>
                  <tbody>
                    {inscritos.map((d) => {
                      const insc = data.inscripciones.find((i) => i.id_inscripcion === d.id_inscripcion);
                      const persona = data.getPersona(insc?.id_estudiante);
                      return (
                        <tr key={d.id_detalle}>
                          <td>{persona.nombres} {persona.apellidos}</td>
                          {criterios.map((c) => {
                            const nota = data.notas.find((n) => n.id_detalle === d.id_detalle && n.id_criterio === c.id_criterio);
                            return <td key={c.id_criterio}>{nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : "—"}</td>;
                          })}
                          <td><strong>{d.estado === "Inscrito" ? data.calcularNotaFinal(idMateria, p.id_paralelo, d.id_detalle) : d.nota_final}</strong></td>
                          <td><Badge>{d.estado}</Badge></td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </div>
          );
        })
      )}
    </div>
  );
}
