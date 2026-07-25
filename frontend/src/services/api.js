import axios from "axios";

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:3000/api",
  timeout: 10000,
});

// Adjunta el token JWT guardado en sessionStorage a cada request (cuando exista backend real)
apiClient.interceptors.request.use((config) => {
  const raw = sessionStorage.getItem("sau_session");
  if (raw) {
    try {
      const { token } = JSON.parse(raw);
      if (token) config.headers.Authorization = `Bearer ${token}`;
    } catch {
      /* noop */
    }
  }
  return config;
});

export const authService = {
  login: (payload) => apiClient.post("/auth/login", payload),
  logout: () => apiClient.post("/auth/logout"),
};

export const usersService = {
  list: () => apiClient.get("/usuarios"),
  create: (payload) => apiClient.post("/usuarios", payload),
  toggleActivo: (id_usuario) => apiClient.patch(`/usuarios/${id_usuario}/estado`),
};

export const academicOfferService = {
  pensum: (id_carrera, id_gestion) => apiClient.get(`/oferta-academica/${id_carrera}`, { params: { id_gestion } }),
  paralelos: (id_materia, id_gestion) => apiClient.get(`/materias/${id_materia}/paralelos`, { params: { id_gestion } }),
};

export const enrollmentService = {
  misInscripciones: (id_gestion) => apiClient.get("/inscripciones/mias", { params: { id_gestion } }),
  inscribir: (payload) => apiClient.post("/inscripciones", payload),
  retirar: (id_detalle) => apiClient.delete(`/inscripciones/detalle/${id_detalle}`),
  listarPorGestion: (id_gestion) => apiClient.get("/inscripciones", { params: { id_gestion } }),
  actualizarEstado: (id_detalle, payload) => apiClient.patch(`/inscripciones/detalle/${id_detalle}`, payload),
};

export const gradesService = {
  criterios: (id_materia, id_paralelo) => apiClient.get(`/paralelos/${id_materia}/${id_paralelo}/criterios`),
  crearCriterio: (id_materia, id_paralelo, payload) => apiClient.post(`/paralelos/${id_materia}/${id_paralelo}/criterios`, payload),
  eliminarCriterio: (id_criterio) => apiClient.delete(`/criterios/${id_criterio}`),
  guardarNota: (payload) => apiClient.post("/notas", payload),
  misNotas: () => apiClient.get("/notas/mias"),
};

export const historyService = {
  historialEstudiante: (id_estudiante) => apiClient.get(`/estudiantes/${id_estudiante}/historial`),
};

export const reportsService = {
  estudiantesPorCarrera: (id_carrera) => apiClient.get(`/reportes/estudiantes-por-carrera/${id_carrera}`),
  cargaDocente: (id_gestion) => apiClient.get("/reportes/carga-docente", { params: { id_gestion } }),
  rendimientoAcademico: () => apiClient.get("/reportes/rendimiento-academico"),
};

export const gestionService = {
  activa: () => apiClient.get("/gestiones/activa"),
  previsualizarCierre: (id_gestion) => apiClient.get(`/gestiones/${id_gestion}/cierre/preview`),
  cerrar: (id_gestion) => apiClient.post(`/gestiones/${id_gestion}/cierre`),
};
