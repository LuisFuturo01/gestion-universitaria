import * as planEstudioModel from '../models/planEstudioModel.js';

export const crearPlanEstudio = async (req, res) => {
    try {
        const { nombre, id_carrera } = req.body;
        const result = await planEstudioModel.crear(nombre, id_carrera);
        res.status(201).json({ message: 'Plan de estudio creado exitosamente', result });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear el plan de estudio', detalle: error.message });
    }
};

export const getPlanesEstudio = async (req, res) => {
    try {
        const planes = await planEstudioModel.obtenerTodos();
        res.status(200).json(planes);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los planes de estudio' });
    }
};

export const getPlanEstudioById = async (req, res) => {
    try {
        const { id } = req.params;
        const plan = await planEstudioModel.obtenerPorId(id);
        res.status(200).json(plan);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener el plan de estudio' });
    }
};

export const actualizarPlanEstudio = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, id_carrera } = req.body;
        await planEstudioModel.actualizar(id, nombre, id_carrera);
        res.status(200).json({ message: 'Plan de estudio actualizado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar el plan de estudio' });
    }
};

export const eliminarPlanEstudio = async (req, res) => {
    try {
        const { id } = req.params;
        await planEstudioModel.eliminar(id);
        res.status(200).json({ message: 'Plan de estudio eliminado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar el plan de estudio' });
    }
};