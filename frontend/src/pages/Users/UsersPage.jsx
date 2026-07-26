import { useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { useToast } from "../../context/ToastContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { ROLE_KEYS } from "../../data/mockData";

const emptyForm = { username: "", password: "", nombres: "", apellidos: "", ci: "", email: "", fecha_nac: "", sexo: "M", idsRol: [] };

export default function UsersPage() {
  const { session } = useAuth();
  const data = useData();
  const { showSuccess, showError, showWarning } = useToast();
  const esAdmin = session?.rolActivo === "ADMIN";
  const esDirector = session?.rolActivo === "DIRECTOR";

  const [form, setForm] = useState(emptyForm);
  const [showForm, setShowForm] = useState(false);
  const [search, setSearch] = useState("");

  // Roles permitidos para creación según el perfil activo
  const rolesPermitidosParaCrear = data.roles.filter((r) => {
    if (esAdmin) return r.nombre === "Docente" || r.nombre === "Estudiante" || r.id_rol === 3 || r.id_rol === 4;
    if (esDirector) return r.nombre === "Administrador" || r.id_rol === 1;
    return false;
  });

  const filas = data.usuarios
    .map((u) => {
      const persona = data.getPersona(u.id_persona);
      const nombres = u.nombres || persona.nombres || "—";
      const apellidos = u.apellidos || persona.apellidos || "";
      const ci = u.ci || persona.ci || (persona.id_persona ? `100000${persona.id_persona}` : "—");
      const email = u.email || persona.email || "—";
      const rawRoles = u.roles || (u.id_rol ? [u.id_rol] : (u.rol ? [u.rol] : [1]));
      return {
        ...u,
        persona: { ...persona, nombres, apellidos, ci, email },
        roles: Array.isArray(rawRoles) ? rawRoles : [rawRoles]
      };
    })
    .filter((f) => {
      const q = search.toLowerCase();
      return !q || f.username.toLowerCase().includes(q) || `${f.persona.nombres} ${f.persona.apellidos}`.toLowerCase().includes(q);
    });

  const toggleRolForm = (id_rol) => {
    setForm((f) => ({
      ...f,
      idsRol: f.idsRol.includes(id_rol) ? f.idsRol.filter((r) => r !== id_rol) : [...f.idsRol, id_rol],
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.username || !form.password || form.idsRol.length === 0) {
      showWarning("Complete usuario, contraseña y al menos un rol permitido.");
      return;
    }

    data.crearUsuario(
      { username: form.username, password: form.password, activo: true },
      {
        nombres: form.nombres,
        apellidos: form.apellidos,
        ci: form.ci,
        email: form.email,
        fecha_nac: form.fecha_nac || "2000-01-01",
        sexo: form.sexo,
      },
      form.idsRol
    );
    showSuccess(`Usuario '${form.username}' registrado correctamente.`);
    setForm(emptyForm);
    setShowForm(false);
  };

  const handleToggleEstado = (usuarioTarget) => {
    const rolesTarget = usuarioTarget.roles.map((r) => (typeof r === "string" ? r.toUpperCase() : (ROLE_KEYS[r] || "").toUpperCase()));
    const targetEsDirector = rolesTarget.some((r) => r.includes("DIRECTOR")) || usuarioTarget.id_rol === 2;
    const targetEsAdmin = rolesTarget.some((r) => r.includes("ADMIN")) || usuarioTarget.id_rol === 1;

    // 1. Nadie puede modificar ni eliminar al Director de Carrera
    if (targetEsDirector) {
      showError("El perfil del Director de Carrera no puede ser modificado ni desactivado por ningún usuario.");
      return;
    }

    // 2. Un Administrativo NO puede modificar ni eliminar a otros Administradores
    if (esAdmin && targetEsAdmin) {
      showError("El personal Administrativo no tiene permisos para desactivar ni modificar a otros Administradores.");
      return;
    }

    // 3. El Director SÍ puede gestionar (desactivar/reactivar) cuentas de Administrativos
    if (esDirector && !targetEsAdmin) {
      showError("El Director de Carrera únicamente administra cuentas del personal Administrativo.");
      return;
    }

    // 4. El Administrativo solo maneja Docentes y Estudiantes
    if (esAdmin) {
      const esDocenteOEstudiante = rolesTarget.some((r) => r.includes("DOCENTE") || r.includes("ESTUDIANTE")) || usuarioTarget.id_rol === 3 || usuarioTarget.id_rol === 4;
      if (!esDocenteOEstudiante) {
        showError("El personal Administrativo únicamente puede gestionar cuentas de Docentes y Estudiantes.");
        return;
      }
    }

    data.toggleUsuarioActivo(usuarioTarget.id_usuario);
    const nuevoEstado = usuarioTarget.estado === "I" || usuarioTarget.activo === false ? "Activado" : "Desactivado";
    showSuccess(`Estado de '${usuarioTarget.username}' actualizado en la base de datos (${nuevoEstado}).`);
  };

  return (
    <div>
      <SectionHeader
        title="Gestión de Usuarios y Roles"
        subtitle={
          esAdmin
            ? "El Administrativo puede gestionar Docentes y Estudiantes (sin permisos sobre otros Admins o el Director)"
            : esDirector
            ? "El Director de Carrera gestiona las cuentas del personal Administrativo"
            : "Directorio de usuarios del sistema"
        }
        actions={
          <>
            <input
              className="search-input"
              placeholder="Buscar por nombre o usuario..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            {(esAdmin || esDirector) && (
              <button className="primary-button" onClick={() => setShowForm((v) => !v)}>
                {showForm ? "Cancelar" : "+ Nuevo usuario"}
              </button>
            )}
          </>
        }
      />

      {(esAdmin || esDirector) && showForm && (
        <form className="page-card form-grid" onSubmit={handleSubmit} style={{ marginBottom: 20 }}>
          <div className="field">
            <label>Usuario</label>
            <input value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} required />
          </div>
          <div className="field">
            <label>Contraseña</label>
            <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
          </div>
          <div className="field">
            <label>Nombres</label>
            <input value={form.nombres} onChange={(e) => setForm({ ...form, nombres: e.target.value })} required />
          </div>
          <div className="field">
            <label>Apellidos</label>
            <input value={form.apellidos} onChange={(e) => setForm({ ...form, apellidos: e.target.value })} required />
          </div>
          <div className="field">
            <label>Carnet de Identidad (CI)</label>
            <input value={form.ci} onChange={(e) => setForm({ ...form, ci: e.target.value })} required />
          </div>
          <div className="field">
            <label>Email</label>
            <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          </div>
          <div className="field">
            <label>Fecha de Nacimiento</label>
            <input type="date" value={form.fecha_nac} onChange={(e) => setForm({ ...form, fecha_nac: e.target.value })} />
          </div>
          <div className="field">
            <label>Sexo</label>
            <select value={form.sexo} onChange={(e) => setForm({ ...form, sexo: e.target.value })}>
              <option value="M">M</option>
              <option value="F">F</option>
            </select>
          </div>
          <div className="field field-wide">
            <label>Roles Permitidos para Asignar</label>
            <div className="checkbox-row">
              {rolesPermitidosParaCrear.map((r) => (
                <label key={r.id_rol} className="checkbox-chip">
                  <input
                    type="checkbox"
                    checked={form.idsRol.includes(r.id_rol)}
                    onChange={() => toggleRolForm(r.id_rol)}
                  />
                  {r.nombre}
                </label>
              ))}
            </div>
          </div>
          <button type="submit" className="primary-button field-wide">Guardar Usuario</button>
        </form>
      )}

      <div className="page-card">
        {filas.length === 0 ? (
          <EmptyState text="No se encontraron usuarios en el directorio." />
        ) : (
          <table className="table">
            <thead>
              <tr>
                <th>Usuario</th>
                <th>Nombre Completo</th>
                <th>CI</th>
                <th>Email</th>
                <th>Roles</th>
                <th>Estado BD</th>
                <th>Acciones / Permisos</th>
              </tr>
            </thead>
            <tbody>
              {filas.map((f) => {
                const targetEsDirector = f.roles.some((r) => String(r).toUpperCase().includes("DIRECTOR")) || f.id_rol === 2;
                const targetEsAdmin = f.roles.some((r) => String(r).toUpperCase().includes("ADMIN")) || f.id_rol === 1;
                const esInactivo = f.estado === "I" || f.activo === false;

                const sePuedeModificar =
                  !targetEsDirector &&
                  ((esAdmin && !targetEsAdmin) || (esDirector && targetEsAdmin));

                return (
                  <tr key={f.id_usuario}>
                    <td>{f.username}</td>
                    <td>{f.persona.nombres} {f.persona.apellidos}</td>
                    <td><strong>{f.persona.ci}</strong></td>
                    <td>{f.persona.email}</td>
                    <td>
                      {f.roles.map((idr, idx) => (
                        <span key={idx} className="role-tag">
                          {typeof idr === "number" ? (ROLE_KEYS[idr] || `ROL-${idr}`) : String(idr)}
                        </span>
                      ))}
                    </td>
                    <td>
                      <Badge tone={esInactivo ? "red" : "green"}>
                        {esInactivo ? "Inactivo (I)" : "Activo (A)"}
                      </Badge>
                    </td>
                    <td>
                      {targetEsDirector ? (
                        <span style={{ fontSize: "0.78rem", color: "#62728a", fontWeight: 600 }}>🔒 Director Inalterable</span>
                      ) : sePuedeModificar ? (
                        <button className="link-button" onClick={() => handleToggleEstado(f)}>
                          {esInactivo ? "Reactivar (A)" : "Desactivar (I)"}
                        </button>
                      ) : (
                        <span style={{ fontSize: "0.78rem", color: "#9aa5b5" }}>Sin permisos</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
