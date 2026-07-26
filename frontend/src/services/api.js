import axios from "axios";

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:3001/api",
  timeout: 10000,
});

// Adjunta el token JWT guardado en sessionStorage a cada request
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
  login: (payload) => apiClient.post("/login", payload),
};

export const usersService = {
  list: () => apiClient.get("/usuarios"),
  create: (payload) => apiClient.post("/usuarios", payload),
  update: (id_usuario, payload) => apiClient.patch(`/usuarios/${id_usuario}`, payload),
  delete: (id_usuario) => apiClient.delete(`/usuarios/${id_usuario}`),
};

export const catalogService = {
  carreras: () => apiClient.get("/carreras"),
  planes: () => apiClient.get("/planes"),
  materias: () => apiClient.get("/materias"),
  planMaterias: (id_plan) => apiClient.get(id_plan ? `/plan-materias/${id_plan}` : "/plan-materias"),
  prerequisitos: (id_plan, id_materia) => apiClient.get(id_plan && id_materia ? `/prerequisitos/${id_plan}/${id_materia}` : "/prerequisitos"),
  paralelos: () => apiClient.get("/paralelos"),
  aulas: () => apiClient.get("/aulas"),
  horarios: () => apiClient.get("/horarios"),
  gestiones: () => apiClient.get("/gestiones"),
  seCursa: () => apiClient.get("/secursa"),
  roles: () => apiClient.get("/roles"),
  actores: () => apiClient.get("/actores"),
  estudiantes: () => apiClient.get("/actores/estudiantes"),
  docentes: () => apiClient.get("/actores/docentes"),
};

export const enrollmentService = {
  listar: () => apiClient.get("/inscripciones"),
  obtenerPorId: (id) => apiClient.get(`/inscripciones/${id}`),
  inscribir: (payload) => apiClient.post("/inscripciones", payload),
  retirar: (id_detalle) => apiClient.patch(`/inscripciones/retirar/${id_detalle}`),
  asignarNota: (payload) => apiClient.post("/inscripciones/nota", payload),
};

export const gradesService = {
  criterios: (id_materia, id_paralelo) => apiClient.get(`/criterios/${id_materia}/${id_paralelo}`),
  todosCriterios: () => apiClient.get("/criterios"),
  crearCriterio: (payload) => apiClient.post("/criterios", payload),
  actualizarCriterio: (id_criterio, payload) => apiClient.put(`/criterios/${id_criterio}`, payload),
  eliminarCriterio: (id_criterio) => apiClient.delete(`/criterios/${id_criterio}`),
  guardarNota: (payload) => apiClient.post("/notas", payload),
  notasPorDetalle: (id_detalle) => apiClient.get(`/notas/${id_detalle}`),
  todasNotas: () => apiClient.get("/notas"),
};

export const gestionCloseService = {
  preview: (id_gestion) => apiClient.get(`/gestiones/${id_gestion}/preview-cierre`),
  cerrar: (id_gestion) => apiClient.post(`/gestiones/${id_gestion}/cerrar`),
  auditoria: () => apiClient.get("/gestiones/auditoria"),
};
