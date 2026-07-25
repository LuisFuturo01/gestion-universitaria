import express from 'express';
import * as gestionController from '../controllers/gestionController.js';

const router = express.Router();

router.post('/', gestionController.crearGestion);
router.get('/', gestionController.getGestiones);
router.put('/:id', gestionController.actualizarGestion);
router.delete('/:id', gestionController.eliminarGestion);

export default router;