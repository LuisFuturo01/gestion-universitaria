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

export const aperturarCompleto = async (id_materia, nombre, cupo_maximo, id_docente, id_gestion, id_aula = 1, id_horario = 1) => {
    const [rows] = await pool.query(
        'CALL sp_aperturar_paralelo_completo(?, ?, ?, ?, ?, ?, ?)', 
        [id_materia, nombre, cupo_maximo, id_docente, id_gestion, id_aula, id_horario]
    );
    return rows[0]?.[0] || rows[0];
};

export const eliminar = async (id_materia, id_paralelo) => {
    const [result] = await pool.query('CALL sp_eliminar_paralelo(?, ?)', [id_materia, id_paralelo]);
    return result;
};

// Asignar docente a un paralelo (el docente solicita dirigir una materia)
// El trigger trg_validar_max_paralelos_docente valida máximo 3 por gestión
export const asignarDocente = async (id_materia, id_paralelo, id_docente) => {
    const [result] = await pool.query(
        `UPDATE paralelo SET id_docente = ? WHERE id_materia = ? AND id_paralelo = ?`,
        [id_docente, id_materia, id_paralelo]
    );
    return result;
};

// Desasignar docente de un paralelo (liberar el paralelo)
export const desasignarDocente = async (id_materia, id_paralelo) => {
    const [result] = await pool.query(
        `UPDATE paralelo SET id_docente = NULL WHERE id_materia = ? AND id_paralelo = ?`,
        [id_materia, id_paralelo]
    );
    return result;
};

// Obtener paralelos sin docente asignado (oferta académica disponible)
export const obtenerSinDocente = async (id_gestion = null) => {
    let query = `
        SELECT p.id_materia, p.id_paralelo, p.nombre, p.cupo_maximo, p.cupo_actual, p.id_gestion,
               m.sigla, m.nombre AS nombre_materia
        FROM paralelo p
        JOIN materia m ON p.id_materia = m.id_materia
        WHERE p.id_docente IS NULL
    `;
    const params = [];
    if (id_gestion) {
        query += ' AND p.id_gestion = ?';
        params.push(id_gestion);
    }
    query += ' ORDER BY m.sigla';
    const [rows] = await pool.query(query, params);
    return rows;
};

// Obtener paralelos que dirige un docente en una gestión
export const obtenerPorDocente = async (id_docente, id_gestion = null) => {
    let query = `
        SELECT p.id_materia, p.id_paralelo, p.nombre, p.cupo_maximo, p.cupo_actual, p.id_gestion,
               m.sigla, m.nombre AS nombre_materia
        FROM paralelo p
        JOIN materia m ON p.id_materia = m.id_materia
        WHERE p.id_docente = ?
    `;
    const params = [id_docente];
    if (id_gestion) {
        query += ' AND p.id_gestion = ?';
        params.push(id_gestion);
    }
    query += ' ORDER BY m.sigla';
    const [rows] = await pool.query(query, params);
    return rows;
};