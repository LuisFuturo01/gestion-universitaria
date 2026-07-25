import { pool } from '../config/db.js';

export const crear = async (nombre) => {
    const [result] = await pool.query('CALL sp_crear_carrera(?)', [nombre]);
    return result[0];
};

export const obtenerTodas = async () => {
    const [rows] = await pool.query('CALL sp_obtener_carreras()');
    return rows[0];
};

export const obtenerPorId = async (id_carrera) => {
    const [rows] = await pool.query('CALL sp_obtener_carrera_por_id(?)', [id_carrera]);
    return rows[0];
};

export const actualizar = async (id_carrera, nombre) => {
    const [result] = await pool.query('CALL sp_actualizar_carrera(?, ?)', [id_carrera, nombre]);
    return result;
};

export const eliminar = async (id_carrera) => {
    const [result] = await pool.query('CALL sp_eliminar_carrera(?)', [id_carrera]);
    return result;
};