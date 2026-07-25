import { pool } from '../config/db.js';

export const crear = async (dia, hora_inicio, hora_fin) => {
    const [result] = await pool.query('CALL sp_crear_horario(?, ?, ?)', [dia, hora_inicio, hora_fin]);
    return result;
};

export const obtenerTodos = async () => {
    const [rows] = await pool.query('CALL sp_obtener_horarios()');
    return rows[0];
};

export const obtenerPorId = async (id_horario) => {
    const [rows] = await pool.query('CALL sp_obtener_horario_por_id(?)', [id_horario]);
    return rows[0];
};

export const actualizar = async (id_horario, dia, hora_inicio, hora_fin) => {
    const [result] = await pool.query('CALL sp_actualizar_horario(?, ?, ?, ?)', [id_horario, dia, hora_inicio, hora_fin]);
    return result;
};

export const eliminar = async (id_horario) => {
    const [result] = await pool.query('CALL sp_eliminar_horario(?)', [id_horario]);
    return result;
};