import * as prerequisitoModel from '../models/prerequisitoModel.js';

export const crearPrerequisito = async (req, res) => {
    try {
        const { id_plan, id_materia, id_materia_req } = req.body;
        await prerequisitoModel.crear(id_plan, id_materia, id_materia_req);
        res.status(201).json({ message: 'Prerrequisito creado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear el prerrequisito', detalle: error.message });
    }
};

export const getPrerequisitos = async (req, res) => {
    try {
        const prerequisitos = await prerequisitoModel.obtenerTodos();
        res.status(200).json(prerequisitos || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los prerrequisitos' });
    }
};

export const getPrerequisitosMateria = async (req, res) => {
    try {
        const { id_plan, id_materia } = req.params;
        const prerequisitos = await prerequisitoModel.obtenerPorMateria(id_plan, id_materia);
        res.status(200).json(prerequisitos || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los prerrequisitos' });
    }
};

export const actualizarPrerequisito = async (req, res) => {
    try {
        const { id_plan, id_materia, old_materia_req } = req.params;
        const { new_materia_req } = req.body;
        await prerequisitoModel.actualizar(id_plan, id_materia, old_materia_req, new_materia_req);
        res.status(200).json({ message: 'Prerrequisito actualizado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar el prerrequisito' });
    }
};

export const eliminarPrerequisito = async (req, res) => {
    try {
        const { id_plan, id_materia, id_materia_req } = req.params;
        await prerequisitoModel.eliminar(id_plan, id_materia, id_materia_req);
        res.status(200).json({ message: 'Prerrequisito eliminado exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar el prerrequisito' });
    }
};