import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { catalogService, enrollmentService, gradesService, usersService, gestionCloseService, paraleloService } from "../services/api";
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
  const [auditoria, setAuditoria] = useState([]);
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
        resCriterios,
        resNotas,
        resAuditoria,
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
        gradesService.todosCriterios(),
        gradesService.todasNotas(),
        gestionCloseService.auditoria(),
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

      // Cargar criterios de evaluación (carga global)
      if (resCriterios.status === "fulfilled" && Array.isArray(resCriterios.value.data)) {
        setCriterios(resCriterios.value.data);
      }

      // Cargar notas (carga global)
      if (resNotas.status === "fulfilled" && Array.isArray(resNotas.value.data)) {
        setNotas(resNotas.value.data);
      }

      // Cargar auditoría
      if (resAuditoria.status === "fulfilled" && Array.isArray(resAuditoria.value.data)) {
        setAuditoria(resAuditoria.value.data);
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
            nota_final: row.nota_final !== null && row.nota_final !== undefined ? Number(row.nota_final) : null,
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

  // Deduplicación global de paralelos por (id_materia, id_paralelo, id_gestion)
  const paralelosDeduplicados = useMemo(() => {
    const mapa = new Map();
    (paralelos || []).forEach((p) => {
      const key = `${p.id_materia}-${p.id_paralelo}-${p.id_gestion || 1}`;
      if (!mapa.has(key)) mapa.set(key, p);
    });
    return Array.from(mapa.values());
  }, [paralelos]);

  // Derivación segura de estudiantes y docentes vinculando el RU real de la base de datos
  const estudiantesCalculados = useMemo(() => {
    const mapaEst = new Map();
    (estudiantes || []).forEach((e) => {
      if (e && e.id_persona) mapaEst.set(Number(e.id_persona), e);
    });

    const fuente = personas.length > 0 ? personas : usuarios;
    return fuente.map((p) => {
      const eMatch = mapaEst.get(Number(p.id_persona));
      return {
        id_persona: Number(p.id_persona),
        ru: eMatch?.ru || p.ru || `${1006000 + Number(p.id_persona)}`,
        id_plan: eMatch?.id_plan || p.id_plan || 1,
        anio_ingreso: eMatch?.anio_ingreso || p.anio_ingreso || 2021,
      };
    });
  }, [estudiantes, personas, usuarios]);

  const docentesCalculados = useMemo(() => {
    if (docentes.length > 0) return docentes;
    const fuente = personas.length > 0 ? personas : usuarios;
    return fuente.map((p) => ({
      id_persona: Number(p.id_persona),
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
    const fromP = personas.find((p) => Number(p.id_persona) === Number(id_persona));
    if (fromP && fromP.nombres) return fromP;
    const fromU = usuarios.find((u) => Number(u.id_persona) === Number(id_persona) || Number(u.id_usuario) === Number(id_persona));
    if (fromU) return {
      id_persona: fromU.id_persona || id_persona,
      nombres: fromU.nombres || fromU.username,
      apellidos: fromU.apellidos || "",
      ci: fromU.ci || "—",
      email: fromU.email || "—"
    };
    return { id_persona, nombres: "—", apellidos: "", ci: "—", email: "—" };
  };

  const getEstudiante = (id_persona) => {
    const est = (estudiantesCalculados || []).find((e) => Number(e.id_persona) === Number(id_persona));
    if (est && est.ru) return est;
    const persona = (personas || []).find((p) => Number(p.id_persona) === Number(id_persona));
    return {
      id_persona: Number(id_persona),
      ru: persona?.ru || `${1006000 + Number(id_persona)}`,
      id_plan: persona?.id_plan || 1,
      anio_ingreso: 2021
    };
  };

  const getGestionActiva = () => {
    const activas = (gestiones || []).filter((g) => g.estado === "Activa");
    if (activas.length > 0) {
      return activas.sort((a, b) => Number(b.id_gestion) - Number(a.id_gestion))[0];
    }
    return null;
  };

  const getDocenteNombre = (id_persona) => {
    if (!id_persona || Number(id_persona) === 0) return "Sin asignar";
    return fullName(getPersona(id_persona));
  };

  const getMateria = (id_materia) =>
    (materias || []).find((m) => Number(m.id_materia) === Number(id_materia)) || {
      id_materia,
      sigla: `MAT-${id_materia}`,
      nombre: `Materia ${id_materia}`,
      creditos: 5,
    };

  const getPensumPlan = (id_plan) =>
    (planMateria || [])
      .filter((pm) => Number(pm.id_plan) === Number(id_plan))
      .map((pm) => ({ ...pm, materia: getMateria(pm.id_materia) }))
      .filter((pm) => pm.materia)
      .sort((a, b) => a.semestre - b.semestre || a.materia.sigla.localeCompare(b.materia.sigla));

  const getPrerrequisitos = (id_plan, id_materia) =>
    [...new Set(
      (prerequisitos || [])
        .filter((p) => Number(p.id_materia) === Number(id_materia))
        .map((p) => Number(p.id_materia_req))
    )];

  const getHistorialEstudiante = (id_estudiante) => {
    const insEst = (inscripciones || []).filter((i) => Number(i.id_estudiante) === Number(id_estudiante));
    const idsIns = insEst.map((i) => i.id_inscripcion);
    const raw = (detalle || [])
      .filter((d) => idsIns.includes(d.id_inscripcion))
      .map((d) => {
        const ins = insEst.find((i) => i.id_inscripcion === d.id_inscripcion);
        const gestion = (gestiones || []).find((g) => Number(g.id_gestion) === Number(ins ? ins.id_gestion : 1)) || { id_gestion: 1, periodo: "I/2026" };
        return { ...d, gestion, materia: getMateria(d.id_materia) };
      })
      .filter((d) => d.gestion && d.materia);

    const mapaPorMateria = new Map();
    raw.forEach((item) => {
      const key = `${item.gestion.id_gestion}-${item.id_materia}`;
      const existente = mapaPorMateria.get(key);
      if (!existente) {
        mapaPorMateria.set(key, item);
      } else if (existente.estado === "Abandono" && item.estado !== "Abandono") {
        mapaPorMateria.set(key, item);
      }
    });

    return Array.from(mapaPorMateria.values()).sort((a, b) => a.gestion.periodo.localeCompare(b.gestion.periodo));
  };

  const getEstadoMateriaParaEstudiante = (id_estudiante, id_materia) => {
    const historial = getHistorialEstudiante(id_estudiante).filter((h) => Number(h.id_materia) === Number(id_materia));
    if (historial.some((h) => h.estado === "Aprobado")) return "aprobada";
    if (historial.some((h) => h.estado === "Inscrito")) return "cursando";
    if (historial.length && historial.every((h) => h.estado === "Reprobado")) return "reprobada";
    return "pendiente";
  };

  const getMateriasAprobadas = (id_estudiante) =>
    getHistorialEstudiante(id_estudiante)
      .filter((h) => h.estado === "Aprobado")
      .map((h) => Number(h.id_materia));

  const getParalelosOferta = (id_materia, id_gestion) => {
    const targetGestion = id_gestion || getGestionActiva()?.id_gestion;
    const directos = (paralelos || []).filter(
      (p) => Number(p.id_materia) === Number(id_materia) && Number(p.id_gestion) === Number(targetGestion)
    );
    const lista = directos.length > 0 ? directos : (paralelos || []).filter((p) => Number(p.id_materia) === Number(id_materia));

    return lista.map((p) => {
      // Contar inscripciones reales activas en memoria para evitar desajustes de la columna cupo_actual
      const inscritosReales = (detalle || []).filter((d) => {
        if (Number(d.id_materia) !== Number(id_materia) || Number(d.id_paralelo) !== Number(p.id_paralelo)) return false;
        if (d.estado === "Abandono" || d.estado === "Retirado") return false;
        const ins = (inscripciones || []).find((i) => Number(i.id_inscripcion) === Number(d.id_inscripcion));
        return !targetGestion || (ins && Number(ins.id_gestion) === Number(targetGestion));
      });

      const mapaEstudiantes = new Map();
      inscritosReales.forEach((d) => {
        const ins = (inscripciones || []).find((i) => Number(i.id_inscripcion) === Number(d.id_inscripcion));
        if (ins?.id_estudiante) mapaEstudiantes.set(Number(ins.id_estudiante), true);
      });

      const numInscritos = Math.max(Number(p.cupo_actual || 0), mapaEstudiantes.size);
      const maximo = Number(p.cupo_maximo || 40);
      const disponibles = Math.max(0, maximo - numInscritos);

      return {
        ...p,
        cupo_actual: numInscritos,
        cupo_maximo: maximo,
        cupo_disponible: disponibles,
        docenteNombre: getDocenteNombre(p.id_docente),
        horario: (seCursa || []).find((s) => Number(s.id_materia) === Number(id_materia) && Number(s.id_paralelo) === Number(p.id_paralelo)),
      };
    });
  };

  const puedeInscribirse = (id_estudiante, id_plan, id_materia) => {
    const pm = (planMateria || []).find(
      (p) => Number(p.id_materia) === Number(id_materia) && (Number(p.id_plan) === Number(id_plan) || !p.id_plan)
    );
    const semestreMateria = pm ? Number(pm.semestre) : 1;

    // 1. Verificar Prerrequisitos directos en la tabla prerequisito
    const requeridas = getPrerrequisitos(id_plan, id_materia);
    const aprobadas = getMateriasAprobadas(id_estudiante);
    const faltantes = requeridas.filter((r) => !aprobadas.includes(Number(r)));
    if (faltantes.length > 0) {
      const nombres = faltantes.map((id) => getMateria(id)?.sigla || `MAT-${id}`).join(", ");
      return { ok: false, motivo: `Debe aprobar primero el prerrequisito directo: ${nombres}` };
    }

    // 2. Regla de Nivel/Semestre: Un estudiante no puede tomar materias del semestre N si le faltan materias de semestres (N-2) o inferiores
    if (semestreMateria > 2) {
      const materiasObligatoriasPrevias = (planMateria || [])
        .filter((p) => (Number(p.id_plan) === Number(id_plan) || Number(p.id_plan) === 1) && Number(p.semestre) <= (semestreMateria - 2))
        .map((p) => Number(p.id_materia));

      const sinAprobarAnteriores = materiasObligatoriasPrevias.filter((id) => !aprobadas.includes(Number(id)));
      if (sinAprobarAnteriores.length > 0) {
        return {
          ok: false,
          motivo: `Bloqueado por avance de nivel: Para cursar materias de ${semestreMateria}º semestre debe aprobar primero las asignaturas de ${semestreMateria - 2}º semestre e inferiores.`
        };
      }
    }

    return { ok: true };
  };

  // ---------- Mutaciones asíncronas conectadas con la API REST de MySQL ----------

  const crearUsuario = async (personaNueva, idsRol) => {
    const res = await usersService.create({
      persona: personaNueva,
      nombres: personaNueva?.nombres,
      apellidos: personaNueva?.apellidos,
      ci: personaNueva?.ci,
      fecha_nac: personaNueva?.fecha_nac,
      sexo: personaNueva?.sexo,
      idsRol,
      id_rol: idsRol?.[0] || 1
    });
    await reloadFromBackend();
    return res.data;
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
    const res = await gradesService.crearCriterio({ id_materia, id_paralelo, nombre, ponderacion });
    const newId = res.data?.result?.insertId || res.data?.result?.id_criterio || Date.now();
    setCriterios((prev) => [...prev, { id_criterio: newId, id_materia, id_paralelo, nombre, ponderacion }]);
  };

  const actualizarCriterio = async (id_criterio, nombre, ponderacion) => {
    await gradesService.actualizarCriterio(id_criterio, { nombre, ponderacion });
    setCriterios((prev) =>
      prev.map((c) => (Number(c.id_criterio) === Number(id_criterio) ? { ...c, nombre, ponderacion } : c))
    );
  };

  const eliminarCriterio = async (id_criterio) => {
    await gradesService.eliminarCriterio(id_criterio);
    setCriterios((prev) => prev.filter((c) => Number(c.id_criterio) !== Number(id_criterio)));
  };

  const guardarNota = async (id_detalle, id_criterio, puntaje_obtenido) => {
    const valNum = Number(puntaje_obtenido);
    // Actualización optimista local de notas en memoria sin provocar spinner ni recarga
    setNotas((prev) => {
      const idx = prev.findIndex((n) => Number(n.id_detalle) === Number(id_detalle) && Number(n.id_criterio) === Number(id_criterio));
      if (idx >= 0) {
        const copy = [...prev];
        copy[idx] = { ...copy[idx], nota_obtenida: valNum, puntaje_obtenido: valNum };
        return copy;
      }
      return [...prev, { id_nota: Date.now(), id_detalle: Number(id_detalle), id_criterio: Number(id_criterio), nota_obtenida: valNum, puntaje_obtenido: valNum }];
    });

    try {
      await gradesService.guardarNota({ id_detalle: Number(id_detalle), id_criterio: Number(id_criterio), nota_obtenida: valNum, puntaje_obtenido: valNum });
    } catch (err) {
      console.error("Error al guardar nota en backend:", err.message);
    }
  };

  const calcularNotaFinal = (id_materia, id_paralelo, id_detalle) => {
    const crit = (criterios || []).filter(
      (c) => Number(c.id_materia) === Number(id_materia) && Number(c.id_paralelo) === Number(id_paralelo)
    );
    const totalSuma = crit.reduce((acc, c) => {
      const nota = (notas || []).find(
        (n) => Number(n.id_detalle) === Number(id_detalle) && Number(n.id_criterio) === Number(c.id_criterio)
      );
      const valor = nota ? Number(nota.nota_obtenida ?? nota.puntaje_obtenido ?? 0) : 0;
      return acc + (isNaN(valor) ? 0 : valor);
    }, 0);
    return Math.round(totalSuma * 100) / 100;
  };

  // Previsualización del cierre — llama a sp_preview_cierre_gestion vía API
  const previewCierreGestion = async (id_gestion) => {
    const res = await gestionCloseService.preview(id_gestion);
    return res.data; // { resumen: {...}, detalle: [...] }
  };

  // Cierre definitivo de gestión — llama a sp_cerrar_gestion vía API
  const cerrarGestion = async (id_gestion) => {
    const res = await gestionCloseService.cerrar(id_gestion);
    await reloadFromBackend();
    return res.data;
  };

  // Iniciar nueva gestión con paralelos automáticos
  const iniciarGestion = async (periodo) => {
    const res = await gestionCloseService.iniciar({ periodo });
    await reloadFromBackend();
    return res.data;
  };

  // Asignar docente a un paralelo
  const asignarDocenteParalelo = async (id_materia, id_paralelo, id_docente) => {
    const activeG = getGestionActiva();
    const res = await paraleloService.asignarDocente(id_materia, id_paralelo, id_docente, activeG?.id_gestion);
    await reloadFromBackend();
    return res.data;
  };

  // Desasignar docente de un paralelo
  const desasignarDocenteParalelo = async (id_materia, id_paralelo) => {
    const activeG = getGestionActiva();
    const res = await paraleloService.desasignarDocente(id_materia, id_paralelo, activeG?.id_gestion);
    await reloadFromBackend();
    return res.data;
  };

  const value = useMemo(
    () => ({
      carreras,
      planes,
      materias,
      roles: roles.length > 0 ? roles : [{ id_rol: 1, nombre: "Administrador" }, { id_rol: 2, nombre: "Director" }, { id_rol: 3, nombre: "Docente" }, { id_rol: 4, nombre: "Estudiante" }],
      aulas,
      horarios,
      seCursa,
      usuarios,
      tieneRol,
      personas,
      paralelos: paralelosDeduplicados,
      inscripciones,
      detalle,
      criterios,
      notas,
      gestiones,
      auditoria,
      idCarreraActiva,
      setIdCarreraActiva,
      getCarrera,
      getPlanesPorCarrera,
      estudiantes: estudiantesCalculados,
      docentes: docentesCalculados,
      loadingBackend,
      reloadFromBackend,
      getPersona,
      getEstudiante,
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
      actualizarCriterio,
      eliminarCriterio,
      guardarNota,
      calcularNotaFinal,
      previewCierreGestion,
      cerrarGestion,
      iniciarGestion,
      asignarDocenteParalelo,
      desasignarDocenteParalelo,
    }),
    [
      carreras,
      planes,
      materias,
      roles,
      usuarios,
      tieneRol,
      personas,
      paralelosDeduplicados,
      inscripciones,
      detalle,
      criterios,
      notas,
      gestiones,
      auditoria,
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
