import { pool } from '../config/db.js';

export const crear = async (id_plan, id_materia, semestre) => {
    const [result] = await pool.query('CALL sp_crear_plan_materia(?, ?, ?)', [id_plan, id_materia, semestre]);
    return result;
};

export const obtenerTodas = async () => {
    try {
        const [rows] = await pool.query('CALL sp_obtener_plan_materias()');
        if (Array.isArray(rows[0])) return rows[0];
        if (Array.isArray(rows)) return rows;
    } catch (e) {
        const [rows] = await pool.query('SELECT id_plan, id_materia, semestre FROM plan_materia');
        return rows;
    }
};

export const obtenerPorPlan = async (id_plan) => {
    try {
        const [rows] = await pool.query('CALL sp_obtener_materias_por_plan(?)', [id_plan]);
        if (Array.isArray(rows[0])) return rows[0];
        if (Array.isArray(rows)) return rows;
    } catch (e) {
        const [rows] = await pool.query('SELECT id_plan, id_materia, semestre FROM plan_materia WHERE id_plan = ?', [id_plan]);
        return rows;
    }
};

export const actualizar = async (id_plan, id_materia, semestre) => {
    const [result] = await pool.query('CALL sp_actualizar_plan_materia(?, ?, ?)', [id_plan, id_materia, semestre]);
    return result;
};

export const eliminar = async (id_plan, id_materia) => {
    const [result] = await pool.query('CALL sp_eliminar_plan_materia(?, ?)', [id_plan, id_materia]);
    return result;
};