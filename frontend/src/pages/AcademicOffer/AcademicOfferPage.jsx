import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { useToast } from "../../context/ToastContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { SkeletonCard } from "../../components/Common/SkeletonLoader";
import CurriculumFlowModal from "../../components/CurriculumFlow/CurriculumFlowModal";

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
  const { showSuccess, showError, showInfo } = useToast();

  const esEstudiante = session?.rolActivo === "ESTUDIANTE";
  const esDocente = session?.rolActivo === "DOCENTE";
  const esAdminDirector = session?.rolActivo === "ADMIN" || session?.rolActivo === "DIRECTOR";

  const targetCarreraId = session?.id_carrera || data.idCarreraActiva || 1;
  const carrera = data.getCarrera(targetCarreraId);
  const planesCarrera = data.getPlanesPorCarrera(carrera.id_carrera);
  const gestionActiva = data.getGestionActiva();

  // Estados principales
  const userPlanId = session?.id_plan || session?.estudiante?.id_plan;
  const [idPlan, setIdPlan] = useState(userPlanId || planesCarrera[0]?.id_plan || 1);
  const [seleccionada, setSeleccionada] = useState(null);
  const [mostrarModalTomar, setMostrarModalTomar] = useState(false);
  const [mostrarFlujo, setMostrarFlujo] = useState(false);
  const [tabDocente, setTabDocente] = useState("malla"); // "malla" | "mis_materias"
  const [idDocenteFiltroAdmin, setIdDocenteFiltroAdmin] = useState(session?.id_persona || 1);

  const planActual = planesCarrera.find((p) => Number(p.id_plan) === Number(idPlan)) || planesCarrera[0] || (data.planes && data.planes[0]);
  const pensumCompleto = useMemo(() => (planActual ? data.getPensumPlan(planActual.id_plan) : []), [planActual, data]);

  // Clasificación de materias del pensum con su tipo
  const pensumClasificado = useMemo(() => {
    return pensumCompleto.map((pm) => ({
      ...pm,
      tipo_materia: getTipoMateria(pm.materia?.sigla, pm.materia?.nombre),
    }));
  }, [pensumCompleto]);

  // Materias por semestre para el plan seleccionado
  const porSemestre = useMemo(() => {
    const grupos = {};
    pensumClasificado.forEach((m) => {
      grupos[m.semestre] = grupos[m.semestre] || [];
      grupos[m.semestre].push(m);
    });
    return grupos;
  }, [pensumClasificado]);

  // ID del docente cuyo expediente estamos consultando (el usuario activo si es DOCENTE, o el seleccionado si es ADMIN)
  const idDocenteObjetivo = esDocente ? session?.id_persona : idDocenteFiltroAdmin;

  // Mis materias dictadas en la gestión activa
  const misMateriasGestionActiva = useMemo(() => {
    if (!idDocenteObjetivo) return [];
    return (data.paralelos || []).filter(
      (p) => Number(p.id_docente) === Number(idDocenteObjetivo) && p.id_gestion === gestionActiva?.id_gestion
    );
  }, [data.paralelos, idDocenteObjetivo, gestionActiva]);

  // Historial completo de materias dictadas (todas las gestiones)
  const historialMateriasDictadas = useMemo(() => {
    if (!idDocenteObjetivo) return [];
    return (data.paralelos || [])
      .filter((p) => Number(p.id_docente) === Number(idDocenteObjetivo))
      .map((p) => {
        const mat = data.getMateria ? data.getMateria(p.id_materia) : null;
        const gest = (data.gestiones || []).find((g) => Number(g.id_gestion) === Number(p.id_gestion));
        const sec = (data.seCursa || []).find((s) => Number(s.id_materia) === Number(p.id_materia) && Number(s.id_paralelo) === Number(p.id_paralelo));
        const aulaObj = sec ? (data.aulas || []).find((a) => Number(a.id_aula) === Number(sec.id_aula)) : null;
        const horObj = sec ? (data.horarios || []).find((h) => Number(h.id_horario) === Number(sec.id_horario)) : null;
        const aulaTexto = aulaObj ? (aulaObj.nombre || (aulaObj.numero ? `Aula ${aulaObj.numero}` : `Aula #${aulaObj.id_aula}`)) : 'Sin asignación';

        return {
          ...p,
          materiaNombre: mat?.nombre || `Materia #${p.id_materia}`,
          materiaSigla: mat?.sigla || `MAT-${p.id_materia}`,
          periodoGestion: gest?.periodo || `Gestión ${p.id_gestion}`,
          estadoGestion: gest?.estado || 'Cerrada',
          aulaNombre: aulaTexto,
          horarioStr: horObj ? `${horObj.dia} ${horObj.hora_inicio} - ${horObj.hora_fin}` : 'Horario a definir'
        };
      });
  }, [data.paralelos, idDocenteObjetivo, data.gestiones, data.seCursa, data.aulas, data.horarios, data]);

  // Paralelos disponibles sin docente asignado en la gestión activa
  const paralelosSinDocente = useMemo(() => {
    return (data.paralelos || [])
      .filter((p) => (!p.id_docente || Number(p.id_docente) === 0) && Number(p.id_gestion) === Number(gestionActiva?.id_gestion))
      .map((p) => {
        const mat = data.getMateria ? data.getMateria(p.id_materia) : null;
        const sec = (data.seCursa || []).find((s) => Number(s.id_materia) === Number(p.id_materia) && Number(s.id_paralelo) === Number(p.id_paralelo));
        const aulaObj = sec ? (data.aulas || []).find((a) => Number(a.id_aula) === Number(sec.id_aula)) : null;
        const horObj = sec ? (data.horarios || []).find((h) => Number(h.id_horario) === Number(sec.id_horario)) : null;
        const aulaTexto = aulaObj ? (aulaObj.nombre || (aulaObj.numero ? `Aula ${aulaObj.numero}` : `Aula #${aulaObj.id_aula}`)) : 'Aula a definir';

        return {
          ...p,
          materiaNombre: mat?.nombre || `Materia #${p.id_materia}`,
          materiaSigla: mat?.sigla || `MAT-${p.id_materia}`,
          aulaNombre: aulaTexto,
          horarioStr: horObj ? `${horObj.dia} ${horObj.hora_inicio} - ${horObj.hora_fin}` : 'Horario a definir'
        };
      });
  }, [data.paralelos, gestionActiva, data.seCursa, data.aulas, data.horarios, data]);

  // Acción para tomar / solicitar dictar una materia
  const handleSolicitarMateria = async (id_materia, id_paralelo) => {
    try {
      await data.asignarDocenteParalelo(id_materia, id_paralelo, idDocenteObjetivo);
      showSuccess(`Materia asignada exitosamente al docente.`);
    } catch (err) {
      const msg = err?.response?.data?.error || err?.response?.data?.detalle || err.message || "Error al solicitar materia";
      showError(msg);
    }
  };

  // Acción para desasignar / liberar una materia
  const handleDesasignarMateria = async (id_materia, id_paralelo) => {
    try {
      await data.desasignarDocenteParalelo(id_materia, id_paralelo);
      showInfo("Asignación de materia removida.");
    } catch (err) {
      showError(err.message || "Error al desasignar materia.");
    }
  };

  const paralelosSeleccionada = seleccionada
    ? data.getParalelosOferta(seleccionada.id_materia, gestionActiva?.id_gestion || 1)
    : [];

  return (
    <div>
      <SectionHeader
        title={`Oferta Académica y Menciones — ${carrera.nombre}`}
        subtitle={
          esDocente
            ? `Malla curricular de todas las menciones y postulación a materias (${gestionActiva?.periodo || 'Gestión Activa'})`
            : esEstudiante
            ? `Plan de estudios por mención y avance curricular (${gestionActiva?.periodo || 'Gestión Activa'})`
            : `Mapeo estructural de menciones y asignación docente en ${carrera.nombre}`
        }
        actions={
          <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap" }}>
            {planesCarrera.length > 0 && (
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <label style={{ fontSize: "0.85rem", fontWeight: 600, color: "#3a4c66" }}>Mención / Plan:</label>
                <select value={planActual?.id_plan} onChange={(e) => setIdPlan(Number(e.target.value))}>
                  {planesCarrera.map((p) => (
                    <option key={p.id_plan} value={p.id_plan}>{p.nombre}</option>
                  ))}
                </select>
              </div>
            )}

            {(esDocente || esAdminDirector) && (
              <button
                className="button primary"
                style={{ display: "flex", alignItems: "center", gap: 6, fontWeight: 600 }}
                onClick={() => setMostrarModalTomar(true)}
              >
                <span>➕</span> Tomar Materias ({paralelosSinDocente.length} libres)
              </button>
            )}
          </div>
        }
      />

      {/* Banner de Estado de Gestión Activa y Pestañas */}
      <div 
        className="page-card" 
        style={{ 
          marginBottom: 16, 
          background: "linear-gradient(135deg, #0b223d, #1d4ed8)", 
          color: "#ffffff", 
          display: "flex", 
          justify: "space-between", 
          alignItems: "center", 
          flexWrap: "wrap", 
          gap: 12,
          boxShadow: "0 10px 25px rgba(13, 34, 64, 0.25)"
        }}
      >
        <div>
          <h3 style={{ margin: "0 0 6px", fontSize: "1.15rem", fontWeight: 800, color: "#ffffff" }}>
            🎓 Mención: {planActual?.nombre || "Mención General de Carrera"}
          </h3>
          <p style={{ margin: 0, fontSize: "0.88rem", color: "#e2e8f0" }}>
            Carrera: <strong style={{ color: "#ffffff" }}>{carrera.nombre}</strong> · Gestión Académica Activa:{" "}
            <span 
              style={{ 
                background: "#10b981", 
                color: "#ffffff", 
                fontWeight: 800, 
                padding: "3px 10px", 
                borderRadius: "20px",
                fontSize: "0.78rem",
                display: "inline-block",
                marginLeft: 4
              }}
            >
              {gestionActiva?.periodo || "I/2026"}
            </span>
          </p>
          <div style={{ marginTop: 10 }}>
            <button
              type="button"
              className="button primary sm"
              style={{
                background: "linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)",
                color: "#ffffff",
                border: "none",
                fontWeight: 800,
                fontSize: "0.85rem",
                padding: "8px 16px",
                borderRadius: 8,
                boxShadow: "0 4px 12px rgba(37, 99, 235, 0.4)",
                cursor: "pointer",
                display: "inline-flex",
                alignItems: "center",
                gap: 6
              }}
              onClick={() => setMostrarFlujo(true)}
            >
              🗺️ Ver Flujo de Malla
            </button>
          </div>
        </div>

        {(esDocente || esAdminDirector) && (
          <div style={{ display: "flex", background: "rgba(0, 0, 0, 0.3)", padding: 5, borderRadius: 10, gap: 6 }}>
            <button
              type="button"
              style={{
                padding: "8px 16px",
                borderRadius: 8,
                border: "none",
                fontWeight: 800,
                fontSize: "0.85rem",
                cursor: "pointer",
                transition: "all 0.15s ease",
                background: tabDocente === "malla" ? "#ffffff" : "transparent",
                color: tabDocente === "malla" ? "#0b223d" : "#ffffff",
                boxShadow: tabDocente === "malla" ? "0 4px 12px rgba(0,0,0,0.25)" : "none"
              }}
              onClick={() => setTabDocente("malla")}
            >
              📖 Malla Curricular
            </button>
            <button
              type="button"
              style={{
                padding: "8px 16px",
                borderRadius: 8,
                border: "none",
                fontWeight: 800,
                fontSize: "0.85rem",
                cursor: "pointer",
                transition: "all 0.15s ease",
                background: tabDocente === "mis_materias" ? "#ffffff" : "transparent",
                color: tabDocente === "mis_materias" ? "#0b223d" : "#ffffff",
                boxShadow: tabDocente === "mis_materias" ? "0 4px 12px rgba(0,0,0,0.25)" : "none"
              }}
              onClick={() => setTabDocente("mis_materias")}
            >
              👨‍🏫 Materias Dictadas ({misMateriasGestionActiva.length}/3)
            </button>
          </div>
        )}
      </div>

      {/* Contenido según Pestaña */}
      {tabDocente === "mis_materias" && (esDocente || esAdminDirector) ? (
        <div className="page-card">
          {esAdminDirector && (
            <div style={{ marginBottom: 16, padding: 12, background: "#f1f5f9", borderRadius: 8, display: "flex", alignItems: "center", gap: 12 }}>
              <label style={{ fontWeight: 600, fontSize: "0.9rem" }}>Filtrar por Docente:</label>
              <select
                value={idDocenteFiltroAdmin}
                onChange={(e) => setIdDocenteFiltroAdmin(Number(e.target.value))}
                style={{ padding: "6px 12px", borderRadius: 6, border: "1px solid #cbd5e1" }}
              >
                {data.docentes.map((d) => (
                  <option key={d.id_persona} value={d.id_persona}>
                    {d.nombres} {d.apellidos} ({d.grado_academico || 'Docente'})
                  </option>
                ))}
              </select>
            </div>
          )}

          <h3 style={{ marginTop: 0, color: "#1e293b" }}>
            📚 Historial de Materias Asignadas e Impartidas
          </h3>
          <p style={{ color: "#64748b", fontSize: "0.88rem", marginBottom: 16 }}>
            Materias asignadas al docente en la gestión activa <strong>({gestionActiva?.periodo})</strong> y en gestiones anteriores. Máximo 3 materias activas por gestión.
          </p>

          {historialMateriasDictadas.length === 0 ? (
            <EmptyState text="El docente no tiene materias asignadas ni dictadas actualmente." />
          ) : (
            <div className="table-responsive">
              <table className="table">
                <thead>
                  <tr>
                    <th>Gestión</th>
                    <th>Sigla / Asignatura</th>
                    <th>Paralelo</th>
                    <th>Aula y Horario</th>
                    <th>Cupo</th>
                    <th>Estado Gestión</th>
                    <th>Acción</th>
                  </tr>
                </thead>
                <tbody>
                  {historialMateriasDictadas.map((m) => (
                    <tr key={`${m.id_materia}-${m.id_paralelo}-${m.id_gestion}`}>
                      <td>
                        <span className="badge badge-info" style={{ fontWeight: 700 }}>{m.periodoGestion}</span>
                      </td>
                      <td>
                        <strong>{m.materiaSigla}</strong> — {m.materiaNombre}
                      </td>
                      <td>
                        <strong>Paralelo {m.nombre}</strong>
                      </td>
                      <td>
                        <small>{m.aulaNombre} · {m.horarioStr}</small>
                      </td>
                      <td>{m.cupo_actual} / {m.cupo_maximo}</td>
                      <td>
                        <span className={`badge ${(m.estadoGestion || '').toLowerCase() === 'activa' ? 'badge-success' : 'badge-secondary'}`}>
                          {m.estadoGestion}
                        </span>
                      </td>
                      <td>
                        {(m.estadoGestion || '').toLowerCase() === 'activa' && (
                          <button
                            className="button danger sm"
                            onClick={() => handleDesasignarMateria(m.id_materia, m.id_paralelo)}
                          >
                            Renunciar / Soltar
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : (
        <>
          {/* Leyenda de Clasificación por Tipo de Materia */}
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
            <EmptyState text="Esta mención aún no tiene asignaturas en el pensum." />
          ) : (
            Object.entries(porSemestre)
              .sort(([a], [b]) => a - b)
              .map(([semestre, materias]) => (
                <div key={semestre} className="page-card semester-block">
                  <h3 className="semester-title">Semestre {semestre}</h3>
                  <div className="materia-grid">
                    {materias.map((m) => {
                      const idMateriaTarget = m.id_materia || m.materia?.id_materia;
                      const estadoEstudiante = esEstudiante
                        ? data.getEstadoMateriaParaEstudiante(session.id_persona, idMateriaTarget)
                        : null;
                      const claseEstado = estadoEstudiante ? ESTADO_INFO[estadoEstudiante].clase : "";
                      const tipoStyle = TIPO_MATERIA_STYLES[m.tipo_materia] || TIPO_MATERIA_STYLES["Corriente"];
                      const oferta = data.getParalelosOferta(idMateriaTarget, gestionActiva?.id_gestion);

                      return (
                        <button
                          key={idMateriaTarget || m.id_materia}
                          className={`materia-card ${tipoStyle.clase} ${claseEstado}`}
                          onClick={() => setSeleccionada({ ...m, id_materia: idMateriaTarget })}
                          type="button"
                        >
                          <span className={`tipo-tag ${tipoStyle.clase}`}>
                            {m.tipo_materia}
                          </span>
                          <strong>{m.materia?.sigla}</strong>
                          <span>{m.materia?.nombre}</span>
                          <small>
                            {m.materia?.creditos || m.materia?.carga_horaria} hrs · {oferta.length} paralelo(s) [{gestionActiva?.periodo || 'I/2026'}]
                          </small>
                        </button>
                      );
                    })}
                  </div>
                </div>
              ))
          )}
        </>
      )}

      {/* Modal de Detalle de Materia Seleccionada */}
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
                Mención: <strong>{planActual?.nombre}</strong> · Gestión: <strong>{gestionActiva?.periodo || 'I/2026'}</strong>
              </p>
            </div>

            {paralelosSeleccionada.length === 0 ? (
              <EmptyState text="No hay paralelos aperturados en la gestión activa para esta asignatura." />
            ) : (
              <table className="table">
                <thead>
                  <tr>
                    <th>Paralelo</th>
                    <th>Docente Asignado</th>
                    <th>Horario y Aula</th>
                    <th>Cupo</th>
                    {(esDocente || esAdminDirector) && <th>Acción</th>}
                  </tr>
                </thead>
                <tbody>
                  {paralelosSeleccionada.map((p) => {
                    const sinDocente = !p.id_docente || Number(p.id_docente) === 0;
                    const esMiMateria = Number(p.id_docente) === Number(idDocenteObjetivo);

                    return (
                      <tr key={p.id_paralelo}>
                        <td><strong>Paralelo {p.nombre}</strong></td>
                        <td>
                          {sinDocente ? (
                            <span className="badge badge-warning" style={{ background: "#f39c12", color: "#fff" }}>Disponible (Sin Docente)</span>
                          ) : (
                            <span style={{ fontWeight: esMiMateria ? 700 : 400, color: esMiMateria ? "#1a5fb4" : "inherit" }}>
                              {p.docenteNombre} {esMiMateria && "(Tú)"}
                            </span>
                          )}
                        </td>
                        <td>
                          {(() => {
                            const sec = (data.seCursa || []).find((s) => Number(s.id_materia) === Number(p.id_materia) && Number(s.id_paralelo) === Number(p.id_paralelo));
                            const aulaObj = sec ? (data.aulas || []).find((a) => Number(a.id_aula) === Number(sec.id_aula)) : null;
                            const horObj = sec ? (data.horarios || []).find((h) => Number(h.id_horario) === Number(sec.id_horario)) : (p.horario ? (data.horarios || []).find((h) => Number(h.id_horario) === Number(p.horario.id_horario)) : null);
                            const aulaTxt = aulaObj ? (aulaObj.nombre || (aulaObj.numero ? `Aula ${aulaObj.numero}` : `Aula #${aulaObj.id_aula}`)) : '';
                            const horTxt = horObj ? `${horObj.dia} ${horObj.hora_inicio} - ${horObj.hora_fin}` : 'Horario a definir';
                            return aulaTxt ? `${aulaTxt} · ${horTxt}` : horTxt;
                          })()}
                        </td>
                        <td>
                          <strong>{p.cupo_actual || 0}</strong> / {p.cupo_maximo}{" "}
                          <small style={{ color: "#64748b" }}>({p.cupo_disponible} libres)</small>
                        </td>
                        {(esDocente || esAdminDirector) && (
                          <td>
                            {sinDocente ? (
                              <button
                                className="button primary sm"
                                onClick={() => handleSolicitarMateria(p.id_materia, p.id_paralelo)}
                              >
                                ➕ Solicitar Impartir
                              </button>
                            ) : esMiMateria ? (
                              <button
                                className="button danger sm"
                                onClick={() => handleDesasignarMateria(p.id_materia, p.id_paralelo)}
                              >
                                Renunciar
                              </button>
                            ) : (
                              <span style={{ fontSize: "0.8rem", color: "#94a3b8" }}>Ocupado</span>
                            )}
                          </td>
                        )}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Modal Modal "Tomar Materias — Oferta Disponible (Sin Docente)" */}
      {mostrarModalTomar && (
        <div className="modal-backdrop" onClick={() => setMostrarModalTomar(false)}>
          <div className="modal-card" style={{ maxWidth: 780, width: "92%" }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>👨‍🏫 Tomar Materias Disponibles — Gestión {gestionActiva?.periodo || 'I/2026'}</h3>
              <button className="link-button" onClick={() => setMostrarModalTomar(false)}>Cerrar ✕</button>
            </div>

            <p style={{ fontSize: "0.88rem", color: "#475569", marginBottom: 16 }}>
              Seleccione cualquier materia aperturada que no tenga docente asignado. Puede tomar <strong>máximo 3 materias</strong> por gestión.
            </p>

            {paralelosSinDocente.length === 0 ? (
              <EmptyState text="No hay paralelos disponibles sin docente en esta gestión." />
            ) : (
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 12, maxHeight: 420, overflowY: "auto", paddingRight: 4 }}>
                {paralelosSinDocente.map((p) => (
                  <div
                    key={`${p.id_materia}-${p.id_paralelo}`}
                    style={{
                      padding: 14,
                      borderRadius: 10,
                      border: "1px solid #e2e8f0",
                      background: "#f8fafc",
                      display: "flex",
                      flexDirection: "column",
                      justify: "space-between",
                      gap: 8
                    }}
                  >
                    <div>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                        <strong style={{ fontSize: "1rem", color: "#1e293b" }}>{p.materiaSigla}</strong>
                        <span className="badge badge-info">Paralelo {p.nombre}</span>
                      </div>
                      <div style={{ fontSize: "0.9rem", color: "#334155", marginTop: 4, fontWeight: 600 }}>
                        {p.materiaNombre}
                      </div>
                      <div style={{ fontSize: "0.8rem", color: "#64748b", marginTop: 4 }}>
                        {p.aulaNombre} · {p.horarioStr} · Cupo: {p.cupo_maximo}
                      </div>
                    </div>

                    <button
                      className="button primary sm"
                      style={{ marginTop: 6, alignSelf: "flex-end", fontWeight: 600 }}
                      onClick={() => {
                        handleSolicitarMateria(p.id_materia, p.id_paralelo);
                      }}
                    >
                      ➕ Solicitar Impartir
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {mostrarFlujo && (
        <CurriculumFlowModal
          plan={planActual}
          data={data}
          estudiante={session?.estudiante || { id_persona: session?.id_persona }}
          onClose={() => setMostrarFlujo(false)}
        />
      )}
    </div>
  );
}
