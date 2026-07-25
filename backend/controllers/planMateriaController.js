import * as planMateriaModel from '../models/planMateriaModel.js';

export const crearPlanMateria = async (req, res) => {
    try {
        const { id_plan, id_materia, semestre } = req.body;
        await planMateriaModel.crear(id_plan, id_materia, semestre);
        res.status(201).json({ message: 'Materia asignada al plan exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al asignar materia al plan', detalle: error.message });
    }
};

export const getPlanMaterias = async (req, res) => {
    try {
        const materias = await planMateriaModel.obtenerTodas();
        res.status(200).json(materias || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener plan materias' });
    }
};

export const getMateriasPorPlan = async (req, res) => {
    try {
        const { id_plan } = req.params;
        const materias = await planMateriaModel.obtenerPorPlan(id_plan);
        res.status(200).json(materias || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las materias del plan' });
    }
};

export const actualizarPlanMateria = async (req, res) => {
    try {
        const { id_plan, id_materia } = req.params;
        const { semestre } = req.body;
        await planMateriaModel.actualizar(id_plan, id_materia, semestre);
        res.status(200).json({ message: 'Semestre actualizado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar la asignación' });
    }
};

export const eliminarPlanMateria = async (req, res) => {
    try {
        const { id_plan, id_materia } = req.params;
        await planMateriaModel.eliminar(id_plan, id_materia);
        res.status(200).json({ message: 'Materia eliminada del plan exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar la materia del plan' });
    }
};