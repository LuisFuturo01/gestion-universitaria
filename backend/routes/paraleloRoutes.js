import express from 'express';
import * as paraleloController from '../controllers/paraleloController.js';

const router = express.Router();

router.post('/', paraleloController.crearParalelo);
router.get('/', paraleloController.getParalelos);
router.get('/sin-docente', paraleloController.getParalelosSinDocente);
router.get('/docente/:id_docente', paraleloController.getParalelosPorDocente);
router.put('/:id_materia/:id_paralelo', paraleloController.actualizarParalelo);
router.put('/:id_materia/:id_paralelo/asignar-docente', paraleloController.asignarDocente);
router.put('/:id_materia/:id_paralelo/desasignar-docente', paraleloController.desasignarDocente);
router.delete('/:id_materia/:id_paralelo', paraleloController.eliminarParalelo);

export default router;