import express from 'express';
import * as carreraController from '../controllers/carreraController.js';

const router = express.Router();

router.post('/', carreraController.crearCarrera);
router.get('/', carreraController.getCarreras);
router.get('/:id', carreraController.getCarreraById);
router.put('/:id', carreraController.actualizarCarrera);
router.delete('/:id', carreraController.eliminarCarrera);

export default router;