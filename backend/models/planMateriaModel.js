import { pool } from '../config/db.js';

export const crear = async (id_plan, id_materia, semestre) => {
    const [result] = await pool.query('CALL sp_crear_plan_materia(?, ?, ?)', [id_plan, id_materia, semestre]);
    return result;
};

export const obtenerTodas = async () => {
    const [rows] = await pool.query('CALL sp_obtener_plan_materias()');
    return rows[0];
};

export const obtenerPorPlan = async (id_plan) => {
    const [rows] = await pool.query('CALL sp_obtener_materias_por_plan(?)', [id_plan]);
    return rows[0];
};

export const actualizar = async (id_plan, id_materia, semestre) => {
    const [result] = await pool.query('CALL sp_actualizar_plan_materia(?, ?, ?)', [id_plan, id_materia, semestre]);
    return result;
};

export const eliminar = async (id_plan, id_materia) => {
    const [result] = await pool.query('CALL sp_eliminar_plan_materia(?, ?)', [id_plan, id_materia]);
    return result;
};