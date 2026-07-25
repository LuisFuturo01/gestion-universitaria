import * as notaModel from '../models/notaModel.js';

export const crearNota = async (req, res) => {
    try {
        const { id_detalle, id_criterio, nota_obtenida, puntaje_obtenido } = req.body;
        const notaFinal = nota_obtenida !== undefined ? nota_obtenida : puntaje_obtenido;
        const result = await notaModel.crear(id_detalle, id_criterio, notaFinal);
        res.status(201).json({ message: 'Nota registrada exitosamente', result });
    } catch (error) {
        res.status(500).json({ error: 'Error al registrar la nota', detalle: error.message });
    }
};

export const getNotasDetalle = async (req, res) => {
    try {
        const { id_detalle } = req.params;
        const notas = await notaModel.obtenerPorDetalle(id_detalle);
        res.status(200).json(notas || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las notas' });
    }
};

export const actualizarNota = async (req, res) => {
    try {
        const { id_nota } = req.params;
        const { nota_obtenida, puntaje_obtenido } = req.body;
        const notaFinal = nota_obtenida !== undefined ? nota_obtenida : puntaje_obtenido;
        await notaModel.actualizar(id_nota, notaFinal);
        res.status(200).json({ message: 'Nota actualizada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar la nota' });
    }
};

export const eliminarNota = async (req, res) => {
    try {
        const { id_nota } = req.params;
        await notaModel.eliminar(id_nota);
        res.status(200).json({ message: 'Nota eliminada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar la nota' });
    }
};
