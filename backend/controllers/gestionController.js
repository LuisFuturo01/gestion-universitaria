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

// Preview cierre — usa sp_preview_cierre_gestion (sin cambios en BD)
export const previewCierreGestion = async (req, res) => {
    try {
        const { id } = req.params;
        const resultado = await gestionModel.previewCierre(id);
        res.status(200).json(resultado);
    } catch (error) {
        const msg = error.message || '';
        if (msg.includes('no existe')) {
            return res.status(404).json({ error: msg });
        }
        res.status(500).json({ error: 'Error al previsualizar el cierre de gestión', detalle: msg });
    }
};

// Cerrar gestión — usa sp_cerrar_gestion (transacción definitiva)
export const cerrarGestion = async (req, res) => {
    try {
        const { id } = req.params;
        const resultado = await gestionModel.cerrar(id);
        res.status(200).json({ message: 'Gestión cerrada exitosamente', ...resultado });
    } catch (error) {
        const msg = error.message || '';
        if (msg.includes('no existe') || msg.includes('ya está cerrada')) {
            return res.status(400).json({ error: msg });
        }
        res.status(500).json({ error: 'Error al cerrar la gestión', detalle: msg });
    }
};

// Auditoría — consulta la tabla auditoria
export const getAuditoria = async (req, res) => {
    try {
        const auditoria = await gestionModel.obtenerAuditoria();
        res.status(200).json(auditoria);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener la auditoría' });
    }
};