import { pool } from '../config/db.js';

export const crear = async (id_plan, id_materia, id_materia_req) => {
    const [result] = await pool.query('CALL sp_crear_prerequisito(?, ?, ?)', [id_plan, id_materia, id_materia_req]);
    return result;
};

export const obtenerTodos = async () => {
    const [rows] = await pool.query('SELECT id_plan, id_materia, id_materia_req FROM prerequisito');
    return rows;
};

export const obtenerPorMateria = async (id_plan, id_materia) => {
    const [rows] = await pool.query('SELECT id_plan, id_materia, id_materia_req FROM prerequisito WHERE id_materia = ?', [id_materia]);
    return rows;
};

export const actualizar = async (id_plan, id_materia, old_materia_req, new_materia_req) => {
    const [result] = await pool.query(
        'CALL sp_actualizar_prerequisito(?, ?, ?, ?)', 
        [id_plan, id_materia, old_materia_req, new_materia_req]
    );
    return result;
};

export const eliminar = async (id_plan, id_materia, id_materia_req) => {
    const [result] = await pool.query(
        'CALL sp_eliminar_prerequisito(?, ?, ?)', 
        [id_plan, id_materia, id_materia_req]
    );
    return result;
};