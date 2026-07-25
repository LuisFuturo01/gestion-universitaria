import * as seCursaModel from '../models/seCursaModel.js';

export const crearSeCursa = async (req, res) => {
    try {
        const { id_materia, id_paralelo, id_aula, id_horario } = req.body;
        await seCursaModel.crear(id_materia, id_paralelo, id_aula, id_horario);
        res.status(201).json({ message: 'Asignación creada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear la asignación', detalle: error.message });
    }
};

export const getSeCursa = async (req, res) => {
    try {
        const asignaciones = await seCursaModel.obtenerTodas();
        res.status(200).json(asignaciones);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las asignaciones' });
    }
};

export const getSeCursaPorParalelo = async (req, res) => {
    try {
        const { id_materia, id_paralelo } = req.params;
        const asignaciones = await seCursaModel.obtenerPorParalelo(id_materia, id_paralelo);
        res.status(200).json(asignaciones);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las asignaciones del paralelo' });
    }
};

export const actualizarSeCursa = async (req, res) => {
    try {
        const { id_materia, id_paralelo, old_aula, old_horario } = req.params;
        const { new_aula, new_horario } = req.body;
        await seCursaModel.actualizar(id_materia, id_paralelo, old_aula, old_horario, new_aula, new_horario);
        res.status(200).json({ message: 'Asignación actualizada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar la asignación' });
    }
};

export const eliminarSeCursa = async (req, res) => {
    try {
        const { id_materia, id_paralelo, id_aula, id_horario } = req.params;
        await seCursaModel.eliminar(id_materia, id_paralelo, id_aula, id_horario);
        res.status(200).json({ message: 'Asignación eliminada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar la asignación' });
    }
};