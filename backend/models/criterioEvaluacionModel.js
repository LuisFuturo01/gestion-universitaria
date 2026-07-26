import { pool } from '../config/db.js';

export const obtenerTodos = async () => {
    const [rows] = await pool.query('SELECT id_criterio, id_materia, id_paralelo, nombre, ponderacion FROM criterio_evaluacion');
    return rows;
};

export const crear = async (id_materia, id_paralelo, nombre, ponderacion) => {
    try {
        const [result] = await pool.query(
            'INSERT INTO criterio_evaluacion (id_materia, id_paralelo, nombre, ponderacion) VALUES (?, ?, ?, ?)',
            [id_materia, id_paralelo, nombre, ponderacion]
        );
        return result;
    } catch (e) {
        const [result] = await pool.query(
            'CALL sp_crear_criterio(?, ?, ?, ?)', 
            [id_materia, id_paralelo, nombre, ponderacion]
        );
        return result;
    }
};

export const obtenerPorParalelo = async (id_materia, id_paralelo) => {
    const [rows] = await pool.query('SELECT * FROM criterio_evaluacion WHERE id_materia = ? AND id_paralelo = ?', [id_materia, id_paralelo]);
    return rows;
};

export const actualizar = async (id_criterio, nombre, ponderacion) => {
    try {
        const [result] = await pool.query(
            'UPDATE criterio_evaluacion SET nombre = ?, ponderacion = ? WHERE id_criterio = ?',
            [nombre, ponderacion, id_criterio]
        );
        return result;
    } catch (e) {
        const [result] = await pool.query('CALL sp_actualizar_criterio(?, ?, ?)', [id_criterio, nombre, ponderacion]);
        return result;
    }
};

export const eliminar = async (id_criterio) => {
    try {
        await pool.query('DELETE FROM nota WHERE id_criterio = ?', [id_criterio]);
        const [result] = await pool.query('DELETE FROM criterio_evaluacion WHERE id_criterio = ?', [id_criterio]);
        return result;
    } catch (e) {
        const [result] = await pool.query('CALL sp_eliminar_criterio(?)', [id_criterio]);
        return result;
    }
};