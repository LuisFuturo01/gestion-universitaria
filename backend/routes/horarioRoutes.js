import express from 'express';
import * as horarioController from '../controllers/horarioController.js';

const router = express.Router();

router.post('/', horarioController.crearHorario);
router.get('/', horarioController.getHorarios);
router.get('/:id', horarioController.getHorarioById);
router.put('/:id', horarioController.actualizarHorario);
router.delete('/:id', horarioController.eliminarHorario);

export default router;