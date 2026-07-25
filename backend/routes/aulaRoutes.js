import express from 'express';
import * as aulaController from '../controllers/aulaController.js';

const router = express.Router();

router.post('/', aulaController.crearAula);
router.get('/', aulaController.getAulas);
router.get('/:id', aulaController.getAulaById);
router.put('/:id', aulaController.actualizarAula);
router.delete('/:id', aulaController.eliminarAula);

export default router;