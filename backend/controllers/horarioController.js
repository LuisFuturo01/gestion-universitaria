import * as horarioModel from '../models/horarioModel.js';

export const crearHorario = async (req, res) => {
    try {
        const { dia, hora_inicio, hora_fin } = req.body;
        await horarioModel.crear(dia, hora_inicio, hora_fin);
        res.status(201).json({ message: 'Horario creado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear el horario', detalle: error.message });
    }
};

export const getHorarios = async (req, res) => {
    try {
        const horarios = await horarioModel.obtenerTodos();
        res.status(200).json(horarios);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los horarios' });
    }
};

export const getHorarioById = async (req, res) => {
    try {
        const { id } = req.params;
        const horario = await horarioModel.obtenerPorId(id);
        res.status(200).json(horario);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener el horario' });
    }
};

export const actualizarHorario = async (req, res) => {
    try {
        const { id } = req.params;
        const { dia, hora_inicio, hora_fin } = req.body;
        await horarioModel.actualizar(id, dia, hora_inicio, hora_fin);
        res.status(200).json({ message: 'Horario actualizado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar el horario' });
    }
};

export const eliminarHorario = async (req, res) => {
    try {
        const { id } = req.params;
        await horarioModel.eliminar(id);
        res.status(200).json({ message: 'Horario eliminado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar el horario' });
    }
};