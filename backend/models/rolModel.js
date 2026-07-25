import { pool } from "../config/db.js";

export const obtTodo = async () => {
    const [resultado] = await pool.query(`
        SELECT id_rol, nombre FROM rol
    `);
    return resultado;
};

export const obtRol = async (id) => {
    const [resultado] = await pool.query(`
        SELECT id_rol, nombre FROM rol WHERE id_rol = ?
    `, [id]);
    return resultado[0];
};

export const inserta = async (rol) => {
    const { nombre } = rol;
    const [resultado] = await pool.query(`
        INSERT INTO rol (nombre) VALUES (?)
    `, [nombre]);

    return { id_rol: resultado.insertId, ...rol };
};

export const actualiza = async (id, rol) => {
    const { nombre } = rol;
    await pool.query(`
        UPDATE rol SET nombre = ? WHERE id_rol = ?
    `, [nombre, id]);

    return { id_rol: id, ...rol };
};

export const elimina = async (id) => {
    await pool.query(`
        DELETE FROM rol WHERE id_rol = ?
    `, [id]);

    return id;
};