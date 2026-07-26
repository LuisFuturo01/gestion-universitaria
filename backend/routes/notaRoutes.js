import express from 'express';
import * as notaController from '../controllers/notaController.js';

const router = express.Router();

router.get('/', notaController.getTodasNotas);
router.post('/', notaController.crearNota);
router.get('/:id_detalle', notaController.getNotasDetalle);
router.put('/:id_nota', notaController.actualizarNota);
router.delete('/:id_nota', notaController.eliminarNota);

export default router;