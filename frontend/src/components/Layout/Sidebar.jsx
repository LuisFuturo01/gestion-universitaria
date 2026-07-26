import { NavLink } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";

const MENU = [
  { to: "/dashboard", icon: "🏠", label: "Inicio", roles: [] },
  { to: "/usuarios", icon: "👤", label: "Usuarios y Roles", roles: ["ADMIN", "DIRECTOR"] },
  { to: "/oferta-academica", icon: "📚", label: "Oferta Académica", roles: [] },
  { to: "/inscripcion", icon: "📝", label: "Inscripciones", roles: ["ADMIN", "DIRECTOR", "ESTUDIANTE"] },
  { to: "/notas", icon: "🧮", label: "Notas y Ponderaciones", roles: ["DOCENTE", "ESTUDIANTE", "ADMIN", "DIRECTOR"] },
  { to: "/historial", icon: "📖", label: "Historial Académico", roles: ["ADMIN", "DIRECTOR", "ESTUDIANTE"] },
  { to: "/reportes", icon: "📊", label: "Reportes y Estadísticas", roles: ["ADMIN", "DIRECTOR"] },
  { to: "/cierre-gestion", icon: "🏛️", label: "Apertura / Cierre de Gestión", roles: ["DIRECTOR", "ADMIN"] },
];

export default function Sidebar({ open, onClose }) {
  const { session } = useAuth();
  if (!session) return null;

  // Filtrado adaptativo estricto por el contexto activo (rolActivo)
  const visible = MENU.filter(
    (item) => item.roles.length === 0 || item.roles.includes(session.rolActivo)
  );

  return (
    <>
      <aside className={`sidebar ${open ? "sidebar-open" : ""}`}>
        <div className="sidebar-brand">
          <span className="sidebar-logo">UN</span>
          <div>
            <p className="sidebar-title">Sistema Académico</p>
            <p className="sidebar-subtitle">
              {session.rolActivo === "DIRECTOR" ? "Modo Director" : session.rolActivo === "DOCENTE" ? "Modo Docente" : "Universidad Nacional"}
            </p>
          </div>
        </div>

        <nav className="sidebar-nav">
          {visible.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => `sidebar-link ${isActive ? "active" : ""}`}
              onClick={onClose}
            >
              <span className="sidebar-icon" aria-hidden="true">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>
      {open && <div className="sidebar-backdrop" onClick={onClose} />}
    </>
  );
}
