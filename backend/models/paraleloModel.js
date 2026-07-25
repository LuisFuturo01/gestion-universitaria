import { pool } from '../config/db.js';

export const crear = async (id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion) => {
    const [result] = await pool.query(
        'CALL sp_crear_paralelo(?, ?, ?, ?, ?, ?)', 
        [id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion]
    );
    return result;
};

export const obtenerTodos = async () => {
    const [rows] = await pool.query('CALL sp_obtener_paralelos()');
    return rows[0];
};

export const actualizar = async (id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion) => {
    const [result] = await pool.query(
        'CALL sp_actualizar_paralelo(?, ?, ?, ?, ?, ?)', 
        [id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion]
    );
    return result;
};

export const eliminar = async (id_materia, id_paralelo) => {
    const [result] = await pool.query('CALL sp_eliminar_paralelo(?, ?)', [id_materia, id_paralelo]);
    return result;
};