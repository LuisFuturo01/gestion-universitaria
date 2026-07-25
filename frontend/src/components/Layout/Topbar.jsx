import { useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";

const ROLE_LABEL = {
  ADMIN: "Administrador",
  DIRECTOR: "Director de Carrera",
  DOCENTE: "Docente",
  ESTUDIANTE: "Estudiante",
};

export default function Topbar({ onToggleSidebar }) {
  const { session, logout, setRolActivo } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login", { replace: true });
  };

  return (
    <header className="topbar">
      <div className="topbar-left">
        <button className="hamburger" onClick={onToggleSidebar} aria-label="Abrir menú">
          ☰
        </button>
        <div>
          <p className="eyebrow">Panel de gestión</p>
          <h1>{ROLE_LABEL[session?.rolActivo] || "Sistema Académico"}</h1>
        </div>
      </div>

      <div className="topbar-right">
        {session?.roles.length > 1 && (
          <select
            className="role-switch"
            value={session.rolActivo}
            onChange={(e) => setRolActivo(e.target.value)}
            aria-label="Cambiar rol activo"
          >
            {session.roles.map((r) => (
              <option key={r} value={r}>
                {ROLE_LABEL[r]}
              </option>
            ))}
          </select>
        )}
        <div className="user-chip">
          <span className="user-avatar">{session?.nombreCompleto?.charAt(0)}</span>
          <div className="user-meta">
            <strong>{session?.nombreCompleto}</strong>
            <span>{ROLE_LABEL[session?.rolActivo]}</span>
          </div>
        </div>
        <button className="logout-button" onClick={handleLogout}>
          Salir
        </button>
      </div>
    </header>
  );
}
