import { pool } from '../config/db.js';

export const crear = async (sigla, nombre, carga_horaria) => {
    const [result] = await pool.query('CALL sp_crear_materia(?, ?, ?)', [sigla, nombre, carga_horaria]);
    return result;
};

export const obtenerTodas = async () => {
    const [rows] = await pool.query('CALL sp_obtener_materias()');
    return rows[0];
};

export const obtenerPorId = async (id) => {
    const [rows] = await pool.query('CALL sp_obtener_materia_por_id(?)', [id]);
    return rows[0];
};

export const actualizar = async (id, sigla, nombre, carga_horaria) => {
    const [result] = await pool.query('CALL sp_actualizar_materia(?, ?, ?, ?)', [id, sigla, nombre, carga_horaria]);
    return result;
};

export const eliminar = async (id) => {
    const [result] = await pool.query('CALL sp_eliminar_materia(?)', [id]);
    return result;
};