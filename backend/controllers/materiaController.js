import * as materiaModel from '../models/materiaModel.js';

export const crearMateria = async (req, res) => {
    try {
        const { sigla, nombre, carga_horaria, creditos } = req.body;
        const horas = carga_horaria || creditos || 5;
        await materiaModel.crear(sigla, nombre, horas);
        res.status(201).json({ message: 'Materia creada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al crear la materia', detalle: error.message });
    }
};

export const getMaterias = async (req, res) => {
    try {
        const materias = await materiaModel.obtenerTodas();
        res.status(200).json(materias || []);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener las materias' });
    }
};

export const getMateriaById = async (req, res) => {
    try {
        const { id } = req.params;
        const materia = await materiaModel.obtenerPorId(id);
        res.status(200).json(materia);
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener la materia' });
    }
};

export const actualizarMateria = async (req, res) => {
    try {
        const { id } = req.params;
        const { sigla, nombre, carga_horaria, creditos } = req.body;
        const horas = carga_horaria || creditos || 5;
        await materiaModel.actualizar(id, sigla, nombre, horas);
        res.status(200).json({ message: 'Materia actualizada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al actualizar la materia' });
    }
};

export const eliminarMateria = async (req, res) => {
    try {
        const { id } = req.params;
        await materiaModel.eliminar(id);
        res.status(200).json({ message: 'Materia eliminada exitosamente' });
    } catch (error) {
        res.status(500).json({ error: 'Error al eliminar la materia' });
    }
};