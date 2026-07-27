import { pool } from '../config/db.js';

export const crear = async (nombre, id_carrera) => {
    const [result] = await pool.query('CALL sp_crear_plan_estudio(?, ?)', [nombre, id_carrera]);
    return result[0];
};

export const obtenerTodos = async () => {
    try {
        const [rows] = await pool.query('CALL sp_obtener_planes_estudio()');
        if (Array.isArray(rows[0])) return rows[0];
        if (Array.isArray(rows)) return rows;
    } catch (e) {
        const [rows] = await pool.query('SELECT id_plan, nombre, id_carrera FROM plan_estudio');
        return rows;
    }
};

export const obtenerPorId = async (id_plan) => {
    const [rows] = await pool.query('CALL sp_obtener_plan_estudio_por_id(?)', [id_plan]);
    return rows[0];
};

export const actualizar = async (id_plan, nombre, id_carrera) => {
    const [result] = await pool.query('CALL sp_actualizar_plan_estudio(?, ?, ?)', [id_plan, nombre, id_carrera]);
    return result;
};

export const eliminar = async (id_plan) => {
    const [result] = await pool.query('CALL sp_eliminar_plan_estudio(?)', [id_plan]);
    return result;
};