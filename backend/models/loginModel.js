import { authPool, pool } from "../config/db.js";

export const iniciarSesion = async (username) => {
    try {
        const [resultado] = await authPool.query(
            `SELECT
                u.id_usuario,
                u.username,
                u.password_hash,
                u.estado,
                p.id_persona,
                COALESCE(p.nombres, u.username) AS nombres,
                COALESCE(p.apellidos, '') AS apellidos,
                COALESCE(p.email, '') AS email,
                COALESCE(r.nombre, 'Administrador') AS rol,
                e.ru,
                e.id_plan
            FROM usuario u
            LEFT JOIN persona p ON u.id_persona = p.id_persona
            LEFT JOIN estudiante e ON p.id_persona = e.id_persona
            LEFT JOIN rol r ON u.id_rol = r.id_rol
            WHERE LOWER(u.username) = LOWER(?)`,
            [username]
        );
        return resultado;
    } catch (err) {
        console.warn("[AUTH POOL FALLBACK TO MAIN POOL]:", err.message);
        const [resultado] = await pool.query(
            `SELECT
                u.id_usuario,
                u.username,
                u.password_hash,
                u.estado,
                p.id_persona,
                COALESCE(p.nombres, u.username) AS nombres,
                COALESCE(p.apellidos, '') AS apellidos,
                COALESCE(p.email, '') AS email,
                COALESCE(r.nombre, 'Administrador') AS rol,
                e.ru,
                e.id_plan
            FROM usuario u
            LEFT JOIN persona p ON u.id_persona = p.id_persona
            LEFT JOIN estudiante e ON p.id_persona = e.id_persona
            LEFT JOIN rol r ON u.id_rol = r.id_rol
            WHERE LOWER(u.username) = LOWER(?)`,
            [username]
        );
        return resultado;
    }
};