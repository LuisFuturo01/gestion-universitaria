import express from 'express';
import * as gestionController from '../controllers/gestionController.js';

const router = express.Router();

// Auditoría (debe ir antes de /:id para que no capture "auditoria" como id)
router.get('/auditoria', gestionController.getAuditoria);

router.post('/', gestionController.crearGestion);
router.get('/', gestionController.getGestiones);

// Cierre y apertura de gestión
router.post('/iniciar', gestionController.iniciarGestion);
router.post('/reparar-paralelos', gestionController.repararParalelos);
router.get('/:id/preview-cierre', gestionController.previewCierreGestion);
router.post('/:id/cerrar', gestionController.cerrarGestion);

router.put('/:id', gestionController.actualizarGestion);
router.delete('/:id', gestionController.eliminarGestion);

export default router;