import * as criterioModel from '../models/criterioEvaluacionModel.js';

export const crearCriterio = async (req, res) => {
    try {
        const { id_materia, id_paralelo, nombre, ponderacion } = req.body;
        const result = await criterioModel.crear(id_materia, id_paralelo, nombre, ponderacion);
        res.status(201).json({ message: 'Criterio de evaluación creado exitosamente', result });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear el criterio', detalle: error.message });
    }
};

export const getCriteriosParalelo = async (req, res) => {
    try {
        const { id_materia, id_paralelo } = req.params;
        const criterios = await criterioModel.obtenerPorParalelo(id_materia, id_paralelo);
        res.status(200).json(criterios);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los criterios' });
    }
};

export const actualizarCriterio = async (req, res) => {
    try {
        const { id_criterio } = req.params;
        const { nombre, ponderacion } = req.body;
        await criterioModel.actualizar(id_criterio, nombre, ponderacion);
        res.status(200).json({ message: 'Criterio actualizado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar el criterio' });
    }
};

export const eliminarCriterio = async (req, res) => {
    try {
        const { id_criterio } = req.params;
        await criterioModel.eliminar(id_criterio);
        res.status(200).json({ message: 'Criterio eliminado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar el criterio' });
    }
};