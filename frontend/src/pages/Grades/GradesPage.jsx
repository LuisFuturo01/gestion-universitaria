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
  
  const [seleccionId, setSeleccionId] = useState(null);
  const [nuevoCriterio, setNuevoCriterio] = useState({ nombre: "", ponderacion: "" });
  const [editandoCriterio, setEditandoCriterio] = useState(null);

  // misParalelos recalculado dinámicamente
  const misParalelos = useMemo(() => {
    if (!session?.id_persona) return [];
    return (data.paralelos || []).filter(
      (p) => Number(p.id_docente) === Number(session.id_persona) && (!gestionActiva || Number(p.id_gestion) === Number(gestionActiva.id_gestion))
    );
  }, [data.paralelos, session?.id_persona, gestionActiva]);

  // Selección activa computada
  const seleccion = useMemo(() => {
    if (misParalelos.length === 0) return null;
    if (seleccionId) {
      const match = misParalelos.find((p) => `${p.id_materia}-${p.id_paralelo}` === seleccionId);
      if (match) return match;
    }
    return misParalelos[0];
  }, [misParalelos, seleccionId]);

  if (!seleccion) {
    return (
      <div>
        <SectionHeader title="Notas y Ponderaciones" subtitle={`Gestión Académica Activa: ${gestionActiva?.periodo || 'I/2026'}`} />
        <EmptyState text="No tiene asignaturas asignadas en la gestión activa. Solicite impartir una materia desde 'Oferta Académica'." />
      </div>
    );
  }

  const materia = data.getMateria(seleccion.id_materia);
  const criterios = (data.criterios || []).filter(
    (c) => Number(c.id_materia) === Number(seleccion.id_materia) && Number(c.id_paralelo) === Number(seleccion.id_paralelo)
  );
  const sumaPonderacion = criterios.reduce((acc, c) => acc + Number(c.ponderacion), 0);

  const [editandoCelda, setEditandoCelda] = useState(null);
  const [valorEdit, setValorEdit] = useState("");

  // Estudiantes inscritos deduplicados por id_estudiante para la gestión activa
  const inscritos = useMemo(() => {
    if (!seleccion) return [];
    const mapaEstudiantes = new Map();
    (data.detalle || []).forEach((d) => {
      if (Number(d.id_materia) === Number(seleccion.id_materia) && Number(d.id_paralelo) === Number(seleccion.id_paralelo)) {
        const insc = (data.inscripciones || []).find((i) => Number(i.id_inscripcion) === Number(d.id_inscripcion));
        if (!gestionActiva || (insc && Number(insc.id_gestion) === Number(gestionActiva.id_gestion))) {
          const idEst = insc?.id_estudiante;
          if (idEst && !mapaEstudiantes.has(idEst)) {
            const persona = data.getPersona(idEst);
            mapaEstudiantes.set(idEst, { detalle: d, persona });
          }
        }
      }
    });
    return Array.from(mapaEstudiantes.values());
  }, [data.detalle, data.inscripciones, data.personas, seleccion, gestionActiva]);

  const agregarCriterio = async (e) => {
    e.preventDefault();
    const nombre = (nuevoCriterio.nombre || "").trim();
    const pond = Number(nuevoCriterio.ponderacion);
    if (!nombre || isNaN(pond) || pond <= 0) {
      showWarning("Ingrese un nombre de criterio y una ponderación válida mayor a 0.");
      return;
    }
    if (sumaPonderacion + pond > 100) {
      showError(`La suma total de ponderaciones no puede superar el 100% (actual acumulado: ${sumaPonderacion}%).`);
      return;
    }

    try {
      await data.crearCriterio(seleccion.id_materia, seleccion.id_paralelo, nombre, pond);
      showSuccess(`Criterio '${nombre}' agregado (${pond}%).`);
      setNuevoCriterio({ nombre: "", ponderacion: "" });
    } catch (err) {
      showError(`Error al crear el criterio: ${err.message}`);
    }
  };

  const guardarNotaEdicion = async (id_detalle, id_criterio, valor, maxPonderacion, nombreCriterio) => {
    if (valor === "" || valor === null || valor === undefined) {
      setEditandoCelda(null);
      return;
    }
    let num = Number(valor);
    if (isNaN(num)) {
      setEditandoCelda(null);
      return;
    }

    if (num < 0) {
      num = 0;
      showWarning("La calificación no puede ser menor a 0. Se ajustó a 0.");
    } else if (num > maxPonderacion) {
      num = maxPonderacion;
      showWarning(`La nota se ajustó automáticamente al máximo de ${maxPonderacion} pts para '${nombreCriterio}'.`);
    }

    try {
      await data.guardarNota(id_detalle, id_criterio, num);
      showSuccess(`Nota guardada: ${num} pts.`);
      setEditandoCelda(null);
    } catch (err) {
      showError(`Error al guardar la nota: ${err.message}`);
    }
  };

  return (
    <div>
      <SectionHeader
        title="Planilla de Notas y Criterios"
        subtitle={`Paralelo ${seleccion.nombre} — ${materia?.sigla || 'Materia'} (${materia?.nombre || ''})`}
        actions={
          <select
            value={`${seleccion.id_materia}-${seleccion.id_paralelo}`}
            onChange={(e) => setSeleccionId(e.target.value)}
          >
            {misParalelos.map((p) => {
              const m = data.getMateria(p.id_materia);
              return <option key={`${p.id_materia}-${p.id_paralelo}`} value={`${p.id_materia}-${p.id_paralelo}`}>{m?.sigla || `MAT-${p.id_materia}`} - Paralelo {p.nombre}</option>;
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
          <thead>
            <tr>
              <th>Criterio</th>
              <th>Ponderación (%)</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {criterios.length === 0 ? (
              <tr>
                <td colSpan="3" style={{ textAlign: "center", color: "#7c8ba3", padding: 12 }}>
                  Sin criterios definidos aún. Agregue el primer criterio en el formulario inferior (ej. Primer Parcial 30%).
                </td>
              </tr>
            ) : (
              criterios.map((c) => (
                <tr key={c.id_criterio}>
                  {editandoCriterio?.id_criterio === c.id_criterio ? (
                    <>
                      <td>
                        <input
                          style={{ width: "100%", padding: "4px 8px" }}
                          value={editandoCriterio.nombre}
                          onChange={(e) => setEditandoCriterio({ ...editandoCriterio, nombre: e.target.value })}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          style={{ width: 90, padding: "4px 8px" }}
                          value={editandoCriterio.ponderacion}
                          onChange={(e) => setEditandoCriterio({ ...editandoCriterio, ponderacion: e.target.value })}
                          min="1"
                          max="100"
                        /> %
                      </td>
                      <td style={{ display: "flex", gap: 8 }}>
                        <button
                          className="button primary sm"
                          onClick={async () => {
                            const nombreEd = (editandoCriterio.nombre || "").trim();
                            const pondEd = Number(editandoCriterio.ponderacion);
                            if (!nombreEd || isNaN(pondEd) || pondEd <= 0) {
                              showWarning("Ingrese un nombre de criterio y ponderación mayor a 0.");
                              return;
                            }
                            const sumaOtros = criterios
                              .filter((x) => Number(x.id_criterio) !== Number(c.id_criterio))
                              .reduce((acc, x) => acc + Number(x.ponderacion), 0);
                            if (sumaOtros + pondEd > 100) {
                              showError(`La suma de ponderaciones no puede superar 100% (actual: ${sumaOtros + pondEd}%).`);
                              return;
                            }
                            try {
                              await data.actualizarCriterio(c.id_criterio, nombreEd, pondEd);
                              showSuccess("Criterio actualizado correctamente.");
                              setEditandoCriterio(null);
                            } catch (err) {
                              showError(`Error al actualizar: ${err.message}`);
                            }
                          }}
                        >
                          💾 Guardar
                        </button>
                        <button
                          className="button secondary sm"
                          onClick={() => setEditandoCriterio(null)}
                        >
                          Cancelar
                        </button>
                      </td>
                    </>
                  ) : (
                    <>
                      <td><strong>{c.nombre}</strong></td>
                      <td><strong>{c.ponderacion}%</strong></td>
                      <td style={{ display: "flex", gap: 8 }}>
                        <button
                          className="button secondary sm"
                          onClick={() => setEditandoCriterio({ id_criterio: c.id_criterio, nombre: c.nombre, ponderacion: c.ponderacion })}
                        >
                          ✏️ Editar
                        </button>
                        <button
                          className="button danger sm"
                          onClick={async () => {
                            try {
                              await data.eliminarCriterio(c.id_criterio);
                              showSuccess("Criterio de evaluación eliminado correctamente.");
                            } catch (err) {
                              showError(`Error al eliminar criterio: ${err.message}`);
                            }
                          }}
                        >
                          🗑️ Eliminar
                        </button>
                      </td>
                    </>
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
        <form className="inline-form" onSubmit={agregarCriterio}>
          <input
            placeholder="Nombre del criterio (ej. Examen Parcial)"
            value={nuevoCriterio.nombre}
            onChange={(e) => setNuevoCriterio({ ...nuevoCriterio, nombre: e.target.value })}
          />
          <input
            type="number"
            placeholder="Ponderación (%)"
            value={nuevoCriterio.ponderacion}
            onChange={(e) => setNuevoCriterio({ ...nuevoCriterio, ponderacion: e.target.value })}
            min="1"
            max="100"
          />
          <button className="primary-button small" type="submit">+ Agregar criterio</button>
        </form>
      </div>

      <div className="page-card" style={{ width: "100%", overflowX: "auto" }}>
        <SectionHeader title="Registro y llenado de planilla" subtitle="Haga clic en el ícono de lápiz ✏️ para calificar a un estudiante" />
        {inscritos.length === 0 || criterios.length === 0 ? (
          <EmptyState text={criterios.length === 0 ? "Defina al menos un criterio para habilitar el registro de calificaciones." : "No hay estudiantes inscritos en este paralelo."} />
        ) : (
          <div className="table-scroll" style={{ width: "100%", overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", minWidth: 650, borderCollapse: "collapse" }}>
              <thead>
                <tr style={{ background: "#f8fafc" }}>
                  <th style={{ minWidth: 200, padding: "12px 16px", textAlign: "left" }}>Estudiante</th>
                  {criterios.map((c) => (
                    <th key={c.id_criterio} style={{ minWidth: 150, padding: "12px 16px", textAlign: "center" }}>
                      <div>{c.nombre}</div>
                      <span style={{ fontSize: "0.78rem", color: "#2563eb", fontWeight: 600 }}>Máx: {c.ponderacion} pts</span>
                    </th>
                  ))}
                  <th style={{ minWidth: 160, padding: "12px 16px", textAlign: "center" }}>Nota Final Calculada</th>
                </tr>
              </thead>
              <tbody>
                {inscritos.map(({ detalle, persona }) => {
                  const notaFinalVal = data.calcularNotaFinal(seleccion.id_materia, seleccion.id_paralelo, detalle.id_detalle);
                  return (
                    <tr key={detalle.id_detalle}>
                      <td style={{ padding: "12px 16px", fontWeight: 600, color: "#1e293b" }}>
                        {persona.nombres} {persona.apellidos}
                      </td>
                      {criterios.map((c) => {
                        const celdaId = `${detalle.id_detalle}-${c.id_criterio}`;
                        const esEditando = editandoCelda === celdaId;
                        const nota = data.notas.find((n) => Number(n.id_detalle) === Number(detalle.id_detalle) && Number(n.id_criterio) === Number(c.id_criterio));
                        const valorNota = nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : "";

                        return (
                          <td key={c.id_criterio} style={{ padding: "8px 12px", textAlign: "center" }}>
                            {esEditando ? (
                              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}>
                                <input
                                  type="number"
                                  style={{
                                    width: 75,
                                    padding: "6px 8px",
                                    textAlign: "center",
                                    fontWeight: 700,
                                    fontSize: "0.9rem",
                                    borderRadius: 6,
                                    border: "2px solid #2563eb",
                                    outline: "none",
                                    background: "#ffffff"
                                  }}
                                  autoFocus
                                  min="0"
                                  max={c.ponderacion}
                                  step="0.5"
                                  placeholder={`0-${c.ponderacion}`}
                                  value={valorEdit}
                                  onChange={(e) => setValorEdit(e.target.value)}
                                  onKeyDown={async (e) => {
                                    if (e.key === "Enter") {
                                      await guardarNotaEdicion(detalle.id_detalle, c.id_criterio, valorEdit, Number(c.ponderacion), c.nombre);
                                    } else if (e.key === "Escape") {
                                      setEditandoCelda(null);
                                    }
                                  }}
                                />
                                <button
                                  type="button"
                                  className="button primary sm"
                                  style={{ padding: "4px 8px", fontSize: "0.85rem", cursor: "pointer", background: "#16a34a", borderColor: "#16a34a" }}
                                  title="Aceptar y guardar cambio"
                                  onClick={async () => {
                                    await guardarNotaEdicion(detalle.id_detalle, c.id_criterio, valorEdit, Number(c.ponderacion), c.nombre);
                                  }}
                                >
                                  ✅
                                </button>
                              </div>
                            ) : (
                              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
                                <span style={{ fontWeight: 700, fontSize: "0.95rem", color: valorNota !== "" ? "#0f172a" : "#94a3b8" }}>
                                  {valorNota !== "" ? `${valorNota} pts` : "—"}
                                </span>
                                <button
                                  type="button"
                                  className="button secondary sm"
                                  style={{ padding: "3px 6px", fontSize: "0.8rem", cursor: "pointer" }}
                                  title="Editar nota"
                                  onClick={() => {
                                    setEditandoCelda(celdaId);
                                    setValorEdit(valorNota !== "" ? String(valorNota) : "");
                                  }}
                                >
                                  ✏️
                                </button>
                              </div>
                            )}
                          </td>
                        );
                      })}
                      <td style={{ padding: "12px 16px", textAlign: "center" }}>
                        <span className={`badge ${notaFinalVal >= 51 ? "badge-success" : "badge-danger"}`} style={{ fontSize: "0.95rem", padding: "6px 12px" }}>
                          {notaFinalVal} pts
                        </span>
                      </td>
                    </tr>
                  );
                })}
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
          const criterios = (data.criterios || []).filter(
            (c) => Number(c.id_materia) === Number(h.id_materia) && Number(c.id_paralelo) === Number(h.id_paralelo)
          );
          const notaFinalVal = data.calcularNotaFinal(h.id_materia, h.id_paralelo, h.id_detalle);
          return (
            <div className="page-card" key={h.id_detalle} style={{ marginBottom: 16 }}>
              <div className="student-row-header">
                <strong>{h.materia?.sigla} — {h.materia?.nombre} (Paralelo {h.id_paralelo})</strong>
                <span className="activity-meta">{h.gestion?.periodo || 'I/2026'}</span>
                <Badge>{h.estado}</Badge>
              </div>
              {criterios.length === 0 ? (
                <EmptyState text="El docente aún no ha registrado la ponderación de criterios." />
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      {criterios.map((c) => (
                        <th key={c.id_criterio}>
                          <div>{c.nombre}</div>
                          <span style={{ fontSize: "0.75rem", color: "#2563eb" }}>(Máx: {c.ponderacion} pts)</span>
                        </th>
                      ))}
                      <th>Nota Final Acumulada</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      {criterios.map((c) => {
                        const nota = (data.notas || []).find(
                          (n) => Number(n.id_detalle) === Number(h.id_detalle) && Number(n.id_criterio) === Number(c.id_criterio)
                        );
                        const val = nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : "—";
                        return <td key={c.id_criterio}><strong>{val}</strong></td>;
                      })}
                      <td>
                        <span className={`badge ${notaFinalVal >= 51 ? "badge-success" : "badge-danger"}`} style={{ fontSize: "0.95rem", padding: "6px 12px" }}>
                          {notaFinalVal} pts
                        </span>
                      </td>
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
  const gestionActiva = data.getGestionActiva();
  const [idMateria, setIdMateria] = useState(data.materias[0]?.id_materia || 1);
  const materiaSel = data.getMateria(idMateria);

  const paralelosMateria = useMemo(() => {
    const directos = (data.paralelos || []).filter(
      (p) => Number(p.id_materia) === Number(idMateria) && Number(p.id_gestion) === Number(gestionActiva?.id_gestion)
    );
    if (directos.length > 0) return directos;
    return (data.paralelos || []).filter((p) => Number(p.id_materia) === Number(idMateria));
  }, [data.paralelos, idMateria, gestionActiva]);

  return (
    <div>
      <SectionHeader
        title="Notas — Vista de Supervisión y Auditoría"
        subtitle={`Monitoreo en tiempo real de planillas de docentes — Gestión Activa: ${gestionActiva?.periodo || "I/2026"}`}
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
          const criterios = (data.criterios || []).filter(
            (c) => Number(c.id_materia) === Number(idMateria) && Number(c.id_paralelo) === Number(p.id_paralelo)
          );

          const mapaEstudiantes = new Map();
          (data.detalle || []).forEach((d) => {
            if (Number(d.id_materia) === Number(idMateria) && Number(d.id_paralelo) === Number(p.id_paralelo)) {
              const insc = (data.inscripciones || []).find((i) => Number(i.id_inscripcion) === Number(d.id_inscripcion));
              if (!gestionActiva || (insc && Number(insc.id_gestion) === Number(gestionActiva.id_gestion))) {
                const idEst = insc?.id_estudiante;
                if (idEst && !mapaEstudiantes.has(idEst)) {
                  const persona = data.getPersona(idEst);
                  mapaEstudiantes.set(idEst, { detalle: d, persona });
                }
              }
            }
          });
          const inscritos = Array.from(mapaEstudiantes.values());

          return (
            <div className="page-card" key={`${p.id_materia}-${p.id_paralelo}-${p.id_gestion}`} style={{ marginBottom: 16 }}>
              <SectionHeader
                title={`Paralelo ${p.nombre} — ${materiaSel?.sigla || 'MAT'} (${materiaSel?.nombre || ''}) — Docente: ${data.getDocenteNombre(p.id_docente)}`}
              />
              {inscritos.length === 0 ? (
                <EmptyState text="Sin estudiantes inscritos en este paralelo para la gestión activa." />
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      <th>Estudiante</th>
                      {criterios.map((c) => (
                        <th key={c.id_criterio}>
                          <div>{c.nombre}</div>
                          <span style={{ fontSize: "0.75rem", color: "#2563eb" }}>({c.ponderacion}%)</span>
                        </th>
                      ))}
                      <th>Nota Final</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    {inscritos.map(({ detalle: d, persona }) => {
                      const notaFinalVal = data.calcularNotaFinal(idMateria, p.id_paralelo, d.id_detalle);
                      return (
                        <tr key={d.id_detalle}>
                          <td><strong>{persona ? `${persona.nombres} ${persona.apellidos}` : `Estudiante #${d.id_inscripcion}`}</strong></td>
                          {criterios.map((c) => {
                            const nota = (data.notas || []).find(
                              (n) => Number(n.id_detalle) === Number(d.id_detalle) && Number(n.id_criterio) === Number(c.id_criterio)
                            );
                            const val = nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : "—";
                            return <td key={c.id_criterio}><strong>{val}</strong></td>;
                          })}
                          <td>
                            <strong>{notaFinalVal} pts</strong>
                          </td>
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
