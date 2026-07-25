import { pool } from '../config/db.js';

export const crear = async (id_detalle, id_criterio, nota_obtenida) => {
    const [result] = await pool.query(
        'CALL sp_crear_nota(?, ?, ?)', 
        [id_detalle, id_criterio, nota_obtenida]
    );
    return result[0];
};

export const obtenerPorDetalle = async (id_detalle) => {
    const [rows] = await pool.query('CALL sp_obtener_notas_detalle(?)', [id_detalle]);
    return rows[0];
};

export const actualizar = async (id_nota, nota_obtenida) => {
    const [result] = await pool.query('CALL sp_actualizar_nota(?, ?)', [id_nota, nota_obtenida]);
    return result;
};

export const eliminar = async (id_nota) => {
    const [result] = await pool.query('CALL sp_eliminar_nota(?)', [id_nota]);
    return result;
};