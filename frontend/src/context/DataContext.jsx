import { createContext, useContext, useMemo, useState } from "react";
import {
  USUARIOS,
  TIENE_ROL,
  PERSONAS,
  CARRERAS,
  PLANES_ESTUDIO,
  MATERIAS,
  PLAN_MATERIA,
  PREREQUISITOS,
  GESTIONES,
  PARALELOS,
  DOCENTES,
  ESTUDIANTES,
  INSCRIPCIONES,
  DETALLE_INSCRIPCION,
  CRITERIOS_EVALUACION,
  NOTAS,
  AULAS,
  HORARIOS,
  SE_CURSA,
  ROLES,
  NOTA_APROBACION,
  fullName,
} from "../data/mockData";

const DataContext = createContext(null);

export function DataProvider({ children }) {
  // Estado "base de datos" completo en memoria (simulación de backend)
  const [usuarios, setUsuarios] = useState(USUARIOS);
  const [tieneRol, setTieneRol] = useState(TIENE_ROL);
  const [personas, setPersonas] = useState(PERSONAS);
  const [paralelos, setParalelos] = useState(PARALELOS);
  const [inscripciones, setInscripciones] = useState(INSCRIPCIONES);
  const [detalle, setDetalle] = useState(DETALLE_INSCRIPCION);
  const [criterios, setCriterios] = useState(CRITERIOS_EVALUACION);
  const [notas, setNotas] = useState(NOTAS);
  const [gestiones, setGestiones] = useState(GESTIONES);
  const [estudiantes] = useState(ESTUDIANTES);
  const [docentes] = useState(DOCENTES);

  // ---------- Helpers de lectura ----------
  const getPersona = (id_persona) => personas.find((p) => p.id_persona === id_persona);
  const getGestionActiva = () => gestiones.find((g) => g.estado === "Activa");

  const getDocenteNombre = (id_persona) => fullName(getPersona(id_persona));

  const getMateria = (id_materia) => MATERIAS.find((m) => m.id_materia === id_materia);

  const getPensumPlan = (id_plan) =>
    PLAN_MATERIA.filter((pm) => pm.id_plan === id_plan)
      .map((pm) => ({ ...pm, materia: getMateria(pm.id_materia) }))
      .sort((a, b) => a.semestre - b.semestre || a.materia.sigla.localeCompare(b.materia.sigla));

  const getPrerrequisitos = (id_plan, id_materia) =>
    PREREQUISITOS.filter((p) => p.id_plan === id_plan && p.id_materia === id_materia).map(
      (p) => p.id_materia_req
    );

  // Historial de un estudiante: todos los detalle_inscripcion cruzados con inscripcion->gestion
  const getHistorialEstudiante = (id_estudiante) => {
    const insEst = inscripciones.filter((i) => i.id_estudiante === id_estudiante);
    const idsIns = insEst.map((i) => i.id_inscripcion);
    return detalle
      .filter((d) => idsIns.includes(d.id_inscripcion))
      .map((d) => {
        const ins = insEst.find((i) => i.id_inscripcion === d.id_inscripcion);
        const gestion = gestiones.find((g) => g.id_gestion === ins.id_gestion);
        return { ...d, gestion, materia: getMateria(d.id_materia) };
      })
      .sort((a, b) => a.gestion.periodo.localeCompare(b.gestion.periodo));
  };

  // Estado de una materia del pensum para un estudiante: aprobada | cursando | reprobada | pendiente
  const getEstadoMateriaParaEstudiante = (id_estudiante, id_materia) => {
    const historial = getHistorialEstudiante(id_estudiante).filter((h) => h.id_materia === id_materia);
    if (historial.some((h) => h.estado === "Aprobado")) return "aprobada";
    if (historial.some((h) => h.estado === "Inscrito")) return "cursando";
    if (historial.length && historial.every((h) => h.estado === "Reprobado")) return "reprobada";
    return "pendiente";
  };

  // Materias aprobadas por un estudiante (para validar prerrequisitos)
  const getMateriasAprobadas = (id_estudiante) =>
    getHistorialEstudiante(id_estudiante)
      .filter((h) => h.estado === "Aprobado")
      .map((h) => h.id_materia);

  // Paralelos ofertados de una materia en una gestión, con cupo y docente resueltos
  const getParalelosOferta = (id_materia, id_gestion) =>
    paralelos
      .filter((p) => p.id_materia === id_materia && p.id_gestion === id_gestion)
      .map((p) => ({
        ...p,
        cupo_disponible: p.cupo_maximo - p.cupo_actual,
        docenteNombre: getDocenteNombre(p.id_docente),
        horario: SE_CURSA.find((s) => s.id_materia === id_materia && s.id_paralelo === p.id_paralelo),
      }));

  // Puede el estudiante inscribirse a esta materia (prerrequisitos cumplidos)
  const puedeInscribirse = (id_estudiante, id_plan, id_materia) => {
    const requeridas = getPrerrequisitos(id_plan, id_materia);
    if (requeridas.length === 0) return { ok: true };
    const aprobadas = getMateriasAprobadas(id_estudiante);
    const faltantes = requeridas.filter((r) => !aprobadas.includes(r));
    if (faltantes.length > 0) {
      const nombres = faltantes.map((id) => getMateria(id)?.sigla).join(", ");
      return { ok: false, motivo: `Debe aprobar primero: ${nombres}` };
    }
    return { ok: true };
  };

  // ---------- Mutaciones ----------
  const crearUsuario = (usuarioNuevo, personaNueva, idsRol) => {
    const id_persona = Math.max(...personas.map((p) => p.id_persona)) + 1;
    const id_usuario = Math.max(...usuarios.map((u) => u.id_usuario)) + 1;
    setPersonas((prev) => [...prev, { ...personaNueva, id_persona }]);
    setUsuarios((prev) => [...prev, { ...usuarioNuevo, id_usuario, id_persona }]);
    setTieneRol((prev) => [...prev, ...idsRol.map((id_rol) => ({ id_usuario, id_rol }))]);
    return id_usuario;
  };

  const toggleUsuarioActivo = (id_usuario) => {
    setUsuarios((prev) =>
      prev.map((u) => (u.id_usuario === id_usuario ? { ...u, activo: u.activo === false ? true : false } : u))
    );
  };

  const inscribirMateria = (id_estudiante, id_gestion, id_materia, id_paralelo) => {
    let id_inscripcion = inscripciones.find(
      (i) => i.id_estudiante === id_estudiante && i.id_gestion === id_gestion
    )?.id_inscripcion;

    if (!id_inscripcion) {
      id_inscripcion = Math.max(0, ...inscripciones.map((i) => i.id_inscripcion)) + 1;
      setInscripciones((prev) => [
        ...prev,
        { id_inscripcion, id_estudiante, id_gestion, fecha_registro: new Date().toISOString().slice(0, 10) },
      ]);
    }

    const id_detalle = Math.max(0, ...detalle.map((d) => d.id_detalle)) + 1;
    setDetalle((prev) => [
      ...prev,
      { id_detalle, id_inscripcion, id_materia, id_paralelo, estado: "Inscrito", nota_final: 0 },
    ]);
    setParalelos((prev) =>
      prev.map((p) =>
        p.id_materia === id_materia && p.id_paralelo === id_paralelo
          ? { ...p, cupo_actual: p.cupo_actual + 1 }
          : p
      )
    );
    return id_detalle;
  };

  const retirarInscripcion = (id_detalle) => {
    const det = detalle.find((d) => d.id_detalle === id_detalle);
    if (!det) return;
    setDetalle((prev) => prev.filter((d) => d.id_detalle !== id_detalle));
    setParalelos((prev) =>
      prev.map((p) =>
        p.id_materia === det.id_materia && p.id_paralelo === det.id_paralelo
          ? { ...p, cupo_actual: Math.max(0, p.cupo_actual - 1) }
          : p
      )
    );
  };

  const actualizarEstadoDetalle = (id_detalle, cambios) => {
    setDetalle((prev) => prev.map((d) => (d.id_detalle === id_detalle ? { ...d, ...cambios } : d)));
  };

  const crearCriterio = (id_materia, id_paralelo, nombre, ponderacion) => {
    const id_criterio = Math.max(0, ...criterios.map((c) => c.id_criterio)) + 1;
    setCriterios((prev) => [...prev, { id_criterio, id_materia, id_paralelo, nombre, ponderacion }]);
    return id_criterio;
  };

  const eliminarCriterio = (id_criterio) => {
    setCriterios((prev) => prev.filter((c) => c.id_criterio !== id_criterio));
    setNotas((prev) => prev.filter((n) => n.id_criterio !== id_criterio));
  };

  const guardarNota = (id_detalle, id_criterio, puntaje_obtenido) => {
    setNotas((prev) => {
      const existe = prev.find((n) => n.id_detalle === id_detalle && n.id_criterio === id_criterio);
      if (existe) {
        return prev.map((n) =>
          n.id_detalle === id_detalle && n.id_criterio === id_criterio ? { ...n, puntaje_obtenido } : n
        );
      }
      const id_nota = Math.max(0, ...prev.map((n) => n.id_nota)) + 1;
      return [...prev, { id_nota, id_detalle, id_criterio, puntaje_obtenido }];
    });
  };

  // Calcula la nota_final de un detalle en base a sus criterios y notas registradas
  const calcularNotaFinal = (id_materia, id_paralelo, id_detalle) => {
    const crit = criterios.filter((c) => c.id_materia === id_materia && c.id_paralelo === id_paralelo);
    const totalPonderado = crit.reduce((acc, c) => {
      const nota = notas.find((n) => n.id_detalle === id_detalle && n.id_criterio === c.id_criterio);
      const puntaje = nota ? nota.puntaje_obtenido : 0;
      return acc + (puntaje * c.ponderacion) / 100;
    }, 0);
    return Math.round(totalPonderado * 100) / 100;
  };

  // Cierre de gestión: recalcula nota_final y estado (Aprobado/Reprobado) de todo "Inscrito", cierra la gestión
  const cerrarGestion = (id_gestion) => {
    const insIds = inscripciones.filter((i) => i.id_gestion === id_gestion).map((i) => i.id_inscripcion);
    setDetalle((prev) =>
      prev.map((d) => {
        if (!insIds.includes(d.id_inscripcion) || d.estado !== "Inscrito") return d;
        const notaFinal = calcularNotaFinal(d.id_materia, d.id_paralelo, d.id_detalle);
        return {
          ...d,
          nota_final: notaFinal,
          estado: notaFinal >= NOTA_APROBACION ? "Aprobado" : "Reprobado",
        };
      })
    );
    setGestiones((prev) => prev.map((g) => (g.id_gestion === id_gestion ? { ...g, estado: "Cerrada" } : g)));
  };

  const value = useMemo(
    () => ({
      // catálogos estáticos
      carreras: CARRERAS,
      planes: PLANES_ESTUDIO,
      materias: MATERIAS,
      roles: ROLES,
      aulas: AULAS,
      horarios: HORARIOS,
      // estado dinámico
      usuarios,
      tieneRol,
      personas,
      paralelos,
      inscripciones,
      detalle,
      criterios,
      notas,
      gestiones,
      estudiantes,
      docentes,
      // helpers
      getPersona,
      getGestionActiva,
      getDocenteNombre,
      getMateria,
      getPensumPlan,
      getPrerrequisitos,
      getHistorialEstudiante,
      getEstadoMateriaParaEstudiante,
      getMateriasAprobadas,
      getParalelosOferta,
      puedeInscribirse,
      crearUsuario,
      toggleUsuarioActivo,
      inscribirMateria,
      retirarInscripcion,
      actualizarEstadoDetalle,
      crearCriterio,
      eliminarCriterio,
      guardarNota,
      calcularNotaFinal,
      cerrarGestion,
    }),
    [usuarios, tieneRol, personas, paralelos, inscripciones, detalle, criterios, notas, gestiones, estudiantes, docentes]
  );

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
}

export const useData = () => useContext(DataContext);
