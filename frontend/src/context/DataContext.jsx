import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { catalogService, enrollmentService, gradesService, usersService } from "../services/api";
import { NOTA_APROBACION, fullName } from "../data/mockData";

const DataContext = createContext(null);

export function DataProvider({ children }) {
  const [carreras, setCarreras] = useState([]);
  const [planes, setPlanes] = useState([]);
  const [materias, setMaterias] = useState([]);
  const [planMateria, setPlanMateria] = useState([]);
  const [prerequisitos, setPrerequisitos] = useState([]);
  const [gestiones, setGestiones] = useState([]);
  const [paralelos, setParalelos] = useState([]);
  const [aulas, setAulas] = useState([]);
  const [horarios, setHorarios] = useState([]);
  const [seCursa, setSeCursa] = useState([]);
  const [roles, setRoles] = useState([]);

  const [usuarios, setUsuarios] = useState([]);
  const [personas, setPersonas] = useState([]);
  const [tieneRol, setTieneRol] = useState([]);
  const [estudiantes, setEstudiantes] = useState([]);
  const [docentes, setDocentes] = useState([]);

  const [inscripciones, setInscripciones] = useState([]);
  const [detalle, setDetalle] = useState([]);
  const [criterios, setCriterios] = useState([]);
  const [notas, setNotas] = useState([]);
  const [loadingBackend, setLoadingBackend] = useState(true);

  // Carrera activa seleccionada para el ámbito de Administración / Dirección
  const [idCarreraActiva, setIdCarreraActiva] = useState(1);

  // Carga dinámica desde la base de datos MySQL (sistemaacademicooficial.sql)
  const reloadFromBackend = async () => {
    try {
      setLoadingBackend(true);
      const [
        resCarreras,
        resPlanes,
        resMaterias,
        resGestiones,
        resParalelos,
        resAulas,
        resHorarios,
        resSeCursa,
        resUsuarios,
        resActores,
        resInscripciones,
        resPlanMaterias,
        resPrerequisitos,
        resRoles,
        resEstudiantes,
        resDocentes,
      ] = await Promise.allSettled([
        catalogService.carreras(),
        catalogService.planes(),
        catalogService.materias(),
        catalogService.gestiones(),
        catalogService.paralelos(),
        catalogService.aulas(),
        catalogService.horarios(),
        catalogService.seCursa(),
        usersService.list(),
        catalogService.actores(),
        enrollmentService.listar(),
        catalogService.planMaterias(),
        catalogService.prerequisitos(),
        catalogService.roles(),
        catalogService.estudiantes(),
        catalogService.docentes(),
      ]);

      if (resCarreras.status === "fulfilled" && Array.isArray(resCarreras.value.data) && resCarreras.value.data.length > 0) {
        setCarreras(resCarreras.value.data);
      } else {
        setCarreras([
          { id_carrera: 1, nombre: "Ingeniería de Sistemas" },
          { id_carrera: 2, nombre: "Ingeniería Informática" }
        ]);
      }

      if (resPlanes.status === "fulfilled" && Array.isArray(resPlanes.value.data) && resPlanes.value.data.length > 0) {
        setPlanes(resPlanes.value.data);
      } else {
        setPlanes([
          { id_plan: 1, nombre: "Plan 2020 — Mención Desarrollo de Software", id_carrera: 1 },
          { id_plan: 2, nombre: "Plan 2020 — Mención Redes y Teledefinición", id_carrera: 1 },
          { id_plan: 3, nombre: "Plan 2021 — Mención Ciencia de Datos", id_carrera: 2 },
        ]);
      }

      if (resMaterias.status === "fulfilled" && Array.isArray(resMaterias.value.data)) {
        setMaterias(resMaterias.value.data.map(m => ({
          ...m,
          carga_horaria: m.carga_horaria || m.creditos || 5,
          creditos: m.carga_horaria || m.creditos || 5
        })));
      }
      if (resGestiones.status === "fulfilled" && Array.isArray(resGestiones.value.data)) {
        setGestiones(resGestiones.value.data);
      }
      if (resParalelos.status === "fulfilled" && Array.isArray(resParalelos.value.data)) {
        setParalelos(resParalelos.value.data);
      }
      if (resAulas.status === "fulfilled" && Array.isArray(resAulas.value.data)) {
        setAulas(resAulas.value.data.map(a => ({ ...a, piso: a.piso || 'Piso 1' })));
      }
      if (resHorarios.status === "fulfilled" && Array.isArray(resHorarios.value.data)) {
        setHorarios(resHorarios.value.data);
      }
      if (resSeCursa.status === "fulfilled" && Array.isArray(resSeCursa.value.data)) {
        setSeCursa(resSeCursa.value.data);
      }
      if (resPlanMaterias.status === "fulfilled" && Array.isArray(resPlanMaterias.value.data)) {
        setPlanMateria(resPlanMaterias.value.data);
      }
      if (resPrerequisitos.status === "fulfilled" && Array.isArray(resPrerequisitos.value.data)) {
        setPrerequisitos(resPrerequisitos.value.data);
      }
      if (resRoles.status === "fulfilled" && Array.isArray(resRoles.value.data)) {
        setRoles(resRoles.value.data);
      }

      if (resUsuarios.status === "fulfilled" && Array.isArray(resUsuarios.value.data)) {
        setUsuarios(resUsuarios.value.data);
      }

      if (resActores.status === "fulfilled" && Array.isArray(resActores.value.data)) {
        setPersonas(resActores.value.data);
      }

      if (resEstudiantes.status === "fulfilled" && Array.isArray(resEstudiantes.value.data)) {
        setEstudiantes(resEstudiantes.value.data);
      }

      if (resDocentes.status === "fulfilled" && Array.isArray(resDocentes.value.data)) {
        setDocentes(resDocentes.value.data);
      }

      if (resInscripciones.status === "fulfilled" && Array.isArray(resInscripciones.value.data)) {
        const rawIns = resInscripciones.value.data;
        const newIns = [];
        const newDet = [];

        rawIns.forEach((row, index) => {
          const id_inscripcion = row.id_inscripcion || index + 1;
          const id_detalle = row.id_detalle || index + 1;
          if (!newIns.some((i) => i.id_inscripcion === id_inscripcion)) {
            newIns.push({
              id_inscripcion,
              id_estudiante: row.id_estudiante || row.id_persona || 1,
              id_gestion: row.id_gestion || 1,
              fecha_registro: row.fecha_registro || new Date().toISOString().slice(0, 10),
            });
          }
          newDet.push({
            id_detalle,
            id_inscripcion,
            id_materia: row.id_materia,
            id_paralelo: row.id_paralelo || 1,
            estado: row.estado || "Inscrito",
            nota_final: row.nota_final || 0,
          });
        });

        setInscripciones(newIns);
        setDetalle(newDet);
      }
    } catch (error) {
      console.warn("API Backend notice:", error.message);
    } finally {
      setLoadingBackend(false);
    }
  };

  useEffect(() => {
    reloadFromBackend();
  }, []);

  // Derivación segura de estudiantes y docentes por carrera
  const estudiantesCalculados = useMemo(() => {
    if (estudiantes.length > 0) return estudiantes;
    const fuente = personas.length > 0 ? personas : usuarios;
    return fuente.map((p) => ({
      id_persona: p.id_persona,
      ru: p.ru || `RU-${p.id_persona}`,
      id_plan: p.id_plan || 1,
      anio_ingreso: p.anio_ingreso || 2021,
    }));
  }, [estudiantes, personas, usuarios]);

  const docentesCalculados = useMemo(() => {
    if (docentes.length > 0) return docentes;
    const fuente = personas.length > 0 ? personas : usuarios;
    return fuente.map((p) => ({
      id_persona: p.id_persona,
      registro_docente: p.registro_docente || `DOC-${p.id_persona}`,
      grado_academico: p.grado_academico || "Lic.",
    }));
  }, [docentes, personas, usuarios]);

  // ---------- Helpers de jerarquía Carrera -> Plan de Estudio (Menciones) -> Materias ----------

  const getCarrera = (id_carrera) => carreras.find((c) => c.id_carrera === id_carrera) || carreras[0] || { id_carrera: 1, nombre: "Ingeniería de Sistemas" };

  const getPlanesPorCarrera = (id_carrera) => {
    const arr = planes.filter((p) => p.id_carrera === id_carrera);
    return arr.length > 0 ? arr : planes.slice(0, 2);
  };

  const getPersona = (id_persona) => {
    const fromP = personas.find((p) => p.id_persona === id_persona);
    if (fromP && fromP.nombres) return fromP;
    const fromU = usuarios.find((u) => u.id_persona === id_persona || u.id_usuario === id_persona);
    if (fromU) return {
      id_persona: fromU.id_persona || id_persona,
      nombres: fromU.nombres || fromU.username,
      apellidos: fromU.apellidos || "",
      ci: fromU.ci || "—",
      email: fromU.email || "—"
    };
    return { id_persona, nombres: "—", apellidos: "", ci: "—", email: "—" };
  };

  const getGestionActiva = () => gestiones.find((g) => g.estado === "Activa") || gestiones[gestiones.length - 1] || { id_gestion: 1, periodo: "I/2026", estado: "Activa" };

  const getDocenteNombre = (id_persona) => fullName(getPersona(id_persona));

  const getMateria = (id_materia) => materias.find((m) => m.id_materia === id_materia) || { id_materia, sigla: `MAT-${id_materia}`, nombre: `Materia ${id_materia}`, creditos: 5 };

  const getPensumPlan = (id_plan) =>
    planMateria
      .filter((pm) => pm.id_plan === id_plan)
      .map((pm) => ({ ...pm, materia: getMateria(pm.id_materia) }))
      .filter((pm) => pm.materia)
      .sort((a, b) => a.semestre - b.semestre || a.materia.sigla.localeCompare(b.materia.sigla));

  const getPrerrequisitos = (id_plan, id_materia) =>
    prerequisitos
      .filter((p) => p.id_plan === id_plan && p.id_materia === id_materia)
      .map((p) => p.id_materia_req);

  const getHistorialEstudiante = (id_estudiante) => {
    const insEst = inscripciones.filter((i) => i.id_estudiante === id_estudiante);
    const idsIns = insEst.map((i) => i.id_inscripcion);
    return detalle
      .filter((d) => idsIns.includes(d.id_inscripcion))
      .map((d) => {
        const ins = insEst.find((i) => i.id_inscripcion === d.id_inscripcion);
        const gestion = gestiones.find((g) => g.id_gestion === (ins ? ins.id_gestion : 1)) || { id_gestion: 1, periodo: "I/2026" };
        return { ...d, gestion, materia: getMateria(d.id_materia) };
      })
      .filter((d) => d.gestion && d.materia)
      .sort((a, b) => a.gestion.periodo.localeCompare(b.gestion.periodo));
  };

  const getEstadoMateriaParaEstudiante = (id_estudiante, id_materia) => {
    const historial = getHistorialEstudiante(id_estudiante).filter((h) => h.id_materia === id_materia);
    if (historial.some((h) => h.estado === "Aprobado")) return "aprobada";
    if (historial.some((h) => h.estado === "Inscrito")) return "cursando";
    if (historial.length && historial.every((h) => h.estado === "Reprobado")) return "reprobada";
    return "pendiente";
  };

  const getMateriasAprobadas = (id_estudiante) =>
    getHistorialEstudiante(id_estudiante)
      .filter((h) => h.estado === "Aprobado")
      .map((h) => h.id_materia);

  const getParalelosOferta = (id_materia, id_gestion) =>
    paralelos
      .filter((p) => p.id_materia === id_materia && p.id_gestion === id_gestion)
      .map((p) => ({
        ...p,
        cupo_disponible: (p.cupo_maximo || 40) - (p.cupo_actual || 0),
        docenteNombre: getDocenteNombre(p.id_docente),
        horario: seCursa.find((s) => s.id_materia === id_materia && s.id_paralelo === p.id_paralelo),
      }));

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

  // ---------- Mutaciones asíncronas conectadas con la API REST de MySQL ----------

  const crearUsuario = async (usuarioNuevo, personaNueva, idsRol) => {
    await usersService.create({ usuario: usuarioNuevo, persona: personaNueva, idsRol, id_rol: idsRol?.[0] || 1 });
    await reloadFromBackend();
  };

  const toggleUsuarioActivo = async (id_usuario) => {
    await usersService.delete(id_usuario);
    await reloadFromBackend();
  };

  const inscribirMateria = async (id_estudiante, id_gestion, id_materia, id_paralelo, id_plan = 1) => {
    await enrollmentService.inscribir({
      id_estudiante,
      id_gestion,
      id_plan,
      id_materia,
      id_paralelo,
    });
    await reloadFromBackend();
  };

  const retirarInscripcion = async (id_detalle) => {
    await enrollmentService.retirar(id_detalle);
    await reloadFromBackend();
  };

  const actualizarEstadoDetalle = (id_detalle, cambios) => {
    setDetalle((prev) => prev.map((d) => (d.id_detalle === id_detalle ? { ...d, ...cambios } : d)));
  };

  const crearCriterio = async (id_materia, id_paralelo, nombre, ponderacion) => {
    await gradesService.crearCriterio({ id_materia, id_paralelo, nombre, ponderacion });
    await reloadFromBackend();
  };

  const eliminarCriterio = async (id_criterio) => {
    await gradesService.eliminarCriterio(id_criterio);
    await reloadFromBackend();
  };

  const guardarNota = async (id_detalle, id_criterio, puntaje_obtenido) => {
    await gradesService.guardarNota({ id_detalle, id_criterio, nota_obtenida: puntaje_obtenido, puntaje_obtenido });
    await reloadFromBackend();
  };

  const calcularNotaFinal = (id_materia, id_paralelo, id_detalle) => {
    const crit = criterios.filter((c) => c.id_materia === id_materia && c.id_paralelo === id_paralelo);
    const totalPonderado = crit.reduce((acc, c) => {
      const nota = notas.find((n) => n.id_detalle === id_detalle && n.id_criterio === c.id_criterio);
      const puntaje = nota ? (nota.nota_obtenida !== undefined ? nota.nota_obtenida : nota.puntaje_obtenido) : 0;
      return acc + (puntaje * c.ponderacion) / 100;
    }, 0);
    return Math.round(totalPonderado * 100) / 100;
  };

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
      carreras,
      planes,
      materias,
      roles: roles.length > 0 ? roles : [{ id_rol: 1, nombre: "Administrador" }, { id_rol: 2, nombre: "Director" }, { id_rol: 3, nombre: "Docente" }, { id_rol: 4, nombre: "Estudiante" }],
      aulas,
      horarios,
      usuarios,
      tieneRol,
      personas,
      paralelos,
      inscripciones,
      detalle,
      criterios,
      notas,
      gestiones,
      idCarreraActiva,
      setIdCarreraActiva,
      getCarrera,
      getPlanesPorCarrera,
      estudiantes: estudiantesCalculados,
      docentes: docentesCalculados,
      loadingBackend,
      reloadFromBackend,
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
    [
      carreras,
      planes,
      materias,
      roles,
      usuarios,
      tieneRol,
      personas,
      paralelos,
      inscripciones,
      detalle,
      criterios,
      notas,
      gestiones,
      idCarreraActiva,
      estudiantesCalculados,
      docentesCalculados,
      aulas,
      horarios,
      seCursa,
      loadingBackend,
    ]
  );

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
}

export const useData = () => useContext(DataContext);
