import * as carreraModel from '../models/carreraModel.js';

export const crearCarrera = async (req, res) => {
    try {
        const { nombre } = req.body;
        const result = await carreraModel.crear(nombre);
        res.status(201).json({ message: 'Carrera creada exitosamente', result });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear la carrera', detalle: error.message });
    }
};

export const getCarreras = async (req, res) => {
    try {
        const carreras = await carreraModel.obtenerTodas();
        res.status(200).json(carreras);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las carreras' });
    }
};

export const getCarreraById = async (req, res) => {
    try {
        const { id } = req.params;
        const carrera = await carreraModel.obtenerPorId(id);
        res.status(200).json(carrera);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener la carrera' });
    }
};

export const actualizarCarrera = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre } = req.body;
        await carreraModel.actualizar(id, nombre);
        res.status(200).json({ message: 'Carrera actualizada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar la carrera' });
    }
};

export const eliminarCarrera = async (req, res) => {
    try {
        const { id } = req.params;
        await carreraModel.eliminar(id);
        res.status(200).json({ message: 'Carrera eliminada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar la carrera' });
    }
};
