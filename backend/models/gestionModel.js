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

// Cierre de gestión — usa sp_preview_cierre_gestion (devuelve 2 result sets: resumen + detalle)
export const previewCierre = async (id_gestion) => {
    const [rows] = await pool.query('CALL sp_preview_cierre_gestion(?)', [id_gestion]);
    // rows[0] = resumen (1 fila), rows[1] = detalle por estudiante
    return { resumen: rows[0]?.[0] || {}, detalle: rows[1] || [] };
};

// Cierre de gestión — usa sp_cerrar_gestion (transacción definitiva)
export const cerrar = async (id_gestion) => {
    const [rows] = await pool.query('CALL sp_cerrar_gestion(?)', [id_gestion]);
    return rows[0]?.[0] || {};
};

// Auditoría — consulta la tabla auditoria con datos del usuario
export const obtenerAuditoria = async () => {
    const [rows] = await pool.query(`
        SELECT 
            a.id_auditoria,
            a.id_usuario,
            u.username,
            a.accion,
            a.fecha,
            a.hora
        FROM auditoria a
        LEFT JOIN usuario u ON a.id_usuario = u.id_usuario
        ORDER BY a.fecha DESC, a.hora DESC
        LIMIT 50
    `);
    return rows;
};