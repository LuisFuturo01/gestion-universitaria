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