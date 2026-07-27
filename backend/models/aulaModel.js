import { pool } from '../config/db.js';

export const crear = async (nombre, piso, ubicacion, capacidad) => {
    const [result] = await pool.query('CALL sp_crear_aula(?, ?, ?, ?)', [nombre, piso || 'Piso 1', ubicacion, capacidad]);
    return result;
};

export const obtenerTodas = async () => {
    try {
        const [rows] = await pool.query('CALL sp_obtener_aulas()');
        if (Array.isArray(rows[0])) return rows[0];
        if (Array.isArray(rows)) return rows;
    } catch (e) {
        const [rows] = await pool.query('SELECT id_aula, nombre, piso, ubicacion, capacidad FROM aula');
        return rows;
    }
};

export const obtenerPorId = async (id_aula) => {
    const [rows] = await pool.query('CALL sp_obtener_aula_por_id(?)', [id_aula]);
    return rows[0];
};

export const actualizar = async (id_aula, nombre, piso, ubicacion, capacidad) => {
    const [result] = await pool.query('CALL sp_actualizar_aula(?, ?, ?, ?, ?)', [id_aula, nombre, piso || 'Piso 1', ubicacion, capacidad]);
    return result;
};

export const eliminar = async (id_aula) => {
    const [result] = await pool.query('CALL sp_eliminar_aula(?)', [id_aula]);
    return result;
};