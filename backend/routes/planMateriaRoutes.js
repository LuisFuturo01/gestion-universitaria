import express from 'express';
import * as planMateriaController from '../controllers/planMateriaController.js';

const router = express.Router();

router.post('/', planMateriaController.crearPlanMateria);
router.get('/', planMateriaController.getPlanMaterias);
router.get('/:id_plan', planMateriaController.getMateriasPorPlan);
router.put('/:id_plan/:id_materia', planMateriaController.actualizarPlanMateria);
router.delete('/:id_plan/:id_materia', planMateriaController.eliminarPlanMateria);

export default router;