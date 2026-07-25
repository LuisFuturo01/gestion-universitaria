import { useState } from "react";
import { useData } from "../../context/DataContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { ROLE_KEYS } from "../../data/mockData";

const emptyForm = { username: "", password: "", nombres: "", apellidos: "", ci: "", email: "", fecha_nac: "", sexo: "M", idsRol: [] };

export default function UsersPage() {
  const data = useData();
  const [form, setForm] = useState(emptyForm);
  const [showForm, setShowForm] = useState(false);
  const [search, setSearch] = useState("");

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
      alert("Complete usuario, contraseña y al menos un rol.");
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
    setForm(emptyForm);
    setShowForm(false);
  };

  return (
    <div>
      <SectionHeader
        title="Gestión de Usuarios y Roles"
        subtitle="Alta de usuarios, asignación de roles y estado de cuentas"
        actions={
          <>
            <input
              className="search-input"
              placeholder="Buscar por nombre o usuario..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            <button className="primary-button" onClick={() => setShowForm((v) => !v)}>
              {showForm ? "Cancelar" : "+ Nuevo usuario"}
            </button>
          </>
        }
      />

      {showForm && (
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
            <label>Carnet de identidad (CI)</label>
            <input value={form.ci} onChange={(e) => setForm({ ...form, ci: e.target.value })} required />
          </div>
          <div className="field">
            <label>Email</label>
            <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          </div>
          <div className="field">
            <label>Fecha de nacimiento</label>
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
            <label>Roles</label>
            <div className="checkbox-row">
              {data.roles.map((r) => (
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
          <button type="submit" className="primary-button field-wide">Guardar usuario</button>
        </form>
      )}

      <div className="page-card">
        {filas.length === 0 ? (
          <EmptyState text="No se encontraron usuarios." />
        ) : (
          <table className="table">
            <thead>
              <tr>
                <th>Usuario</th>
                <th>Nombre completo</th>
                <th>CI</th>
                <th>Email</th>
                <th>Roles</th>
                <th>Estado</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filas.map((f) => (
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
                  <td><Badge>{f.estado === "I" || f.activo === false ? "Inactivo" : "Activo"}</Badge></td>
                  <td>
                    <button className="link-button" onClick={() => data.toggleUsuarioActivo(f.id_usuario)}>
                      {f.estado === "I" || f.activo === false ? "Reactivar" : "Desactivar"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
