import express from 'express';
import * as prerequisitoController from '../controllers/prerequisitoController.js';

const router = express.Router();

router.post('/', prerequisitoController.crearPrerequisito);
router.get('/', prerequisitoController.getPrerequisitos);
router.get('/:id_plan/:id_materia', prerequisitoController.getPrerequisitosMateria);
router.put('/:id_plan/:id_materia/:old_materia_req', prerequisitoController.actualizarPrerequisito);
router.delete('/:id_plan/:id_materia/:id_materia_req', prerequisitoController.eliminarPrerequisito);

export default router;