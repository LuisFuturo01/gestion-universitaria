import { pool } from '../config/db.js';

export const crear = async (id_materia, id_paralelo, id_aula, id_horario) => {
    const [result] = await pool.query(
        'CALL sp_crear_se_cursa(?, ?, ?, ?)', 
        [id_materia, id_paralelo, id_aula, id_horario]
    );
    return result;
};

export const obtenerTodas = async () => {
    try {
        const [rows] = await pool.query('CALL sp_obtener_se_cursa()');
        if (Array.isArray(rows[0])) return rows[0];
        if (Array.isArray(rows)) return rows;
    } catch (e) {
        const [rows] = await pool.query('SELECT id_materia, id_paralelo, id_aula, id_horario FROM se_cursa');
        return rows;
    }
};

export const obtenerPorParalelo = async (id_materia, id_paralelo) => {
    const [rows] = await pool.query('CALL sp_obtener_se_cursa_por_paralelo(?, ?)', [id_materia, id_paralelo]);
    return rows[0];
};

export const actualizar = async (id_materia, id_paralelo, old_aula, old_horario, new_aula, new_horario) => {
    const [result] = await pool.query(
        'CALL sp_actualizar_se_cursa(?, ?, ?, ?, ?, ?)', 
        [id_materia, id_paralelo, old_aula, old_horario, new_aula, new_horario]
    );
    return result;
};

export const eliminar = async (id_materia, id_paralelo, id_aula, id_horario) => {
    const [result] = await pool.query(
        'CALL sp_eliminar_se_cursa(?, ?, ?, ?)', 
        [id_materia, id_paralelo, id_aula, id_horario]
    );
    return result;
};