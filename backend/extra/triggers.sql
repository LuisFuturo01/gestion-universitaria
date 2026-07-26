-- ==============================================================================
-- SCRIPT OFICIAL DE TRIGGERS Y TABLA DE AUDITORÍA
-- Base de Datos: sistemaacademico
-- ==============================================================================

USE sistemaacademico;

-- 1. Asegurar la columna 'estado' en la tabla 'gestion'
ALTER TABLE `gestion` ADD COLUMN `estado` VARCHAR(20) NOT NULL DEFAULT 'Activa';

-- 2. Estructura de Tabla para Auditoría
CREATE TABLE IF NOT EXISTS `auditoria` (
  `id_auditoria` INT(11) NOT NULL AUTO_INCREMENT,
  `id_usuario` INT(11) NOT NULL,
  `accion` VARCHAR(255) NOT NULL,
  `fecha` DATE NOT NULL,
  `hora` TIME NOT NULL,
  PRIMARY KEY (`id_auditoria`),
  KEY `fk_auditoria_usuario` (`id_usuario`),
  CONSTRAINT `fk_auditoria_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- 3. Trigger 1: Validar que la suma de ponderaciones de criterios no supere el 100%
DROP TRIGGER IF EXISTS trg_validar_ponderacion_criterio;
DELIMITER //
CREATE TRIGGER trg_validar_ponderacion_criterio
BEFORE INSERT ON criterio_evaluacion
FOR EACH ROW
BEGIN
    DECLARE v_suma_actual FLOAT;
    
    SELECT COALESCE(SUM(ponderacion), 0) INTO v_suma_actual
    FROM criterio_evaluacion
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    
    IF (v_suma_actual + NEW.ponderacion) > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La suma de las ponderaciones no puede superar el 100%.';
    END IF;
END //
DELIMITER ;


-- 4. Trigger 2: Incrementar el cupo actual del paralelo al inscribir
DROP TRIGGER IF EXISTS trg_incrementar_cupo_actual;
DELIMITER //
CREATE TRIGGER trg_incrementar_cupo_actual
AFTER INSERT ON detalle_inscripcion
FOR EACH ROW
BEGIN
    UPDATE paralelo
    SET cupo_actual = cupo_actual + 1
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
END //
DELIMITER ;


-- 5. Trigger 3: Decrementar el cupo actual del paralelo al retirar inscripción
DROP TRIGGER IF EXISTS trg_decrementar_cupo_actual;
DELIMITER //
CREATE TRIGGER trg_decrementar_cupo_actual
AFTER DELETE ON detalle_inscripcion
FOR EACH ROW
BEGIN
    UPDATE paralelo
    SET cupo_actual = GREATEST(cupo_actual - 1, 0)
    WHERE id_materia = OLD.id_materia AND id_paralelo = OLD.id_paralelo;
END //
DELIMITER ;


-- 6. Trigger 4: Bloquear inserción de notas si la gestión académica está cerrada
DROP TRIGGER IF EXISTS trg_bloquear_notas_gestion_cerrada;
DELIMITER //
CREATE TRIGGER trg_bloquear_notas_gestion_cerrada
BEFORE INSERT ON nota
FOR EACH ROW
BEGIN
    DECLARE v_estado_gestion VARCHAR(20);
    
    SELECT g.estado INTO v_estado_gestion
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    JOIN gestion g ON i.id_gestion = g.id_gestion
    WHERE di.id_detalle = NEW.id_detalle;
    
    IF v_estado_gestion = 'Cerrada' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Operación denegada: La gestión académica ya está cerrada.';
    END IF;
END //
DELIMITER ;


-- 7. Trigger 5: Auditoría automática al crear nuevos usuarios
DROP TRIGGER IF EXISTS trg_auditoria_nuevo_usuario;
DELIMITER //
CREATE TRIGGER trg_auditoria_nuevo_usuario
AFTER INSERT ON usuario
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (id_usuario, accion, fecha, hora)
    VALUES (NEW.id_usuario, CONCAT('Creación de usuario: ', NEW.username), CURDATE(), CURTIME());
END //
DELIMITER ;