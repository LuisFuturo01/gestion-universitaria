import { useState } from "react";
import { useNavigate, Navigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";

const DEMO_USERS = [
  { rol: "Administrador", usuario: "admin", clave: "admin123" },
  { rol: "Director de Carrera", usuario: "director", clave: "director123" },
  { rol: "Docente", usuario: "docente", clave: "docente123" },
  { rol: "Estudiante", usuario: "estudiante", clave: "estudiante123" },
];

export default function LoginPage() {
  const { login, session } = useAuth();
  const navigate = useNavigate();
  const [formData, setFormData] = useState({ username: "", password: "" });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  if (session) return <Navigate to="/dashboard" replace />;

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    // Simula latencia de red para que se sienta como una llamada real al backend
    setTimeout(() => {
      const result = login(formData.username, formData.password);
      setLoading(false);
      if (!result.ok) {
        setError(result.mensaje);
        return;
      }
      navigate("/dashboard", { replace: true });
    }, 300);
  };

  const fillDemo = (usuario, clave) => {
    setFormData({ username: usuario, password: clave });
    setError("");
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-header">
          <span className="login-badge">UN</span>
          <h2>Iniciar sesión</h2>
          <p className="login-subtitle">Sistema Académico Universitario</p>
        </div>

        <form className="login-form" onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="username">Usuario</label>
            <input
              id="username"
              type="text"
              name="username"
              value={formData.username}
              onChange={handleChange}
              placeholder="Ingrese su usuario"
              autoComplete="username"
              required
            />
          </div>

          <div className="field">
            <label htmlFor="password">Contraseña</label>
            <input
              id="password"
              type="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              placeholder="Ingrese su contraseña"
              autoComplete="current-password"
              required
            />
          </div>

          {error && <p className="form-error" role="alert">{error}</p>}

          <button type="submit" className="primary-button" disabled={loading}>
            {loading ? "Ingresando..." : "Ingresar"}
          </button>
        </form>

        <div className="demo-users">
          <p className="demo-title">Usuarios de prueba (clic para autocompletar)</p>
          <div className="demo-grid">
            {DEMO_USERS.map((u) => (
              <button
                type="button"
                key={u.usuario}
                className="demo-chip"
                onClick={() => fillDemo(u.usuario, u.clave)}
              >
                <strong>{u.rol}</strong>
                <span>{u.usuario} / {u.clave}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
