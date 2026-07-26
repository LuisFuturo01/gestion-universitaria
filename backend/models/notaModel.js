import { pool } from '../config/db.js';

// Obtener TODAS las notas (carga global inicial del frontend)
export const obtenerTodas = async () => {
    const [rows] = await pool.query('SELECT id_nota, id_detalle, id_criterio, nota_obtenida FROM nota');
    return rows;
};
export const crear = async (id_detalle, id_criterio, nota_obtenida) => {
    try {
        const [existente] = await pool.query(
            'SELECT id_nota FROM nota WHERE id_detalle = ? AND id_criterio = ?',
            [id_detalle, id_criterio]
        );

        if (existente.length > 0) {
            await pool.query(
                'UPDATE nota SET nota_obtenida = ? WHERE id_nota = ?',
                [nota_obtenida, existente[0].id_nota]
            );
            return { id_nota: existente[0].id_nota };
        } else {
            const [res] = await pool.query(
                'INSERT INTO nota (id_detalle, id_criterio, nota_obtenida) VALUES (?, ?, ?)',
                [id_detalle, id_criterio, nota_obtenida]
            );
            return { id_nota: res.insertId };
        }
    } catch (e) {
        console.warn('[NOTA MODEL WARN] Fallback SP:', e.message);
        const [result] = await pool.query('CALL sp_crear_nota(?, ?, ?)', [id_detalle, id_criterio, nota_obtenida]);
        return result;
    }
};

export const obtenerPorDetalle = async (id_detalle) => {
    const [rows] = await pool.query('SELECT * FROM nota WHERE id_detalle = ?', [id_detalle]);
    return rows;
};

export const actualizar = async (id_nota, nota_obtenida) => {
    const [result] = await pool.query('UPDATE nota SET nota_obtenida = ? WHERE id_nota = ?', [nota_obtenida, id_nota]);
    return result;
};

export const eliminar = async (id_nota) => {
    const [result] = await pool.query('DELETE FROM nota WHERE id_nota = ?', [id_nota]);
    return result;
};