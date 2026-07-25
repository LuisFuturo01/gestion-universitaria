import express from 'express';
import * as planEstudioController from '../controllers/planEstudioController.js';

const router = express.Router();

router.post('/', planEstudioController.crearPlanEstudio);
router.get('/', planEstudioController.getPlanesEstudio);
router.get('/:id', planEstudioController.getPlanEstudioById);
router.put('/:id', planEstudioController.actualizarPlanEstudio);
router.delete('/:id', planEstudioController.eliminarPlanEstudio);

export default router;