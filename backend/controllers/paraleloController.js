import * as paraleloModel from '../models/paraleloModel.js';

export const crearParalelo = async (req, res) => {
    try {
        const { id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion } = req.body;
        await paraleloModel.crear(id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion);
        res.status(201).json({ message: 'Paralelo creado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear el paralelo', detalle: error.message });
    }
};

export const getParalelos = async (req, res) => {
    try {
        const paralelos = await paraleloModel.obtenerTodos();
        res.status(200).json(paralelos);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los paralelos' });
    }
};

export const actualizarParalelo = async (req, res) => {
    try {
        const { id_materia, id_paralelo } = req.params;
        const { nombre, cupo_maximo, id_docente, id_gestion } = req.body;
        await paraleloModel.actualizar(id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion);
        res.status(200).json({ message: 'Paralelo actualizado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar el paralelo' });
    }
};

export const eliminarParalelo = async (req, res) => {
    try {
        const { id_materia, id_paralelo } = req.params;
        await paraleloModel.eliminar(id_materia, id_paralelo);
        res.status(200).json({ message: 'Paralelo eliminado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar el paralelo' });
    }
};

// Docente solicita dirigir un paralelo (máximo 3 por gestión, validado por trigger en BD)
export const asignarDocente = async (req, res) => {
    try {
        const { id_materia, id_paralelo } = req.params;
        const { id_docente } = req.body;

        if (!id_docente) {
            return res.status(400).json({ error: 'Se requiere id_docente' });
        }

        await paraleloModel.asignarDocente(id_materia, id_paralelo, id_docente);
        res.status(200).json({ message: 'Docente asignado al paralelo exitosamente' });
    } catch (error) {
        // El trigger trg_validar_max_paralelos_docente lanza SQLSTATE 45000
        if (error.message && error.message.includes('ya dirige 3 paralelos')) {
            return res.status(409).json({ error: error.message });
        }
        res.status(500).json({ error: 'Error al asignar docente al paralelo', detalle: error.message });
    }
};

// Liberar un paralelo (desasignar docente)
export const desasignarDocente = async (req, res) => {
    try {
        const { id_materia, id_paralelo } = req.params;
        await paraleloModel.desasignarDocente(id_materia, id_paralelo);
        res.status(200).json({ message: 'Docente desasignado del paralelo exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al desasignar docente del paralelo', detalle: error.message });
    }
};

// Paralelos sin docente (oferta académica disponible para solicitar)
export const getParalelosSinDocente = async (req, res) => {
    try {
        const { id_gestion } = req.query;
        const paralelos = await paraleloModel.obtenerSinDocente(id_gestion || null);
        res.status(200).json(paralelos);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener paralelos sin docente', detalle: error.message });
    }
};

// Paralelos que dirige un docente específico
export const getParalelosPorDocente = async (req, res) => {
    try {
        const { id_docente } = req.params;
        const { id_gestion } = req.query;
        const paralelos = await paraleloModel.obtenerPorDocente(id_docente, id_gestion || null);
        res.status(200).json(paralelos);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener paralelos del docente', detalle: error.message });
    }
};