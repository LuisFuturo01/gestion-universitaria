import * as aulaModel from '../models/aulaModel.js';

export const crearAula = async (req, res) => {
    try {
        const { nombre, piso, ubicacion, capacidad } = req.body;
        await aulaModel.crear(nombre, piso, ubicacion, capacidad);
        res.status(201).json({ message: 'Aula creada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear el aula', detalle: error.message });
    }
};

export const getAulas = async (req, res) => {
    try {
        const aulas = await aulaModel.obtenerTodas();
        res.status(200).json(aulas || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las aulas' });
    }
};

export const getAulaById = async (req, res) => {
    try {
        const { id } = req.params;
        const aula = await aulaModel.obtenerPorId(id);
        res.status(200).json(aula);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener el aula' });
    }
};

export const actualizarAula = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, piso, ubicacion, capacidad } = req.body;
        await aulaModel.actualizar(id, nombre, piso, ubicacion, capacidad);
        res.status(200).json({ message: 'Aula actualizada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar el aula' });
    }
};

export const eliminarAula = async (req, res) => {
    try {
        const { id } = req.params;
        await aulaModel.eliminar(id);
        res.status(200).json({ message: 'Aula eliminada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar el aula' });
    }
};