// =========================================================
// CONSTANTES Y HELPERS DE LA APLICACIÓN
// (Todos los datos se obtienen en tiempo real desde el backend MySQL)
// =========================================================

export const ROLE_KEYS = {
  1: "ADMIN",
  2: "DIRECTOR",
  3: "DOCENTE",
  4: "ESTUDIANTE",
};

export const NOTA_APROBACION = 51; // Umbral de aprobación sobre 100

export const fullName = (p) => (p && p.nombres ? `${p.nombres} ${p.apellidos}` : "—");

export const paraleloKey = (id_materia, id_paralelo) => `${id_materia}-${id_paralelo}`;

// Estructuras iniciales vacías para compatibilidad (los datos se cargan dinámicamente desde MySQL)
export const ROLES = [];
export const PERSONAS = [];
export const USUARIOS = [];
export const TIENE_ROL = [];
export const CARRERAS = [];
export const PLANES_ESTUDIO = [];
export const DOCENTES = [];
export const ADMINISTRATIVOS = [];
export const DIRECTORES_CARRERA = [];
export const DIRECTOR_CARRERA_ASIGNACION = [];
export const ESTUDIANTES = [];
export const MATERIAS = [];
export const PLAN_MATERIA = [];
export const PREREQUISITOS = [];
export const GESTIONES = [];
export const AULAS = [];
export const HORARIOS = [];
export const PARALELOS = [];
export const SE_CURSA = [];
export const INSCRIPCIONES = [];
export const DETALLE_INSCRIPCION = [];
export const CRITERIOS_EVALUACION = [];
export const NOTAS = [];
export const LOG_ACCESO = [];

export const cloneDB = () => ({
  usuarios: [],
  tieneRol: [],
  personas: [],
  estudiantes: [],
  docentes: [],
  paralelos: [],
  inscripciones: [],
  detalle: [],
  criterios: [],
  notas: [],
  gestiones: [],
});
