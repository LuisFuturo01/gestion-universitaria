import { pool } from '../config/db.js';

export const crear = async (periodo) => {
    const [result] = await pool.query('CALL sp_crear_gestion(?)', [periodo]);
    return result;
};

export const obtenerTodas = async () => {
    const [rows] = await pool.query('CALL sp_obtener_gestiones()');
    return rows[0];
};

export const actualizar = async (id_gestion, periodo) => {
    const [result] = await pool.query('CALL sp_actualizar_gestion(?, ?)', [id_gestion, periodo]);
    return result;
};

export const eliminar = async (id_gestion) => {
    const [result] = await pool.query('CALL sp_eliminar_gestion(?)', [id_gestion]);
    return result;
};