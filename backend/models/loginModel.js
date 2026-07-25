import { pool } from "../config/db.js";

export const iniciarSesion = async (username) => {

    const [resultado] = await pool.query(
        `SELECT
            u.id_usuario,
            u.username,
            u.password_hash,
            p.id_persona,
            p.nombres,
            p.apellidos,
            p.email,
            r.nombre AS rol
        FROM USUARIO u
        INNER JOIN PERSONA p
            ON u.id_persona = p.id_persona
        INNER JOIN TIENE_ROL tr
            ON u.id_usuario = tr.id_usuario
        INNER JOIN ROL r
            ON tr.id_rol = r.id_rol
        WHERE u.username = ?`,

        [username]
    );

    return resultado;
};