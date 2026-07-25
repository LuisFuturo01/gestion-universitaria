import express from 'express';
import * as criterioController from '../controllers/criterioEvaluacionController.js';

const router = express.Router();

router.post('/', criterioController.crearCriterio);
router.get('/:id_materia/:id_paralelo', criterioController.getCriteriosParalelo);
router.put('/:id_criterio', criterioController.actualizarCriterio);
router.delete('/:id_criterio', criterioController.eliminarCriterio);

export default router;