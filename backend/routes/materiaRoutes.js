import express from 'express';
import * as materiaController from '../controllers/materiaController.js';

const router = express.Router();

router.post('/', materiaController.crearMateria);
router.get('/', materiaController.getMaterias);
router.get('/:id', materiaController.getMateriaById);
router.put('/:id', materiaController.actualizarMateria);
router.delete('/:id', materiaController.eliminarMateria);

export default router;