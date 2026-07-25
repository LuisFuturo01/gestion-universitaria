import express from 'express';
import * as paraleloController from '../controllers/paraleloController.js';

const router = express.Router();

router.post('/', paraleloController.crearParalelo);
router.get('/', paraleloController.getParalelos);
router.put('/:id_materia/:id_paralelo', paraleloController.actualizarParalelo);
router.delete('/:id_materia/:id_paralelo', paraleloController.eliminarParalelo);

export default router;