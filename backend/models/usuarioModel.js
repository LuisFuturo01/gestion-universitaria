import { pool } from "../config/db.js";

export const obtTodo = async () => {
    const [resultado] = await pool.query(`
        SELECT
            u.id_usuario,
            u.username,
            u.id_persona,
            u.id_rol,
            r.nombre AS rol,
            p.ci,
            p.nombres,
            p.apellidos,
            p.email
        FROM usuario u
        LEFT JOIN persona p ON u.id_persona = p.id_persona
        LEFT JOIN rol r ON u.id_rol = r.id_rol
        WHERE u.estado = 'A'
    `);

    return resultado;
};

export const obtUsuario = async (id) => {
    const [resultado] = await pool.query(
        `
        SELECT
            u.id_usuario,
            u.username,
            u.id_persona,
            u.id_rol,
            r.nombre AS rol,
            p.ci,
            p.nombres,
            p.apellidos,
            p.email
        FROM usuario u
        LEFT JOIN persona p ON u.id_persona = p.id_persona
        LEFT JOIN rol r ON u.id_rol = r.id_rol
        WHERE u.id_usuario = ? AND u.estado = 'A'  
        `,
        [id]
    );

    return resultado[0];
};

export const inserta = async (usuario) => {
    const { username, password_hash, id_persona, id_rol } = usuario;

    const [resultado] = await pool.query(
        `
        INSERT INTO usuario
        (username, password_hash, id_persona, id_rol, estado)
        VALUES(?, ?, ?, ?, 'A')
        `,
        [username, password_hash, id_persona, id_rol || 1]
    );

    return {
        id_usuario: resultado.insertId,
        ...usuario
    };
};

export const actualiza = async (id, usuario) => {
    const { username, password_hash, id_rol } = usuario;

    await pool.query(
        `
        UPDATE usuario
        SET username = ?,
            password_hash = COALESCE(?, password_hash),
            id_rol = COALESCE(?, id_rol)
        WHERE id_usuario = ?
        `,
        [username, password_hash || null, id_rol || null, id]
    );

    return {
        id_usuario: id,
        ...usuario
    };
};

export const elimina = async (id) => {
    await pool.query(
        `
        UPDATE usuario
        SET estado = 'I'
        WHERE id_usuario = ?
        `,
        [id]
    );

    return id;
};