import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { useToast } from "../../context/ToastContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { SkeletonCard } from "../../components/Common/SkeletonLoader";

export default function EnrollmentPage() {
  const { session } = useAuth();
  const data = useData();
  const esAdminOrDirector = session?.rolActivo === "ADMIN" || session?.rolActivo === "DIRECTOR";
  const gestionActiva = data.getGestionActiva();

  if (data.loadingBackend) {
    return (
      <div style={{ padding: 20 }}>
        <SectionHeader title="Cargando Ventanilla de Inscripción..." />
        <SkeletonCard count={3} height={140} />
      </div>
    );
  }

  // ---------- Vista Administrativo / Director ----------
  if (esAdminOrDirector) {
    return <VistaAdministrador data={data} gestionActiva={gestionActiva} />;
  }

  // ---------- Vista Estudiante ----------
  return <VistaEstudiante session={session} data={data} gestionActiva={gestionActiva} />;
}

function VistaEstudiante({ session, data, gestionActiva }) {
  const { showSuccess, showError, showWarning } = useToast();
  const estudiante = session?.estudiante || { id_persona: session?.id_persona, ru: `RU-${session?.id_persona}`, id_plan: 1 };
  const plan = data.planes.find((p) => p.id_plan === estudiante.id_plan) || data.planes[0];
  const pensum = data.getPensumPlan(plan?.id_plan || 1);
  const [idMateria, setIdMateria] = useState(null);

  const misInscripcionesActivas = data
    .getHistorialEstudiante(estudiante.id_persona)
    .filter((h) => h.gestion?.id_gestion === gestionActiva?.id_gestion && h.estado === "Inscrito");

  const materiasDisponibles = pensum.filter((m) => {
    const estado = data.getEstadoMateriaParaEstudiante(estudiante.id_persona, m.id_materia);
    return estado === "pendiente" || estado === "reprobada";
  });

  const paralelos = idMateria ? data.getParalelosOferta(idMateria, gestionActiva?.id_gestion) : [];

  // Función de validación de Choque de Horarios en Tiempo Real
  const verificarChoqueHorario = (id_paralelo_target) => {
    const candParalelo = data.paralelos.find((p) => p.id_materia === idMateria && p.id_paralelo === id_paralelo_target);
    if (!candParalelo) return { choque: false };

    const candSeCursa = data.horarios.length > 0 ? (candParalelo.horario || {}) : null;
    const candHorario = candSeCursa ? data.horarios.find((h) => h.id_horario === candSeCursa.id_horario) : null;

    if (!candHorario) return { choque: false };

    for (const insc of misInscripcionesActivas) {
      const insParalelo = data.paralelos.find((p) => p.id_materia === insc.id_materia && p.id_paralelo === insc.id_paralelo);
      if (!insParalelo) continue;
      const insHorario = insParalelo.horario ? data.horarios.find((h) => h.id_horario === insParalelo.horario.id_horario) : null;
      if (!insHorario) continue;

      if (candHorario.dia === insHorario.dia) {
        if (candHorario.hora_inicio < insHorario.hora_fin && candHorario.hora_fin > insHorario.hora_inicio) {
          const materiaChoque = data.getMateria(insc.id_materia);
          return {
            choque: true,
            mensaje: `Choque de horario el día ${candHorario.dia} (${candHorario.hora_inicio}-${candHorario.hora_fin}) con la materia inscrita: ${materiaChoque?.sigla || 'Materia'}`
          };
        }
      }
    }

    return { choque: false };
  };

  const inscribir = async (id_paralelo) => {
    const checkPrereq = data.puedeInscribirse(estudiante.id_persona, plan?.id_plan || 1, idMateria);
    if (!checkPrereq.ok) {
      showError(`No puede inscribirse: ${checkPrereq.motivo}`);
      return;
    }

    const checkChoque = verificarChoqueHorario(id_paralelo);
    if (checkChoque.choque) {
      showWarning(checkChoque.mensaje);
      return;
    }

    try {
      await data.inscribirMateria(estudiante.id_persona, gestionActiva?.id_gestion || 1, idMateria, id_paralelo);
      showSuccess("¡Inscripción realizada con éxito!");
      setIdMateria(null);
    } catch (e) {
      showError(`Error al realizar la inscripción: ${e.message}`);
    }
  };

  return (
    <div>
      <SectionHeader title="Ventanilla de Auto-Inscripción" subtitle={`Gestión Activa: ${gestionActiva?.periodo || "I/2026"}`} />

      <div className="page-card" style={{ marginBottom: 20 }}>
        <SectionHeader title="Mis materias inscritas en esta gestión" />
        {misInscripcionesActivas.length === 0 ? (
          <EmptyState text="Aún no se ha inscrito a ninguna materia en esta gestión." />
        ) : (
          <table className="table">
            <thead><tr><th>Materia</th><th>Paralelo</th><th>Estado</th><th>Acción</th></tr></thead>
            <tbody>
              {misInscripcionesActivas.map((h) => (
                <tr key={h.id_detalle}>
                  <td><strong>{h.materia?.sigla}</strong> — {h.materia?.nombre}</td>
                  <td>Paralelo {h.id_paralelo}</td>
                  <td><Badge>{h.estado}</Badge></td>
                  <td>
                    <button
                      className="link-button danger"
                      onClick={async () => {
                        await data.retirarInscripcion(h.id_detalle);
                        showInfo("Inscripción retirada correctamente.");
                      }}
                    >
                      Retirar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="page-card">
        <SectionHeader
          title="Materias disponibles para inscripción"
          subtitle="Seleccione una asignatura para ver los paralelos ofertados y verificar horarios"
        />
        <div className="materia-grid">
          {materiasDisponibles.map((m) => {
            const check = data.puedeInscribirse(estudiante.id_persona, plan?.id_plan || 1, m.id_materia);
            return (
              <button
                key={m.id_materia}
                className={`materia-card ${check.ok ? "materia-blue" : "materia-locked"}`}
                onClick={() => {
                  if (check.ok) {
                    setIdMateria(m.id_materia);
                  } else {
                    showWarning(check.motivo);
                  }
                }}
                type="button"
              >
                <strong>{m.materia?.sigla}</strong>
                <span>{m.materia?.nombre}</span>
                <small>{check.ok ? "Disponible para inscripcion" : "🔒 Prerrequisitos faltantes"}</small>
              </button>
            );
          })}
        </div>
      </div>

      {idMateria && (
        <div className="modal-backdrop" onClick={() => setIdMateria(null)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Elegir Paralelo — {data.getMateria(idMateria)?.sigla}</h3>
              <button className="link-button" onClick={() => setIdMateria(null)}>Cerrar ✕</button>
            </div>
            {paralelos.length === 0 ? (
              <EmptyState text="No hay paralelos ofertados para esta materia en la gestión activa." />
            ) : (
              <table className="table">
                <thead><tr><th>Paralelo</th><th>Docente</th><th>Horario</th><th>Cupo</th><th>Acción</th></tr></thead>
                <tbody>
                  {paralelos.map((p) => {
                    const validacion = verificarChoqueHorario(p.id_paralelo);
                    const sinCupo = p.cupo_disponible <= 0;
                    return (
                      <tr key={p.id_paralelo}>
                        <td><strong>Paralelo {p.nombre}</strong></td>
                        <td>{p.docenteNombre}</td>
                        <td>
                          {p.horario
                            ? `${data.horarios.find((h) => h.id_horario === p.horario.id_horario)?.dia || ''} ${data.horarios.find((h) => h.id_horario === p.horario.id_horario)?.hora_inicio || ''}`
                            : "Por definir"}
                        </td>
                        <td>
                          <span style={{ color: sinCupo ? "#e64545" : "#1f9d55", fontWeight: 600 }}>
                            {p.cupo_disponible} / {p.cupo_maximo}
                          </span>
                        </td>
                        <td>
                          {validacion.choque ? (
                            <span style={{ color: "#e64545", fontSize: "0.8rem", fontWeight: 600 }}>⚠️ Choque de horario</span>
                          ) : (
                            <button
                              className="primary-button small"
                              disabled={sinCupo}
                              onClick={() => inscribir(p.id_paralelo)}
                            >
                              {sinCupo ? "Sin cupo" : "Inscribirme"}
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function VistaAdministrador({ data, gestionActiva }) {
  const { showSuccess, showInfo } = useToast();
  const [idGestion, setIdGestion] = useState(gestionActiva?.id_gestion || 1);
  const [filtroEstudiante, setFiltroEstudiante] = useState("");

  const filas = useMemo(() => {
    return data.estudiantes
      .map((e) => {
        const persona = data.getPersona(e.id_persona);
        const historial = data.getHistorialEstudiante(e.id_persona).filter((h) => h.gestion?.id_gestion === idGestion);
        return { estudiante: e, persona, historial };
      })
      .filter((f) => {
        const q = filtroEstudiante.toLowerCase();
        return !q || `${f.persona.nombres} ${f.persona.apellidos} ${f.estudiante.ru}`.toLowerCase().includes(q);
      });
  }, [data, idGestion, filtroEstudiante]);

  return (
    <div>
      <SectionHeader
        title="Ventanilla de Inscripción — Administración"
        subtitle="Supervisión de inscripciones y gestión de excepciones para cualquier estudiante"
        actions={
          <>
            <input className="search-input" placeholder="Buscar estudiante o RU..." value={filtroEstudiante} onChange={(e) => setFiltroEstudiante(e.target.value)} />
            <select value={idGestion} onChange={(e) => setIdGestion(Number(e.target.value))}>
              {data.gestiones.map((g) => (
                <option key={g.id_gestion} value={g.id_gestion}>{g.periodo}</option>
              ))}
            </select>
          </>
        }
      />

      {filas.map((f) => (
        <div className="page-card" key={f.estudiante.id_persona} style={{ marginBottom: 16 }}>
          <div className="student-row-header">
            <strong>{f.persona.nombres} {f.persona.apellidos}</strong>
            <span className="activity-meta">RU: {f.estudiante.ru}</span>
          </div>
          {f.historial.length === 0 ? (
            <EmptyState text="Sin inscripciones registradas en esta gestión." />
          ) : (
            <table className="table">
              <thead><tr><th>Materia</th><th>Estado</th><th>Nota Final</th><th>Acciones</th></tr></thead>
              <tbody>
                {f.historial.map((h) => (
                  <tr key={h.id_detalle}>
                    <td>{h.materia?.sigla} — {h.materia?.nombre}</td>
                    <td><Badge>{h.estado}</Badge></td>
                    <td><strong>{h.nota_final}</strong></td>
                    <td>
                      <select
                        value={h.estado}
                        onChange={(e) => {
                          data.actualizarEstadoDetalle(h.id_detalle, { estado: e.target.value });
                          showSuccess(`Estado actualizado a: ${e.target.value}`);
                        }}
                      >
                        <option value="Inscrito">Inscrito</option>
                        <option value="Aprobado">Aprobado</option>
                        <option value="Reprobado">Reprobado</option>
                        <option value="Abandono">Abandono</option>
                      </select>
                      <button
                        className="link-button danger"
                        onClick={async () => {
                          await data.retirarInscripcion(h.id_detalle);
                          showInfo("Inscripción eliminada por administración.");
                        }}
                      >
                        Eliminar
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      ))}
    </div>
  );
}
