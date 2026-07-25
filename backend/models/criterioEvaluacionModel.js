import { pool } from '../config/db.js';

export const crear = async (id_materia, id_paralelo, nombre, ponderacion) => {
    const [result] = await pool.query(
        'CALL sp_crear_criterio(?, ?, ?, ?)', 
        [id_materia, id_paralelo, nombre, ponderacion]
    );
    return result[0];
};

export const obtenerPorParalelo = async (id_materia, id_paralelo) => {
    const [rows] = await pool.query('CALL sp_obtener_criterios_paralelo(?, ?)', [id_materia, id_paralelo]);
    return rows[0];
};

export const actualizar = async (id_criterio, nombre, ponderacion) => {
    const [result] = await pool.query('CALL sp_actualizar_criterio(?, ?, ?)', [id_criterio, nombre, ponderacion]);
    return result;
};

export const eliminar = async (id_criterio) => {
    const [result] = await pool.query('CALL sp_eliminar_criterio(?)', [id_criterio]);
    return result;
};