-- ==============================================================================
-- SCRIPT DE CORRECCIÓN PARA TRIGGER DE AUDITORÍA EN PERSONA
-- Base de Datos: sistemaacademico
-- Resuelve el error de clave foránea #1452 al crear usuarios
-- ==============================================================================

USE sistemaacademico;

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_auditoria_persona_insert`$$

CREATE TRIGGER `trg_auditoria_persona_insert` AFTER INSERT ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (
        @current_user_id, 
        'INSERT', 
        CONCAT('Nueva persona: ', NEW.nombres, ' ', NEW.apellidos, ' (CI: ', NEW.ci, ')'), 
        CURDATE(), 
        CURTIME()
    );
END$$

DELIMITER ;
