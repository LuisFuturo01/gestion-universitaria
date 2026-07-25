import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";

export default function EnrollmentPage() {
  const { session } = useAuth();
  const data = useData();
  const esAdmin = session.rolActivo === "ADMIN";
  const gestionActiva = data.getGestionActiva();

  // ---------- Vista Estudiante ----------
  if (!esAdmin) {
    return <VistaEstudiante session={session} data={data} gestionActiva={gestionActiva} />;
  }

  // ---------- Vista Administrador ----------
  return <VistaAdministrador data={data} gestionActiva={gestionActiva} />;
}

function VistaEstudiante({ session, data, gestionActiva }) {
  const estudiante = session.estudiante;
  const plan = data.planes.find((p) => p.id_plan === estudiante.id_plan);
  const pensum = data.getPensumPlan(estudiante.id_plan);
  const [idMateria, setIdMateria] = useState(null);

  const misInscripcionesActivas = data
    .getHistorialEstudiante(estudiante.id_persona)
    .filter((h) => h.gestion.id_gestion === gestionActiva?.id_gestion);

  const materiasDisponibles = pensum.filter((m) => {
    const estado = data.getEstadoMateriaParaEstudiante(estudiante.id_persona, m.id_materia);
    return estado === "pendiente" || estado === "reprobada";
  });

  const paralelos = idMateria ? data.getParalelosOferta(idMateria, gestionActiva?.id_gestion) : [];

  const inscribir = (id_paralelo) => {
    const check = data.puedeInscribirse(estudiante.id_persona, plan.id_plan, idMateria);
    if (!check.ok) {
      alert(`No puede inscribirse: ${check.motivo}`);
      return;
    }
    data.inscribirMateria(estudiante.id_persona, gestionActiva.id_gestion, idMateria, id_paralelo);
    setIdMateria(null);
  };

  return (
    <div>
      <SectionHeader title="Ventanilla de Inscripción" subtitle={`Gestión activa: ${gestionActiva?.periodo || "—"}`} />

      <div className="page-card" style={{ marginBottom: 20 }}>
        <SectionHeader title="Mis materias inscritas en esta gestión" />
        {misInscripcionesActivas.length === 0 ? (
          <EmptyState text="Aún no se ha inscrito a ninguna materia en esta gestión." />
        ) : (
          <table className="table">
            <thead><tr><th>Materia</th><th>Estado</th><th></th></tr></thead>
            <tbody>
              {misInscripcionesActivas.map((h) => (
                <tr key={h.id_detalle}>
                  <td>{h.materia.sigla} — {h.materia.nombre}</td>
                  <td><Badge>{h.estado}</Badge></td>
                  <td>
                    {h.estado === "Inscrito" && (
                      <button className="link-button danger" onClick={() => data.retirarInscripcion(h.id_detalle)}>
                        Retirar
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="page-card">
        <SectionHeader title="Materias disponibles para inscribirse" subtitle="Solo se muestran materias cuyos prerrequisitos ya cumplió (o que aún no aprueba)" />
        <div className="materia-grid">
          {materiasDisponibles.map((m) => {
            const check = data.puedeInscribirse(estudiante.id_persona, plan.id_plan, m.id_materia);
            return (
              <button
                key={m.id_materia}
                className={`materia-card ${check.ok ? "materia-blue" : "materia-locked"}`}
                onClick={() => (check.ok ? setIdMateria(m.id_materia) : alert(check.motivo))}
                type="button"
              >
                <strong>{m.materia.sigla}</strong>
                <span>{m.materia.nombre}</span>
                <small>{check.ok ? "Disponible" : "🔒 " + check.motivo}</small>
              </button>
            );
          })}
        </div>
      </div>

      {idMateria && (
        <div className="modal-backdrop" onClick={() => setIdMateria(null)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Elegir paralelo</h3>
              <button className="link-button" onClick={() => setIdMateria(null)}>Cerrar ✕</button>
            </div>
            {paralelos.length === 0 ? (
              <EmptyState text="No hay paralelos ofertados para esta materia en la gestión activa." />
            ) : (
              <table className="table">
                <thead><tr><th>Paralelo</th><th>Docente</th><th>Cupo</th><th></th></tr></thead>
                <tbody>
                  {paralelos.map((p) => (
                    <tr key={p.id_paralelo}>
                      <td>{p.nombre}</td>
                      <td>{p.docenteNombre}</td>
                      <td>{p.cupo_disponible} / {p.cupo_maximo}</td>
                      <td>
                        <button
                          className="primary-button small"
                          disabled={p.cupo_disponible <= 0}
                          onClick={() => inscribir(p.id_paralelo)}
                        >
                          {p.cupo_disponible <= 0 ? "Sin cupo" : "Inscribirme"}
                        </button>
                      </td>
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

function VistaAdministrador({ data, gestionActiva }) {
  const [idGestion, setIdGestion] = useState(gestionActiva?.id_gestion);
  const [filtroEstudiante, setFiltroEstudiante] = useState("");

  const filas = useMemo(() => {
    return data.estudiantes
      .map((e) => {
        const persona = data.getPersona(e.id_persona);
        const historial = data.getHistorialEstudiante(e.id_persona).filter((h) => h.gestion.id_gestion === idGestion);
        return { estudiante: e, persona, historial };
      })
      .filter((f) => {
        const q = filtroEstudiante.toLowerCase();
        return !q || `${f.persona.nombres} ${f.persona.apellidos} ${f.estudiante.ru}`.toLowerCase().includes(q);
      });
  }, [data, idGestion, filtroEstudiante]);

  const cambiarEstado = (id_detalle, estado) => {
    data.actualizarEstadoDetalle(id_detalle, { estado });
  };

  return (
    <div>
      <SectionHeader
        title="Ventanilla de Inscripción — Administración"
        subtitle="El administrativo puede revisar y modificar la inscripción de cualquier estudiante"
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
            <EmptyState text="Sin inscripciones en esta gestión." />
          ) : (
            <table className="table">
              <thead><tr><th>Materia</th><th>Estado</th><th>Nota</th><th>Acciones</th></tr></thead>
              <tbody>
                {f.historial.map((h) => (
                  <tr key={h.id_detalle}>
                    <td>{h.materia.sigla} — {h.materia.nombre}</td>
                    <td><Badge>{h.estado}</Badge></td>
                    <td>{h.nota_final}</td>
                    <td>
                      <select value={h.estado} onChange={(e) => cambiarEstado(h.id_detalle, e.target.value)}>
                        <option value="Inscrito">Inscrito</option>
                        <option value="Aprobado">Aprobado</option>
                        <option value="Reprobado">Reprobado</option>
                        <option value="Abandono">Abandono</option>
                      </select>
                      <button className="link-button danger" onClick={() => data.retirarInscripcion(h.id_detalle)}>Eliminar</button>
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
