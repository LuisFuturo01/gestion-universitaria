import { createContext, useContext, useEffect, useState } from "react";
import {
  USUARIOS,
  PERSONAS,
  TIENE_ROL,
  ROLES,
  ROLE_KEYS,
  ESTUDIANTES,
  DOCENTES,
  fullName,
} from "../data/mockData";

const AuthContext = createContext(null);
const STORAGE_KEY = "sau_session"; // Sistema Académico Universitario

function buildSession(usuario) {
  const persona = PERSONAS.find((p) => p.id_persona === usuario.id_persona);
  const idsRol = TIENE_ROL.filter((t) => t.id_usuario === usuario.id_usuario).map((t) => t.id_rol);
  const roles = ROLES.filter((r) => idsRol.includes(r.id_rol)).map((r) => ROLE_KEYS[r.id_rol]);
  const estudiante = ESTUDIANTES.find((e) => e.id_persona === usuario.id_persona) || null;
  const docente = DOCENTES.find((d) => d.id_persona === usuario.id_persona) || null;

  return {
    id_usuario: usuario.id_usuario,
    username: usuario.username,
    id_persona: persona.id_persona,
    nombreCompleto: fullName(persona),
    persona,
    roles, // ej: ["DOCENTE"] o ["DIRECTOR","DOCENTE"]
    rolActivo: roles[0],
    estudiante,
    docente,
    loginTime: new Date().toISOString(),
  };
}

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

  const login = (username, password) => {
    const usuario = USUARIOS.find((u) => u.username === username.trim());
    if (!usuario) return { ok: false, mensaje: "Usuario no encontrado." };
    if (usuario.password !== password) return { ok: false, mensaje: "Contraseña incorrecta." };

    const nueva = buildSession(usuario);
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(nueva));
    setSession(nueva);
    return { ok: true, session: nueva };
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
