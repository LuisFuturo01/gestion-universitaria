// =========================================================
// DATOS MOCK — reflejan 1:1 las tablas del DDL (DDL-proy-v1.sql)
// Esto simula lo que vendría del backend mientras no está listo.
// Cuando el backend exista, este archivo se reemplaza por
// llamadas reales en src/services/api.js (ver services/*.js)
// =========================================================

// ---------- ROL ----------
export const ROLES = [
  { id_rol: 1, nombre: "Administrador" },
  { id_rol: 2, nombre: "Director" },
  { id_rol: 3, nombre: "Docente" },
  { id_rol: 4, nombre: "Estudiante" },
];

// ---------- PERSONA ----------
export const PERSONAS = [
  { id_persona: 1, ci: "1111111", nombres: "Ana", apellidos: "Mamani Quispe", fecha_nac: "1985-02-10", sexo: "F", email: "ana.admin@uni.edu.bo" },
  { id_persona: 2, ci: "2222222", nombres: "Rodrigo", apellidos: "Fernández Loza", fecha_nac: "1978-06-22", sexo: "M", email: "rodrigo.director@uni.edu.bo" },
  { id_persona: 3, ci: "3333333", nombres: "María", apellidos: "Gómez Vargas", fecha_nac: "1982-11-03", sexo: "F", email: "maria.docente@uni.edu.bo" },
  { id_persona: 4, ci: "4444444", nombres: "Carlos", apellidos: "Ruiz Salazar", fecha_nac: "1980-04-17", sexo: "M", email: "carlos.docente@uni.edu.bo" },
  { id_persona: 5, ci: "1234567", nombres: "Juan", apellidos: "Pérez Ramos", fecha_nac: "2003-05-14", sexo: "M", email: "juan.perez@uni.edu.bo" },
  { id_persona: 6, ci: "5555555", nombres: "Lucía", apellidos: "Torrez Choque", fecha_nac: "2002-09-30", sexo: "F", email: "lucia.torrez@uni.edu.bo" },
  { id_persona: 7, ci: "6666666", nombres: "Diego", apellidos: "Alanoca Yujra", fecha_nac: "2003-01-25", sexo: "M", email: "diego.alanoca@uni.edu.bo" },
];

export const fullName = (p) => (p ? `${p.nombres} ${p.apellidos}` : "—");

// ---------- USUARIO (contraseñas en claro solo para el mock) ----------
export const USUARIOS = [
  { id_usuario: 1, username: "admin", password: "admin123", id_persona: 1 },
  { id_usuario: 2, username: "director", password: "director123", id_persona: 2 },
  { id_usuario: 3, username: "docente", password: "docente123", id_persona: 3 },
  { id_usuario: 4, username: "docente2", password: "docente123", id_persona: 4 },
  { id_usuario: 5, username: "estudiante", password: "estudiante123", id_persona: 5 },
  { id_usuario: 6, username: "estudiante2", password: "estudiante123", id_persona: 6 },
  { id_usuario: 7, username: "estudiante3", password: "estudiante123", id_persona: 7 },
];

// ---------- TIENE_ROL ----------
export const TIENE_ROL = [
  { id_usuario: 1, id_rol: 1 }, // admin
  { id_usuario: 2, id_rol: 2 }, // director
  { id_usuario: 2, id_rol: 3 }, // el director también es docente (caso real común)
  { id_usuario: 3, id_rol: 3 }, // docente
  { id_usuario: 4, id_rol: 3 }, // docente2
  { id_usuario: 5, id_rol: 4 }, // estudiante
  { id_usuario: 6, id_rol: 4 },
  { id_usuario: 7, id_rol: 4 },
];

export const ROLE_KEYS = {
  1: "ADMIN",
  2: "DIRECTOR",
  3: "DOCENTE",
  4: "ESTUDIANTE",
};

// ---------- CARRERA (mención) ----------
export const CARRERAS = [
  { id_carrera: 1, nombre: "Ingeniería de Sistemas" },
  { id_carrera: 2, nombre: "Ingeniería Informática" },
];

// ---------- PLAN_ESTUDIO ----------
export const PLANES_ESTUDIO = [
  { id_plan: 1, nombre: "Plan 2022", id_carrera: 1 },
  { id_plan: 2, nombre: "Plan 2022", id_carrera: 2 },
];

// ---------- DOCENTE ----------
export const DOCENTES = [
  { id_persona: 2, registro_docente: "DOC-001", grado_academico: "Ph.D." },
  { id_persona: 3, registro_docente: "DOC-002", grado_academico: "M.Sc." },
  { id_persona: 4, registro_docente: "DOC-003", grado_academico: "Lic." },
];

// ---------- ADMINISTRATIVO ----------
export const ADMINISTRATIVOS = [
  { id_persona: 1, item: "ADM-001" },
];

// ---------- DIRECTOR_CARRERA ----------
export const DIRECTORES_CARRERA = [{ id_persona: 2 }];
export const DIRECTOR_CARRERA_ASIGNACION = [
  { id_persona: 2, id_carrera: 1, gestion: "2024-2027" },
];

// ---------- ESTUDIANTE ----------
export const ESTUDIANTES = [
  { id_persona: 5, ru: "20210458", id_plan: 1, anio_ingreso: 2021 },
  { id_persona: 6, ru: "20220112", id_plan: 1, anio_ingreso: 2022 },
  { id_persona: 7, ru: "20230087", id_plan: 2, anio_ingreso: 2023 },
];

// ---------- MATERIA ----------
export const MATERIAS = [
  { id_materia: 1, sigla: "INF-101", nombre: "Introducción a la Programación", creditos: 5 },
  { id_materia: 2, sigla: "MAT-101", nombre: "Cálculo I", creditos: 5 },
  { id_materia: 3, sigla: "INF-102", nombre: "Programación Orientada a Objetos", creditos: 5 },
  { id_materia: 4, sigla: "MAT-102", nombre: "Cálculo II", creditos: 5 },
  { id_materia: 5, sigla: "INF-151", nombre: "Estructuras de Datos", creditos: 5 },
  { id_materia: 6, sigla: "INF-161", nombre: "Diseño y Administración de Bases de Datos", creditos: 5 },
  { id_materia: 7, sigla: "INF-211", nombre: "Programación Web", creditos: 5 },
  { id_materia: 8, sigla: "INF-221", nombre: "Sistemas Operativos", creditos: 4 },
  { id_materia: 9, sigla: "INF-311", nombre: "Ingeniería de Software I", creditos: 5 },
];

// ---------- PLAN_MATERIA (pensum: qué materia va en qué semestre de cada plan) ----------
export const PLAN_MATERIA = [
  { id_plan: 1, id_materia: 1, semestre: 1 },
  { id_plan: 1, id_materia: 2, semestre: 1 },
  { id_plan: 1, id_materia: 3, semestre: 2 },
  { id_plan: 1, id_materia: 4, semestre: 2 },
  { id_plan: 1, id_materia: 5, semestre: 3 },
  { id_plan: 1, id_materia: 6, semestre: 3 },
  { id_plan: 1, id_materia: 7, semestre: 4 },
  { id_plan: 1, id_materia: 8, semestre: 4 },
  { id_plan: 1, id_materia: 9, semestre: 5 },
  // Plan 2 (Ing. Informática) reutiliza algunas materias
  { id_plan: 2, id_materia: 1, semestre: 1 },
  { id_plan: 2, id_materia: 2, semestre: 1 },
  { id_plan: 2, id_materia: 3, semestre: 2 },
  { id_plan: 2, id_materia: 6, semestre: 2 },
  { id_plan: 2, id_materia: 7, semestre: 3 },
];

// ---------- PREREQUISITO ----------
export const PREREQUISITOS = [
  { id_plan: 1, id_materia: 3, id_materia_req: 1 }, // POO requiere Introducción a la Programación
  { id_plan: 1, id_materia: 4, id_materia_req: 2 }, // Cálculo II requiere Cálculo I
  { id_plan: 1, id_materia: 5, id_materia_req: 3 }, // Estructuras de Datos requiere POO
  { id_plan: 1, id_materia: 6, id_materia_req: 3 }, // BD requiere POO
  { id_plan: 1, id_materia: 7, id_materia_req: 6 }, // Prog. Web requiere BD
  { id_plan: 1, id_materia: 7, id_materia_req: 5 }, // Prog. Web requiere Estructuras de Datos
  { id_plan: 1, id_materia: 9, id_materia_req: 7 }, // Ing. Software I requiere Prog. Web
  { id_plan: 2, id_materia: 3, id_materia_req: 1 },
  { id_plan: 2, id_materia: 6, id_materia_req: 3 },
  { id_plan: 2, id_materia: 7, id_materia_req: 6 },
];

// ---------- GESTION ----------
export const GESTIONES = [
  { id_gestion: 1, periodo: "I/2025", estado: "Cerrada" },
  { id_gestion: 2, periodo: "II/2025", estado: "Cerrada" },
  { id_gestion: 3, periodo: "I/2026", estado: "Activa" },
];

// ---------- AULA ----------
export const AULAS = [
  { id_aula: 1, nombre: "Aula 101", ubicacion: "Piso 1, Edificio Central", capacidad: 40 },
  { id_aula: 2, nombre: "Lab A", ubicacion: "Piso 2, Edificio Nuevo", capacidad: 25 },
];

// ---------- HORARIO ----------
export const HORARIOS = [
  { id_horario: 1, dia: "Lunes", hora_inicio: "08:00", hora_fin: "10:00" },
  { id_horario: 2, dia: "Miércoles", hora_inicio: "10:00", hora_fin: "12:00" },
  { id_horario: 3, dia: "Martes", hora_inicio: "14:00", hora_fin: "16:00" },
];

// ---------- PARALELO (gestión activa I/2026 = id_gestion 3, más histórico) ----------
export const PARALELOS = [
  { id_materia: 1, id_paralelo: 1, nombre: "A", cupo_maximo: 30, cupo_actual: 30, id_docente: 3, id_gestion: 1 },
  { id_materia: 2, id_paralelo: 1, nombre: "A", cupo_maximo: 30, cupo_actual: 30, id_docente: 4, id_gestion: 1 },
  { id_materia: 3, id_paralelo: 1, nombre: "A", cupo_maximo: 30, cupo_actual: 28, id_docente: 3, id_gestion: 2 },
  { id_materia: 6, id_paralelo: 1, nombre: "A", cupo_maximo: 25, cupo_actual: 25, id_docente: 2, id_gestion: 2 },
  // Gestión activa
  { id_materia: 5, id_paralelo: 1, nombre: "A", cupo_maximo: 30, cupo_actual: 18, id_docente: 3, id_gestion: 3 },
  { id_materia: 6, id_paralelo: 2, nombre: "B", cupo_maximo: 25, cupo_actual: 20, id_docente: 2, id_gestion: 3 },
  { id_materia: 7, id_paralelo: 1, nombre: "A", cupo_maximo: 25, cupo_actual: 25, id_docente: 4, id_gestion: 3 },
  { id_materia: 4, id_paralelo: 1, nombre: "A", cupo_maximo: 30, cupo_actual: 10, id_docente: 4, id_gestion: 3 },
  { id_materia: 1, id_paralelo: 2, nombre: "B", cupo_maximo: 30, cupo_actual: 12, id_docente: 3, id_gestion: 3 },
];

export const paraleloKey = (id_materia, id_paralelo) => `${id_materia}-${id_paralelo}`;

// ---------- SE_CURSA ----------
export const SE_CURSA = [
  { id_materia: 5, id_paralelo: 1, id_aula: 1, id_horario: 1 },
  { id_materia: 6, id_paralelo: 2, id_aula: 2, id_horario: 2 },
  { id_materia: 7, id_paralelo: 1, id_aula: 2, id_horario: 3 },
];

// ---------- INSCRIPCION (cabecera por estudiante y gestión) ----------
export const INSCRIPCIONES = [
  { id_inscripcion: 1, id_estudiante: 5, id_gestion: 1, fecha_registro: "2025-02-03" },
  { id_inscripcion: 2, id_estudiante: 5, id_gestion: 2, fecha_registro: "2025-07-10" },
  { id_inscripcion: 3, id_estudiante: 5, id_gestion: 3, fecha_registro: "2026-02-02" },
  { id_inscripcion: 4, id_estudiante: 6, id_gestion: 3, fecha_registro: "2026-02-03" },
];

// ---------- DETALLE_INSCRIPCION ----------
export const DETALLE_INSCRIPCION = [
  // Juan Pérez (id_persona 5) — histórico
  { id_detalle: 1, id_inscripcion: 1, id_materia: 1, id_paralelo: 1, estado: "Aprobado", nota_final: 78 },
  { id_detalle: 2, id_inscripcion: 1, id_materia: 2, id_paralelo: 1, estado: "Aprobado", nota_final: 65 },
  { id_detalle: 3, id_inscripcion: 2, id_materia: 3, id_paralelo: 1, estado: "Reprobado", nota_final: 40 },
  { id_detalle: 4, id_inscripcion: 2, id_materia: 6, id_paralelo: 1, estado: "Aprobado", nota_final: 82 },
  // gestión activa
  { id_detalle: 5, id_inscripcion: 3, id_materia: 6, id_paralelo: 2, estado: "Inscrito", nota_final: 0 },
  // Lucía Torrez
  { id_detalle: 6, id_inscripcion: 4, id_materia: 5, id_paralelo: 1, estado: "Inscrito", nota_final: 0 },
];

// ---------- CRITERIO_EVALUACION (ponderaciones que define el docente) ----------
export const CRITERIOS_EVALUACION = [
  { id_criterio: 1, id_materia: 6, id_paralelo: 2, nombre: "1er Parcial", ponderacion: 30 },
  { id_criterio: 2, id_materia: 6, id_paralelo: 2, nombre: "2do Parcial", ponderacion: 30 },
  { id_criterio: 3, id_materia: 6, id_paralelo: 2, nombre: "Proyecto Final", ponderacion: 25 },
  { id_criterio: 4, id_materia: 6, id_paralelo: 2, nombre: "Auxiliatura", ponderacion: 15 },
  { id_criterio: 5, id_materia: 5, id_paralelo: 1, nombre: "1er Parcial", ponderacion: 35 },
  { id_criterio: 6, id_materia: 5, id_paralelo: 1, nombre: "2do Parcial", ponderacion: 35 },
  { id_criterio: 7, id_materia: 5, id_paralelo: 1, nombre: "Prácticas", ponderacion: 30 },
];

// ---------- NOTA ----------
export const NOTAS = [
  { id_nota: 1, id_detalle: 5, id_criterio: 1, puntaje_obtenido: 25 },
  { id_nota: 2, id_detalle: 5, id_criterio: 2, puntaje_obtenido: 22 },
  { id_nota: 3, id_detalle: 6, id_criterio: 5, puntaje_obtenido: 28 },
];

// ---------- LOG_ACCESO ----------
export const LOG_ACCESO = [];

export const NOTA_APROBACION = 51; // umbral de aprobación sobre 100

export const cloneDB = () => ({
  usuarios: [...USUARIOS],
  tieneRol: [...TIENE_ROL],
  personas: [...PERSONAS],
  estudiantes: [...ESTUDIANTES],
  docentes: [...DOCENTES],
  paralelos: [...PARALELOS],
  inscripciones: [...INSCRIPCIONES],
  detalle: [...DETALLE_INSCRIPCION],
  criterios: [...CRITERIOS_EVALUACION],
  notas: [...NOTAS],
  gestiones: [...GESTIONES],
});
