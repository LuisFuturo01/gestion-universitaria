import express from 'express';
import * as seCursaController from '../controllers/seCursaController.js';

const router = express.Router();

router.post('/', seCursaController.crearSeCursa);
router.get('/', seCursaController.getSeCursa);
router.get('/:id_materia/:id_paralelo', seCursaController.getSeCursaPorParalelo);
router.put('/:id_materia/:id_paralelo/:old_aula/:old_horario', seCursaController.actualizarSeCursa);
router.delete('/:id_materia/:id_paralelo/:id_aula/:id_horario', seCursaController.eliminarSeCursa);

export default router;