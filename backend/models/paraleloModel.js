import { pool } from '../config/db.js';
import { repararParalelosGestionActiva } from './gestionModel.js';

export const crear = async (id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion) => {
    const [result] = await pool.query(
        'CALL sp_crear_paralelo(?, ?, ?, ?, ?, ?)', 
        [id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion]
    );
    return result;
};

export const obtenerTodos = async () => {
    try {
        let [rows] = await pool.query(
            'SELECT id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion FROM paralelo'
        );

        if (!rows || rows.length === 0) {
            console.log('[AUTO-REPAIR] La tabla paralelo está vacía. Generando paralelos para la gestión activa...');
            await repararParalelosGestionActiva();
            const [rowsReparados] = await pool.query(
                'SELECT id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion FROM paralelo'
            );
            return rowsReparados;
        }

        return rows;
    } catch (err) {
        console.error('[PARALELO MODEL ERROR]:', err.message);
        return [];
    }
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

export const asignarDocente = async (id_materia, id_paralelo, id_docente, id_gestion = null) => {
    let query = `UPDATE paralelo SET id_docente = ? WHERE id_materia = ? AND id_paralelo = ?`;
    const params = [id_docente, id_materia, id_paralelo];
    if (id_gestion) {
        query += ` AND id_gestion = ?`;
        params.push(id_gestion);
    }
    const [result] = await pool.query(query, params);
    return result;
};

export const desasignarDocente = async (id_materia, id_paralelo, id_gestion = null) => {
    let query = `UPDATE paralelo SET id_docente = NULL WHERE id_materia = ? AND id_paralelo = ?`;
    const params = [id_materia, id_paralelo];
    if (id_gestion) {
        query += ` AND id_gestion = ?`;
        params.push(id_gestion);
    }
    const [result] = await pool.query(query, params);
    return result;
};

// Obtener paralelos sin docente asignado (oferta académica disponible)
export const obtenerSinDocente = async (id_gestion = null) => {
    let query = `
        SELECT 
            p.id_materia, p.id_paralelo, p.nombre, p.cupo_maximo,
            COALESCE(
                (SELECT COUNT(*) 
                 FROM detalle_inscripcion d
                 JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
                 WHERE d.id_materia = p.id_materia 
                   AND d.id_paralelo = p.id_paralelo 
                   AND i.id_gestion = p.id_gestion 
                   AND d.estado = 'Inscrito'), 
                0
            ) AS cupo_actual,
            GREATEST(0, p.cupo_maximo - COALESCE(
                (SELECT COUNT(*) 
                 FROM detalle_inscripcion d
                 JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
                 WHERE d.id_materia = p.id_materia 
                   AND d.id_paralelo = p.id_paralelo 
                   AND i.id_gestion = p.id_gestion 
                   AND d.estado = 'Inscrito'), 
                0
            )) AS cupo_disponible,
            p.id_gestion,
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
        SELECT 
            p.id_materia, p.id_paralelo, p.nombre, p.cupo_maximo,
            COALESCE(
                (SELECT COUNT(*) 
                 FROM detalle_inscripcion d
                 JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
                 WHERE d.id_materia = p.id_materia 
                   AND d.id_paralelo = p.id_paralelo 
                   AND i.id_gestion = p.id_gestion 
                   AND d.estado = 'Inscrito'), 
                0
            ) AS cupo_actual,
            GREATEST(0, p.cupo_maximo - COALESCE(
                (SELECT COUNT(*) 
                 FROM detalle_inscripcion d
                 JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
                 WHERE d.id_materia = p.id_materia 
                   AND d.id_paralelo = p.id_paralelo 
                   AND i.id_gestion = p.id_gestion 
                   AND d.estado = 'Inscrito'), 
                0
            )) AS cupo_disponible,
            p.id_gestion,
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