import { createContext, useContext, useEffect, useState } from "react";
import { authService } from "../services/api";

const AuthContext = createContext(null);
const STORAGE_KEY = "sau_session";

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (raw) {
      try {
        setSession(JSON.parse(raw));
      } catch {
        sessionStorage.removeItem(STORAGE_KEY);
      }
    }
    setLoading(false);
  }, []);

  const login = async (username, password) => {
    try {
      const res = await authService.login({ username: username.trim(), password });
      if (res.data && res.data.token && res.data.usuario) {
        const u = res.data.usuario;
        const mainU = Array.isArray(u) ? u[0] : u;
        let roles = Array.isArray(mainU.roles) ? mainU.roles : [mainU.rol || "ADMIN"];

        // Garantiza Modo Dual Director / Docente si posee rol DIRECTOR
        if (roles.includes("DIRECTOR") && !roles.includes("DOCENTE")) {
          roles = [...roles, "DOCENTE"];
        }

        const persona = {
          id_persona: mainU.id_persona,
          nombres: mainU.nombre_completo || mainU.nombres || mainU.username,
          apellidos: mainU.apellidos || "",
          email: mainU.email || "",
        };

        const nueva = {
          id_usuario: mainU.id_usuario,
          username: mainU.username,
          id_persona: mainU.id_persona,
          id_carrera: mainU.id_carrera || 1,
          nombreCompleto: mainU.nombre_completo || `${mainU.nombres || ""} ${mainU.apellidos || ""}`.trim() || mainU.username,
          persona,
          roles,
          rolActivo: roles[0] || "ADMIN",
          estudiante: { id_persona: mainU.id_persona, ru: mainU.ru || `RU-${mainU.id_persona}`, id_plan: 1 },
          docente: { id_persona: mainU.id_persona, registro_docente: `DOC-${mainU.id_persona}` },
          token: res.data.token,
          loginTime: new Date().toISOString(),
        };

        sessionStorage.setItem(STORAGE_KEY, JSON.stringify(nueva));
        setSession(nueva);
        return { ok: true, session: nueva };
      }
      return { ok: false, mensaje: res.data?.mensaje || "Credenciales incorrectas." };
    } catch (err) {
      const msg = err?.response?.data?.mensaje || err?.response?.data?.error || "Error de conexión al servidor.";
      return { ok: false, mensaje: typeof msg === "string" ? msg : "Credenciales incorrectas." };
    }
  };

  const logout = () => {
    sessionStorage.removeItem(STORAGE_KEY);
    setSession(null);
  };

  const setRolActivo = (rol) => {
    if (!session || !session.roles.includes(rol)) return;
    const actualizado = { ...session, rolActivo: rol };
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(actualizado));
    setSession(actualizado);
  };

  const hasRole = (...rolesPermitidos) =>
    !!session && session.roles.some((r) => rolesPermitidos.includes(r));

  return (
    <AuthContext.Provider value={{ session, loading, login, logout, setRolActivo, hasRole }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
