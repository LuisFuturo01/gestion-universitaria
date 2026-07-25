import { pool } from '../config/db.js';

export const crear = async (id_plan, id_materia, id_materia_req) => {
    const [result] = await pool.query('CALL sp_crear_prerequisito(?, ?, ?)', [id_plan, id_materia, id_materia_req]);
    return result;
};

export const obtenerTodos = async () => {
    const [rows] = await pool.query('CALL sp_obtener_prerequisitos()');
    return rows[0];
};

export const obtenerPorMateria = async (id_plan, id_materia) => {
    const [rows] = await pool.query('CALL sp_obtener_prerequisitos_materia(?, ?)', [id_plan, id_materia]);
    return rows[0];
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