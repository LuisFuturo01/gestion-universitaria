import * as gestionModel from '../models/gestionModel.js';

export const crearGestion = async (req, res) => {
    try {
        const { periodo } = req.body;
        await gestionModel.crear(periodo);
        res.status(201).json({ message: 'Gestión creada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear la gestión', detalle: error.message });
    }
};

export const getGestiones = async (req, res) => {
    try {
        const gestiones = await gestionModel.obtenerTodas();
        res.status(200).json(gestiones);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las gestiones' });
    }
};

export const actualizarGestion = async (req, res) => {
    try {
        const { id } = req.params;
        const { periodo } = req.body;
        await gestionModel.actualizar(id, periodo);
        res.status(200).json({ message: 'Gestión actualizada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar la gestión' });
    }
};

export const eliminarGestion = async (req, res) => {
    try {
        const { id } = req.params;
        await gestionModel.eliminar(id);
        res.status(200).json({ message: 'Gestión eliminada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar la gestión' });
    }
};