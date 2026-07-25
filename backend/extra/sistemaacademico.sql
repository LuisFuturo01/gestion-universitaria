SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_realizar_inscripcion` (IN `p_id_estudiante` INT, IN `p_id_gestion` INT, IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
DECLARE v_id_inscripcion INT DEFAULT NULL;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
RESIGNAL;
END;
START TRANSACTION;
IF NOT fn_existe_estudiante(p_id_estudiante) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='El estudiante no existe.';
END IF;
IF NOT fn_existe_gestion(p_id_gestion) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='La gestion no existe.';
END IF;
IF NOT fn_existe_materia(p_id_materia) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='La materia no existe.';
END IF;
IF NOT fn_existe_paralelo(p_id_materia,p_id_paralelo) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='El paralelo no existe.';
END IF;
IF NOT fn_cupo_disponible(p_id_materia,p_id_paralelo) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='No existen cupos disponibles.';
END IF;
IF fn_ya_inscrito(p_id_estudiante,p_id_gestion,p_id_materia) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='El estudiante ya esta inscrito en esa materia.';
END IF;
IF NOT fn_tiene_prerrequisitos(p_id_estudiante,p_id_plan,p_id_materia) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='No cumple los prerrequisitos.';
END IF;
SELECT id_inscripcion
INTO v_id_inscripcion
FROM INSCRIPCION
WHERE id_estudiante=p_id_estudiante
AND id_gestion=p_id_gestion
LIMIT 1;
IF v_id_inscripcion IS NULL THEN
INSERT INTO INSCRIPCION(id_estudiante, id_gestion, fecha_registro)
VALUES(p_id_estudiante, p_id_gestion, CURDATE());
SET v_id_inscripcion = LAST_INSERT_ID();
END IF;
INSERT INTO DETALLE_INSCRIPCION(id_inscripcion, id_materia, id_paralelo, estado, nota_final)
VALUES(v_id_inscripcion, p_id_materia, p_id_paralelo, 'Inscrito', 0);
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_retirar_inscripcion` (IN `p_id_detalle` INT)   BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
RESIGNAL;
END;
START TRANSACTION;
IF NOT EXISTS(
SELECT 1 FROM DETALLE_INSCRIPCION WHERE id_detalle=p_id_detalle
) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='La inscripcion no existe.';
END IF;
UPDATE DETALLE_INSCRIPCION
SET estado='Abandono'
WHERE id_detalle=p_id_detalle;
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_cupo_disponible` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_max INT;
DECLARE v_actual INT;
SELECT cupo_maximo, cupo_actual INTO v_max, v_actual FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
RETURN v_actual < v_max;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_estudiante` (`p_id_estudiante` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM ESTUDIANTE WHERE id_persona = p_id_estudiante;
RETURN v_existe > 0;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_gestion` (`p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM GESTION WHERE id_gestion=p_id_gestion;
RETURN v_existe>0;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_materia` (`p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM MATERIA WHERE id_materia=p_id_materia;
RETURN v_existe>0;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_paralelo` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM PARALELO WHERE id_materia=p_id_materia AND id_paralelo=p_id_paralelo;
RETURN v_existe>0;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_tiene_prerrequisitos` (`p_id_estudiante` INT, `p_id_plan` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_total INT DEFAULT 0;
DECLARE v_aprobadas INT DEFAULT 0;
SELECT COUNT(*) INTO v_total FROM PREREQUISITO WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
IF v_total = 0 THEN
RETURN TRUE;
END IF;
SELECT COUNT(*) INTO v_aprobadas FROM PREREQUISITO pr INNER JOIN DETALLE_INSCRIPCION di ON pr.id_materia_req = di.id_materia INNER JOIN INSCRIPCION i ON di.id_inscripcion = i.id_inscripcion WHERE pr.id_plan = p_id_plan AND pr.id_materia = p_id_materia AND i.id_estudiante = p_id_estudiante AND di.nota_final >= 51;
RETURN v_total = v_aprobadas;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_ya_inscrito` (`p_id_estudiante` INT, `p_id_gestion` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM INSCRIPCION i INNER JOIN DETALLE_INSCRIPCION d ON i.id_inscripcion=d.id_inscripcion WHERE i.id_estudiante=p_id_estudiante AND i.id_gestion=p_id_gestion AND d.id_materia=p_id_materia;
RETURN v_existe>0;
END$$

DELIMITER ;

CREATE TABLE `administrativo` (
  `id_persona` int(11) NOT NULL,
  `item` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `aula` (
  `id_aula` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `ubicacion` varchar(100) NOT NULL,
  `capacidad` int(11) NOT NULL,
  PRIMARY KEY (`id_aula`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `carrera` (
  `id_carrera` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  PRIMARY KEY (`id_carrera`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `criterio_evaluacion` (
  `id_criterio` int(11) NOT NULL AUTO_INCREMENT,
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `ponderacion` float NOT NULL,
  PRIMARY KEY (`id_criterio`),
  KEY `fk_criterio_paralelo` (`id_materia`,`id_paralelo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `detalle_inscripcion` (
  `id_detalle` int(11) NOT NULL AUTO_INCREMENT,
  `id_inscripcion` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Inscrito',
  `nota_final` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_detalle`),
  KEY `fk_detalle_inscripcion_cabecera` (`id_inscripcion`),
  KEY `fk_detalle_paralelo` (`id_materia`,`id_paralelo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELIMITER $$
CREATE TRIGGER `trg_aumentar_cupo` AFTER INSERT ON `detalle_inscripcion` FOR EACH ROW BEGIN
    UPDATE PARALELO
    SET cupo_actual=cupo_actual+1
    WHERE id_materia=NEW.id_materia
    AND id_paralelo=NEW.id_paralelo;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `trg_disminuir_cupo` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW BEGIN
    UPDATE PARALELO
    SET cupo_actual=cupo_actual-1
    WHERE id_materia=OLD.id_materia
    AND id_paralelo=OLD.id_paralelo;
END
$$
DELIMITER ;

CREATE TABLE `director_carrera` (
  `id_persona` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `director_carrera_asignacion` (
  `id_persona` int(11) NOT NULL,
  `id_carrera` int(11) NOT NULL,
  `gestion` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `docente` (
  `id_persona` int(11) NOT NULL,
  `registro_docente` varchar(20) NOT NULL,
  `grado_academico` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `estudiante` (
  `id_persona` int(11) NOT NULL,
  `ru` varchar(20) NOT NULL,
  `id_plan` int(11) NOT NULL,
  `anio_ingreso` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `gestion` (
  `id_gestion` int(11) NOT NULL AUTO_INCREMENT,
  `periodo` varchar(20) NOT NULL,
  PRIMARY KEY (`id_gestion`),
  UNIQUE KEY `periodo` (`periodo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `horario` (
  `id_horario` int(11) NOT NULL AUTO_INCREMENT,
  `dia` varchar(15) NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL,
  PRIMARY KEY (`id_horario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `inscripcion` (
  `id_inscripcion` int(11) NOT NULL AUTO_INCREMENT,
  `id_estudiante` int(11) NOT NULL,
  `id_gestion` int(11) NOT NULL,
  `fecha_registro` date NOT NULL,
  PRIMARY KEY (`id_inscripcion`),
  KEY `fk_inscripcion_estudiante` (`id_estudiante`),
  KEY `fk_inscripcion_gestion` (`id_gestion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `materia` (
  `id_materia` int(11) NOT NULL AUTO_INCREMENT,
  `sigla` varchar(15) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `creditos` int(11) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Activo',
  PRIMARY KEY (`id_materia`),
  UNIQUE KEY `sigla` (`sigla`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `nota` (
  `id_nota` int(11) NOT NULL AUTO_INCREMENT,
  `id_detalle` int(11) NOT NULL,
  `id_criterio` int(11) NOT NULL,
  `puntaje_obtenido` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_nota`),
  KEY `fk_nota_detalle` (`id_detalle`),
  KEY `fk_nota_criterio` (`id_criterio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `paralelo` (
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `nombre` varchar(10) NOT NULL,
  `cupo_maximo` int(11) NOT NULL,
  `cupo_actual` int(11) NOT NULL DEFAULT 0,
  `id_docente` int(11) NOT NULL,
  `id_gestion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `persona` (
  `id_persona` int(11) NOT NULL AUTO_INCREMENT,
  `ci` varchar(20) NOT NULL,
  `nombres` varchar(80) NOT NULL,
  `apellidos` varchar(80) NOT NULL,
  `fecha_nac` date NOT NULL,
  `sexo` varchar(1) NOT NULL,
  `email` varchar(120) NOT NULL,
  `estado` char(1) NOT NULL DEFAULT 'A',
  PRIMARY KEY (`id_persona`),
  UNIQUE KEY `ci` (`ci`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `plan_estudio` (
  `id_plan` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `id_carrera` int(11) NOT NULL,
  PRIMARY KEY (`id_plan`),
  KEY `fk_plan_carrera` (`id_carrera`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `plan_materia` (
  `id_plan` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `semestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `prerequisito` (
  `id_plan` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `id_materia_req` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `rol` (
  `id_rol` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  PRIMARY KEY (`id_rol`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `se_cursa` (
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `id_aula` int(11) NOT NULL,
  `id_horario` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `tiene_rol` (
  `id_usuario` int(11) NOT NULL,
  `id_rol` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `usuario` (
  `id_usuario` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `id_persona` int(11) NOT NULL,
  `estado` char(1) NOT NULL DEFAULT 'A',
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `id_persona` (`id_persona`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE `administrativo` ADD PRIMARY KEY (`id_persona`), ADD UNIQUE KEY `item` (`item`);
ALTER TABLE `director_carrera` ADD PRIMARY KEY (`id_persona`);
ALTER TABLE `director_carrera_asignacion` ADD PRIMARY KEY (`id_persona`,`id_carrera`), ADD KEY `fk_asignacion_carrera` (`id_carrera`);
ALTER TABLE `docente` ADD PRIMARY KEY (`id_persona`), ADD UNIQUE KEY `registro_docente` (`registro_docente`);
ALTER TABLE `estudiante` ADD PRIMARY KEY (`id_persona`), ADD UNIQUE KEY `ru` (`ru`), ADD KEY `fk_estudiante_plan` (`id_plan`);
ALTER TABLE `paralelo` ADD PRIMARY KEY (`id_materia`,`id_paralelo`), ADD KEY `fk_paralelo_docente` (`id_docente`), ADD KEY `fk_paralelo_gestion` (`id_gestion`);
ALTER TABLE `plan_materia` ADD PRIMARY KEY (`id_plan`,`id_materia`), ADD KEY `fk_planmateria_materia` (`id_materia`);
ALTER TABLE `prerequisito` ADD PRIMARY KEY (`id_plan`,`id_materia`,`id_materia_req`), ADD KEY `fk_prereq_materia_req` (`id_plan`,`id_materia_req`);
ALTER TABLE `se_cursa` ADD PRIMARY KEY (`id_materia`,`id_paralelo`,`id_aula`,`id_horario`), ADD KEY `fk_secursa_aula` (`id_aula`), ADD KEY `fk_secursa_horario` (`id_horario`);
ALTER TABLE `tiene_rol` ADD PRIMARY KEY (`id_usuario`,`id_rol`), ADD KEY `fk_tienerol_rol` (`id_rol`);

ALTER TABLE `administrativo` ADD CONSTRAINT `fk_admin_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`);
ALTER TABLE `criterio_evaluacion` ADD CONSTRAINT `fk_criterio_paralelo` FOREIGN KEY (`id_materia`,`id_paralelo`) REFERENCES `paralelo` (`id_materia`, `id_paralelo`);
ALTER TABLE `detalle_inscripcion` ADD CONSTRAINT `fk_detalle_inscripcion_cabecera` FOREIGN KEY (`id_inscripcion`) REFERENCES `inscripcion` (`id_inscripcion`), ADD CONSTRAINT `fk_detalle_paralelo` FOREIGN KEY (`id_materia`,`id_paralelo`) REFERENCES `paralelo` (`id_materia`, `id_paralelo`);
ALTER TABLE `director_carrera` ADD CONSTRAINT `fk_director_docente` FOREIGN KEY (`id_persona`) REFERENCES `docente` (`id_persona`);
ALTER TABLE `director_carrera_asignacion` ADD CONSTRAINT `fk_asignacion_carrera` FOREIGN KEY (`id_carrera`) REFERENCES `carrera` (`id_carrera`), ADD CONSTRAINT `fk_asignacion_director` FOREIGN KEY (`id_persona`) REFERENCES `director_carrera` (`id_persona`);
ALTER TABLE `docente` ADD CONSTRAINT `fk_docente_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`);
ALTER TABLE `estudiante` ADD CONSTRAINT `fk_estudiante_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`), ADD CONSTRAINT `fk_estudiante_plan` FOREIGN KEY (`id_plan`) REFERENCES `plan_estudio` (`id_plan`);
ALTER TABLE `inscripcion` ADD CONSTRAINT `fk_inscripcion_estudiante` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiante` (`id_persona`), ADD CONSTRAINT `fk_inscripcion_gestion` FOREIGN KEY (`id_gestion`) REFERENCES `gestion` (`id_gestion`);
ALTER TABLE `nota` ADD CONSTRAINT `fk_nota_criterio` FOREIGN KEY (`id_criterio`) REFERENCES `criterio_evaluacion` (`id_criterio`), ADD CONSTRAINT `fk_nota_detalle` FOREIGN KEY (`id_detalle`) REFERENCES `detalle_inscripcion` (`id_detalle`);
ALTER TABLE `paralelo` ADD CONSTRAINT `fk_paralelo_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_persona`), ADD CONSTRAINT `fk_paralelo_gestion` FOREIGN KEY (`id_gestion`) REFERENCES `gestion` (`id_gestion`), ADD CONSTRAINT `fk_paralelo_materia` FOREIGN KEY (`id_materia`) REFERENCES `materia` (`id_materia`);
ALTER TABLE `plan_estudio` ADD CONSTRAINT `fk_plan_carrera` FOREIGN KEY (`id_carrera`) REFERENCES `carrera` (`id_carrera`);
ALTER TABLE `plan_materia` ADD CONSTRAINT `fk_planmateria_materia` FOREIGN KEY (`id_materia`) REFERENCES `materia` (`id_materia`), ADD CONSTRAINT `fk_planmateria_plan` FOREIGN KEY (`id_plan`) REFERENCES `plan_estudio` (`id_plan`);
ALTER TABLE `prerequisito` ADD CONSTRAINT `fk_prereq_materia_actual` FOREIGN KEY (`id_plan`,`id_materia`) REFERENCES `plan_materia` (`id_plan`, `id_materia`), ADD CONSTRAINT `fk_prereq_materia_req` FOREIGN KEY (`id_plan`,`id_materia_req`) REFERENCES `plan_materia` (`id_plan`, `id_materia`);
ALTER TABLE `se_cursa` ADD CONSTRAINT `fk_secursa_aula` FOREIGN KEY (`id_aula`) REFERENCES `aula` (`id_aula`), ADD CONSTRAINT `fk_secursa_horario` FOREIGN KEY (`id_horario`) REFERENCES `horario` (`id_horario`), ADD CONSTRAINT `fk_secursa_paralelo` FOREIGN KEY (`id_materia`,`id_paralelo`) REFERENCES `paralelo` (`id_materia`, `id_paralelo`);
ALTER TABLE `tiene_rol` ADD CONSTRAINT `fk_tienerol_rol` FOREIGN KEY (`id_rol`) REFERENCES `rol` (`id_rol`), ADD CONSTRAINT `fk_tienerol_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);
ALTER TABLE `usuario` ADD CONSTRAINT `fk_usuario_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`);
COMMIT;
