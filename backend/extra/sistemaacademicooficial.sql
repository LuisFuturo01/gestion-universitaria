-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 26-07-2026 a las 01:46:40
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistemaacademico`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_aula` (IN `p_id_aula` INT, IN `p_nombre` VARCHAR(50), IN `p_piso` VARCHAR(20), IN `p_ubicacion` VARCHAR(100), IN `p_capacidad` INT)   BEGIN
    UPDATE aula SET nombre = p_nombre, piso = p_piso, ubicacion = p_ubicacion, capacidad = p_capacidad WHERE id_aula = p_id_aula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_carrera` (IN `p_id_carrera` INT, IN `p_nombre` VARCHAR(100))   BEGIN
    UPDATE carrera SET nombre = p_nombre WHERE id_carrera = p_id_carrera;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_criterio` (IN `p_id_criterio` INT, IN `p_nombre` VARCHAR(50), IN `p_ponderacion` FLOAT)   BEGIN
    UPDATE criterio_evaluacion SET nombre = p_nombre, ponderacion = p_ponderacion WHERE id_criterio = p_id_criterio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_gestion` (IN `p_id_gestion` INT, IN `p_periodo` VARCHAR(20))   BEGIN
    UPDATE gestion SET periodo = p_periodo WHERE id_gestion = p_id_gestion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_horario` (IN `p_id_horario` INT, IN `p_dia` VARCHAR(15), IN `p_hora_inicio` TIME, IN `p_hora_fin` TIME)   BEGIN
    UPDATE horario SET dia = p_dia, hora_inicio = p_hora_inicio, hora_fin = p_hora_fin WHERE id_horario = p_id_horario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_materia` (IN `p_id` INT, IN `p_sigla` VARCHAR(15), IN `p_nombre` VARCHAR(100), IN `p_carga_horaria` INT)   BEGIN
    UPDATE materia SET sigla = p_sigla, nombre = p_nombre, carga_horaria = p_carga_horaria WHERE id_materia = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_nota` (IN `p_id_nota` INT, IN `p_puntaje` FLOAT)   BEGIN
    UPDATE nota SET nota_obtenida = p_puntaje WHERE id_nota = p_id_nota;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT)   BEGIN
    UPDATE paralelo
    SET nombre = p_nombre, cupo_maximo = p_cupo_maximo, id_docente = p_id_docente, id_gestion = p_id_gestion
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_plan_estudio` (IN `p_id_plan` INT, IN `p_nombre` VARCHAR(100), IN `p_id_carrera` INT)   BEGIN
    UPDATE plan_estudio SET nombre = p_nombre, id_carrera = p_id_carrera WHERE id_plan = p_id_plan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_semestre` INT)   BEGIN
    UPDATE plan_materia SET semestre = p_semestre WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_old_req` INT, IN `p_new_req` INT)   BEGIN
    UPDATE prerequisito SET id_materia_req = p_new_req WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_old_req;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_old_aula` INT, IN `p_old_horario` INT, IN `p_new_aula` INT, IN `p_new_horario` INT)   BEGIN
    UPDATE se_cursa SET id_aula = p_new_aula, id_horario = p_new_horario
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_old_aula AND id_horario = p_old_horario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_aula` (IN `p_nombre` VARCHAR(50), IN `p_piso` VARCHAR(20), IN `p_ubicacion` VARCHAR(100), IN `p_capacidad` INT)   BEGIN
    INSERT INTO aula (nombre, piso, ubicacion, capacidad) VALUES (p_nombre, p_piso, p_ubicacion, p_capacidad);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_carrera` (IN `p_nombre` VARCHAR(100))   BEGIN
    INSERT INTO carrera (nombre) VALUES (p_nombre);
    SELECT LAST_INSERT_ID() AS id_carrera;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_criterio` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(50), IN `p_ponderacion` FLOAT)   BEGIN
    INSERT INTO criterio_evaluacion (id_materia, id_paralelo, nombre, ponderacion) VALUES (p_id_materia, p_id_paralelo, p_nombre, p_ponderacion);
    SELECT LAST_INSERT_ID() AS id_criterio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_gestion` (IN `p_periodo` VARCHAR(20))   BEGIN
    INSERT INTO gestion (periodo) VALUES (p_periodo);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_horario` (IN `p_dia` VARCHAR(15), IN `p_hora_inicio` TIME, IN `p_hora_fin` TIME)   BEGIN
    INSERT INTO horario (dia, hora_inicio, hora_fin) VALUES (p_dia, p_hora_inicio, p_hora_fin);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_materia` (IN `p_sigla` VARCHAR(15), IN `p_nombre` VARCHAR(100), IN `p_carga_horaria` INT)   BEGIN
    INSERT INTO materia (sigla, nombre, carga_horaria) VALUES (p_sigla, p_nombre, p_carga_horaria);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_nota` (IN `p_id_detalle` INT, IN `p_id_criterio` INT, IN `p_puntaje` FLOAT)   BEGIN
    INSERT INTO nota (id_detalle, id_criterio, nota_obtenida) VALUES (p_id_detalle, p_id_criterio, p_puntaje);
    SELECT LAST_INSERT_ID() AS id_nota;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT)   BEGIN
    INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion)
    VALUES (p_id_materia, p_id_paralelo, p_nombre, p_cupo_maximo, p_id_docente, p_id_gestion);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_plan_estudio` (IN `p_nombre` VARCHAR(100), IN `p_id_carrera` INT)   BEGIN
    INSERT INTO plan_estudio (nombre, id_carrera) VALUES (p_nombre, p_id_carrera);
    SELECT LAST_INSERT_ID() AS id_plan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_semestre` INT)   BEGIN
    INSERT INTO plan_materia (id_plan, id_materia, semestre) VALUES (p_id_plan, p_id_materia, p_semestre);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_materia_req` INT)   BEGIN
    INSERT INTO prerequisito (id_plan, id_materia, id_materia_req) VALUES (p_id_plan, p_id_materia, p_id_materia_req);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) VALUES (p_id_materia, p_id_paralelo, p_id_aula, p_id_horario);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_aula` (IN `p_id_aula` INT)   BEGIN
    DELETE FROM aula WHERE id_aula = p_id_aula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_carrera` (IN `p_id_carrera` INT)   BEGIN
    DELETE FROM carrera WHERE id_carrera = p_id_carrera;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_criterio` (IN `p_id_criterio` INT)   BEGIN
    DELETE FROM criterio_evaluacion WHERE id_criterio = p_id_criterio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_gestion` (IN `p_id_gestion` INT)   BEGIN
    DELETE FROM gestion WHERE id_gestion = p_id_gestion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_horario` (IN `p_id_horario` INT)   BEGIN
    DELETE FROM horario WHERE id_horario = p_id_horario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_materia` (IN `p_id` INT)   BEGIN
    DELETE FROM materia WHERE id_materia = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_nota` (IN `p_id_nota` INT)   BEGIN
    DELETE FROM nota WHERE id_nota = p_id_nota;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    DELETE FROM paralelo WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_plan_estudio` (IN `p_id_plan` INT)   BEGIN
    DELETE FROM plan_estudio WHERE id_plan = p_id_plan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT)   BEGIN
    DELETE FROM plan_materia WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_materia_req` INT)   BEGIN
    DELETE FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_id_materia_req;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    DELETE FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_id_aula AND id_horario = p_id_horario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_aulas` ()   BEGIN
    SELECT * FROM aula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_aula_por_id` (IN `p_id_aula` INT)   BEGIN
    SELECT * FROM aula WHERE id_aula = p_id_aula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_carreras` ()   BEGIN
    SELECT * FROM carrera;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_carrera_por_id` (IN `p_id_carrera` INT)   BEGIN
    SELECT * FROM carrera WHERE id_carrera = p_id_carrera;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_criterios_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    SELECT * FROM criterio_evaluacion WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_gestiones` ()   BEGIN
    SELECT * FROM gestion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_horarios` ()   BEGIN
    SELECT * FROM horario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_horario_por_id` (IN `p_id_horario` INT)   BEGIN
    SELECT * FROM horario WHERE id_horario = p_id_horario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_materias` ()   BEGIN
    SELECT * FROM materia;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_materias_por_plan` (IN `p_id_plan` INT)   BEGIN
    SELECT * FROM plan_materia WHERE id_plan = p_id_plan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_materia_por_id` (IN `p_id` INT)   BEGIN
    SELECT * FROM materia WHERE id_materia = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_notas_detalle` (IN `p_id_detalle` INT)   BEGIN
    SELECT * FROM nota WHERE id_detalle = p_id_detalle;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_paralelos` ()   BEGIN
    SELECT * FROM paralelo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_planes_estudio` ()   BEGIN
    SELECT * FROM plan_estudio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_plan_estudio_por_id` (IN `p_id_plan` INT)   BEGIN
    SELECT * FROM plan_estudio WHERE id_plan = p_id_plan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_plan_materias` ()   BEGIN
    SELECT * FROM plan_materia;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_prerequisitos` ()   BEGIN
    SELECT * FROM prerequisito;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_prerequisitos_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT)   BEGIN
    SELECT * FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_se_cursa` ()   BEGIN
    SELECT * FROM se_cursa;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_se_cursa_por_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    SELECT * FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

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

--
-- Funciones
--
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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `administrativo`
--

CREATE TABLE `administrativo` (
  `id_persona` int(11) NOT NULL,
  `item` varchar(20) NOT NULL,
  `id_carrera` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `administrativo`
--

INSERT INTO `administrativo` (`id_persona`, `item`, `id_carrera`) VALUES
(1, 'ADM-001', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria`
--

CREATE TABLE `auditoria` (
  `id_auditoria` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `accion` varchar(255) NOT NULL,
  `fecha` date NOT NULL,
  `hora` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `aula`
--

CREATE TABLE `aula` (
  `id_aula` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `piso` varchar(20) NOT NULL,
  `ubicacion` varchar(100) NOT NULL,
  `capacidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `aula`
--

INSERT INTO `aula` (`id_aula`, `nombre`, `piso`, `ubicacion`, `capacidad`) VALUES
(1, 'Aula 101', 'Piso 1', 'Pabellón A', 50),
(2, 'Aula 102', 'Piso 1', 'Pabellón A', 50),
(3, 'Lab 1', 'Planta Baja', 'Edificio Central', 30),
(4, 'Lab 2', 'Planta Baja', 'Edificio Central', 30),
(5, 'Auditorio', 'Piso 2', 'Bloque B', 120);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `carrera`
--

CREATE TABLE `carrera` (
  `id_carrera` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `carrera`
--

INSERT INTO `carrera` (`id_carrera`, `nombre`) VALUES
(3, 'Estadística'),
(1, 'Informática'),
(2, 'Ingeniería de Sistemas');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `criterio_evaluacion`
--

CREATE TABLE `criterio_evaluacion` (
  `id_criterio` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `ponderacion` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `criterio_evaluacion`
--
DELIMITER $$
CREATE TRIGGER `trg_validar_ponderacion_criterio` BEFORE INSERT ON `criterio_evaluacion` FOR EACH ROW BEGIN
    DECLARE v_suma_actual FLOAT;
    
    SELECT COALESCE(SUM(ponderacion), 0) INTO v_suma_actual
    FROM criterio_evaluacion
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    
    IF (v_suma_actual + NEW.ponderacion) > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La suma de las ponderaciones no puede superar el 100%.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_inscripcion`
--

CREATE TABLE `detalle_inscripcion` (
  `id_detalle` int(11) NOT NULL,
  `id_inscripcion` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Inscrito',
  `nota_final` float NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `detalle_inscripcion`
--
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
CREATE TRIGGER `trg_decrementar_cupo_actual` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW BEGIN
    UPDATE paralelo
    SET cupo_actual = GREATEST(cupo_actual - 1, 0)
    WHERE id_materia = OLD.id_materia AND id_paralelo = OLD.id_paralelo;
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
DELIMITER $$
CREATE TRIGGER `trg_incrementar_cupo_actual` AFTER INSERT ON `detalle_inscripcion` FOR EACH ROW BEGIN
    UPDATE paralelo
    SET cupo_actual = cupo_actual + 1
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_liberar_cupo_abandono` AFTER UPDATE ON `detalle_inscripcion` FOR EACH ROW BEGIN
    -- Si el estado cambia de 'Inscrito' a 'Abandono', liberamos el cupo
    IF OLD.estado = 'Inscrito' AND NEW.estado = 'Abandono' THEN
        UPDATE PARALELO
        SET cupo_actual = cupo_actual - 1
        WHERE id_materia = NEW.id_materia
        AND id_paralelo = NEW.id_paralelo;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `director_carrera`
--

CREATE TABLE `director_carrera` (
  `id_persona` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `director_carrera`
--

INSERT INTO `director_carrera` (`id_persona`) VALUES
(2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `director_carrera_asignacion`
--

CREATE TABLE `director_carrera_asignacion` (
  `id_persona` int(11) NOT NULL,
  `id_carrera` int(11) NOT NULL,
  `gestion` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `docente`
--

CREATE TABLE `docente` (
  `id_persona` int(11) NOT NULL,
  `registro_docente` varchar(20) NOT NULL,
  `grado_academico` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `docente`
--

INSERT INTO `docente` (`id_persona`, `registro_docente`, `grado_academico`) VALUES
(2, 'DOC-001', 'Ph.D.'),
(3, 'DOC-002', 'M.Sc.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estudiante`
--

CREATE TABLE `estudiante` (
  `id_persona` int(11) NOT NULL,
  `ru` varchar(20) NOT NULL,
  `id_plan` int(11) NOT NULL,
  `anio_ingreso` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `estudiante`
--

INSERT INTO `estudiante` (`id_persona`, `ru`, `id_plan`, `anio_ingreso`) VALUES
(4, '20210458', 1, 2021);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `gestion`
--

CREATE TABLE `gestion` (
  `id_gestion` int(11) NOT NULL,
  `periodo` varchar(20) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Activa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `gestion`
--

INSERT INTO `gestion` (`id_gestion`, `periodo`, `estado`) VALUES
(1, 'I/2026', 'Activa'),
(2, 'II/2026', 'Activa'),
(3, 'Verano/2026', 'Activa');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `horario`
--

CREATE TABLE `horario` (
  `id_horario` int(11) NOT NULL,
  `dia` varchar(15) NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `horario`
--

INSERT INTO `horario` (`id_horario`, `dia`, `hora_inicio`, `hora_fin`) VALUES
(1, 'Lunes', '08:00:00', '10:00:00'),
(2, 'Martes', '10:00:00', '12:00:00'),
(3, 'Miércoles', '08:00:00', '10:00:00'),
(4, 'Jueves', '14:00:00', '16:00:00'),
(5, 'Viernes', '16:00:00', '18:00:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inscripcion`
--

CREATE TABLE `inscripcion` (
  `id_inscripcion` int(11) NOT NULL,
  `id_estudiante` int(11) NOT NULL,
  `id_gestion` int(11) NOT NULL,
  `fecha_registro` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `materia`
--

CREATE TABLE `materia` (
  `id_materia` int(11) NOT NULL,
  `sigla` varchar(15) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `carga_horaria` int(11) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `materia`
--

INSERT INTO `materia` (`id_materia`, `sigla`, `nombre`, `carga_horaria`, `estado`) VALUES
(1, 'INF-111', 'Introducción a la Programación', 80, 'Activo'),
(2, 'INF-112', 'Organización de Computadoras', 80, 'Activo'),
(3, 'INF-113', 'Laboratorio de Computación', 40, 'Activo'),
(4, 'MAT-114', 'Matemática Básica', 80, 'Activo'),
(5, 'LIN-115', 'Lenguaje', 40, 'Activo'),
(6, 'INF-121', 'Algoritmos y Programación', 80, 'Activo'),
(7, 'MAT-122', 'Cálculo I', 80, 'Activo'),
(8, 'SIS-111', 'Teoría de Sistemas', 80, 'Activo'),
(9, 'SIS-121', 'Análisis de Sistemas', 80, 'Activo'),
(10, 'INF-131', 'Estructura de Datos', 80, 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nota`
--

CREATE TABLE `nota` (
  `id_nota` int(11) NOT NULL,
  `id_detalle` int(11) NOT NULL,
  `id_criterio` int(11) NOT NULL,
  `nota_obtenida` float NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `nota`
--
DELIMITER $$
CREATE TRIGGER `trg_bloquear_notas_gestion_cerrada` BEFORE INSERT ON `nota` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `paralelo`
--

CREATE TABLE `paralelo` (
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `nombre` varchar(10) NOT NULL,
  `cupo_maximo` int(11) NOT NULL,
  `cupo_actual` int(11) NOT NULL DEFAULT 0,
  `id_docente` int(11) NOT NULL,
  `id_gestion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `persona`
--

CREATE TABLE `persona` (
  `id_persona` int(11) NOT NULL,
  `ci` varchar(20) NOT NULL,
  `nombres` varchar(80) NOT NULL,
  `apellidos` varchar(80) NOT NULL,
  `fecha_nac` date NOT NULL,
  `sexo` varchar(1) NOT NULL,
  `email` varchar(120) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `persona`
--

INSERT INTO `persona` (`id_persona`, `ci`, `nombres`, `apellidos`, `fecha_nac`, `sexo`, `email`, `estado`) VALUES
(1, '1111111', 'Ana', 'Mamani Quispe', '1985-02-10', 'F', 'admin@uni.edu.bo', 'A'),
(2, '2222222', 'Carlos', 'Condori Ramos', '1980-05-15', 'M', 'director@uni.edu.bo', 'A'),
(3, '3333333', 'María', 'Gómez Vargas', '1988-09-20', 'F', 'docente@uni.edu.bo', 'A'),
(4, '4444444', 'Juan', 'Pérez Ramos', '2002-11-03', 'M', 'estudiante@uni.edu.bo', 'A');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `plan_estudio`
--

CREATE TABLE `plan_estudio` (
  `id_plan` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `id_carrera` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `plan_estudio`
--

INSERT INTO `plan_estudio` (`id_plan`, `nombre`, `id_carrera`) VALUES
(1, 'Plan 2021 - Informática', 1),
(2, 'Plan 2022 - Sistemas', 2),
(3, 'Plan 2015 - Informática', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `plan_materia`
--

CREATE TABLE `plan_materia` (
  `id_plan` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `semestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `plan_materia`
--

INSERT INTO `plan_materia` (`id_plan`, `id_materia`, `semestre`) VALUES
(1, 1, 1),
(1, 2, 1),
(1, 3, 1),
(1, 4, 1),
(1, 5, 1),
(1, 6, 2),
(1, 7, 2),
(2, 8, 1),
(2, 9, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `prerequisito`
--

CREATE TABLE `prerequisito` (
  `id_plan` int(11) NOT NULL,
  `id_materia` int(11) NOT NULL,
  `id_materia_req` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `prerequisito`
--

INSERT INTO `prerequisito` (`id_plan`, `id_materia`, `id_materia_req`) VALUES
(1, 6, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `id_rol` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`id_rol`, `nombre`) VALUES
(1, 'Administrador'),
(2, 'Director'),
(3, 'Docente'),
(4, 'Estudiante');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `se_cursa`
--

CREATE TABLE `se_cursa` (
  `id_materia` int(11) NOT NULL,
  `id_paralelo` int(11) NOT NULL,
  `id_aula` int(11) NOT NULL,
  `id_horario` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id_usuario` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `id_persona` int(11) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id_usuario`, `username`, `password_hash`, `id_persona`, `id_rol`, `estado`) VALUES
(1, 'admin', '$2b$10$Apu8F4a5whB9MI6KcERdMuaoRmjvWkHkbM80r3ed7dxve3ZVImxY.', 1, 1, 'A'),
(2, 'director', '$2b$10$qYh50svv7SVbHh7katOxaegJxrneUGXvl/S6KU03eRH2uy.IVpa8C', 2, 2, 'A'),
(3, 'docente', '$2b$10$Sgu0Ur804KVMuk8rel0WyOmfHeddEh3.q5/JCu0k47zW46qUP14Sy', 3, 3, 'A'),
(4, 'estudiante', '$2b$10$6oKFCpOJqZufw4VBHHMppuZlPossjriLfjpaSRaCJQslEuo50COsa', 4, 4, 'A');

--
-- Disparadores `usuario`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_nuevo_usuario` AFTER INSERT ON `usuario` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, accion, fecha, hora)
    VALUES (NEW.id_usuario, CONCAT('Creación de usuario: ', NEW.username), CURDATE(), CURTIME());
END
$$
DELIMITER ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `administrativo`
--
ALTER TABLE `administrativo`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `item` (`item`),
  ADD KEY `fk_admin_carrera` (`id_carrera`);

--
-- Indices de la tabla `auditoria`
--
ALTER TABLE `auditoria`
  ADD PRIMARY KEY (`id_auditoria`),
  ADD KEY `fk_auditoria_usuario` (`id_usuario`);

--
-- Indices de la tabla `aula`
--
ALTER TABLE `aula`
  ADD PRIMARY KEY (`id_aula`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `carrera`
--
ALTER TABLE `carrera`
  ADD PRIMARY KEY (`id_carrera`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `criterio_evaluacion`
--
ALTER TABLE `criterio_evaluacion`
  ADD PRIMARY KEY (`id_criterio`),
  ADD KEY `fk_criterio_paralelo` (`id_materia`,`id_paralelo`);

--
-- Indices de la tabla `detalle_inscripcion`
--
ALTER TABLE `detalle_inscripcion`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `fk_detalle_inscripcion_cabecera` (`id_inscripcion`),
  ADD KEY `fk_detalle_paralelo` (`id_materia`,`id_paralelo`);

--
-- Indices de la tabla `director_carrera`
--
ALTER TABLE `director_carrera`
  ADD PRIMARY KEY (`id_persona`);

--
-- Indices de la tabla `director_carrera_asignacion`
--
ALTER TABLE `director_carrera_asignacion`
  ADD PRIMARY KEY (`id_persona`,`id_carrera`),
  ADD KEY `fk_asignacion_carrera` (`id_carrera`);

--
-- Indices de la tabla `docente`
--
ALTER TABLE `docente`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `registro_docente` (`registro_docente`);

--
-- Indices de la tabla `estudiante`
--
ALTER TABLE `estudiante`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `ru` (`ru`),
  ADD KEY `fk_estudiante_plan` (`id_plan`);

--
-- Indices de la tabla `gestion`
--
ALTER TABLE `gestion`
  ADD PRIMARY KEY (`id_gestion`),
  ADD UNIQUE KEY `periodo` (`periodo`);

--
-- Indices de la tabla `horario`
--
ALTER TABLE `horario`
  ADD PRIMARY KEY (`id_horario`);

--
-- Indices de la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  ADD PRIMARY KEY (`id_inscripcion`),
  ADD KEY `fk_inscripcion_estudiante` (`id_estudiante`),
  ADD KEY `fk_inscripcion_gestion` (`id_gestion`);

--
-- Indices de la tabla `materia`
--
ALTER TABLE `materia`
  ADD PRIMARY KEY (`id_materia`),
  ADD UNIQUE KEY `sigla` (`sigla`);

--
-- Indices de la tabla `nota`
--
ALTER TABLE `nota`
  ADD PRIMARY KEY (`id_nota`),
  ADD KEY `fk_nota_detalle` (`id_detalle`),
  ADD KEY `fk_nota_criterio` (`id_criterio`);

--
-- Indices de la tabla `paralelo`
--
ALTER TABLE `paralelo`
  ADD PRIMARY KEY (`id_materia`,`id_paralelo`),
  ADD KEY `fk_paralelo_docente` (`id_docente`),
  ADD KEY `fk_paralelo_gestion` (`id_gestion`);

--
-- Indices de la tabla `persona`
--
ALTER TABLE `persona`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `ci` (`ci`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indices de la tabla `plan_estudio`
--
ALTER TABLE `plan_estudio`
  ADD PRIMARY KEY (`id_plan`),
  ADD KEY `fk_plan_carrera` (`id_carrera`);

--
-- Indices de la tabla `plan_materia`
--
ALTER TABLE `plan_materia`
  ADD PRIMARY KEY (`id_plan`,`id_materia`),
  ADD KEY `fk_planmateria_materia` (`id_materia`);

--
-- Indices de la tabla `prerequisito`
--
ALTER TABLE `prerequisito`
  ADD PRIMARY KEY (`id_plan`,`id_materia`,`id_materia_req`),
  ADD KEY `fk_prereq_materia_req` (`id_plan`,`id_materia_req`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`id_rol`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `se_cursa`
--
ALTER TABLE `se_cursa`
  ADD PRIMARY KEY (`id_materia`,`id_paralelo`,`id_aula`,`id_horario`),
  ADD KEY `fk_secursa_aula` (`id_aula`),
  ADD KEY `fk_secursa_horario` (`id_horario`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `id_persona` (`id_persona`),
  ADD KEY `fk_usuario_rol` (`id_rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoria`
--
ALTER TABLE `auditoria`
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `aula`
--
ALTER TABLE `aula`
  MODIFY `id_aula` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `carrera`
--
ALTER TABLE `carrera`
  MODIFY `id_carrera` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `criterio_evaluacion`
--
ALTER TABLE `criterio_evaluacion`
  MODIFY `id_criterio` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_inscripcion`
--
ALTER TABLE `detalle_inscripcion`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `gestion`
--
ALTER TABLE `gestion`
  MODIFY `id_gestion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `horario`
--
ALTER TABLE `horario`
  MODIFY `id_horario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  MODIFY `id_inscripcion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `materia`
--
ALTER TABLE `materia`
  MODIFY `id_materia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `nota`
--
ALTER TABLE `nota`
  MODIFY `id_nota` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `persona`
--
ALTER TABLE `persona`
  MODIFY `id_persona` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `plan_estudio`
--
ALTER TABLE `plan_estudio`
  MODIFY `id_plan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `administrativo`
--
ALTER TABLE `administrativo`
  ADD CONSTRAINT `fk_admin_carrera` FOREIGN KEY (`id_carrera`) REFERENCES `carrera` (`id_carrera`),
  ADD CONSTRAINT `fk_admin_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`);

--
-- Filtros para la tabla `auditoria`
--
ALTER TABLE `auditoria`
  ADD CONSTRAINT `fk_auditoria_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `criterio_evaluacion`
--
ALTER TABLE `criterio_evaluacion`
  ADD CONSTRAINT `fk_criterio_paralelo` FOREIGN KEY (`id_materia`,`id_paralelo`) REFERENCES `paralelo` (`id_materia`, `id_paralelo`);

--
-- Filtros para la tabla `detalle_inscripcion`
--
ALTER TABLE `detalle_inscripcion`
  ADD CONSTRAINT `fk_detalle_inscripcion_cabecera` FOREIGN KEY (`id_inscripcion`) REFERENCES `inscripcion` (`id_inscripcion`),
  ADD CONSTRAINT `fk_detalle_paralelo` FOREIGN KEY (`id_materia`,`id_paralelo`) REFERENCES `paralelo` (`id_materia`, `id_paralelo`);

--
-- Filtros para la tabla `director_carrera`
--
ALTER TABLE `director_carrera`
  ADD CONSTRAINT `fk_director_docente` FOREIGN KEY (`id_persona`) REFERENCES `docente` (`id_persona`);

--
-- Filtros para la tabla `director_carrera_asignacion`
--
ALTER TABLE `director_carrera_asignacion`
  ADD CONSTRAINT `fk_asignacion_carrera` FOREIGN KEY (`id_carrera`) REFERENCES `carrera` (`id_carrera`),
  ADD CONSTRAINT `fk_asignacion_director` FOREIGN KEY (`id_persona`) REFERENCES `director_carrera` (`id_persona`);

--
-- Filtros para la tabla `docente`
--
ALTER TABLE `docente`
  ADD CONSTRAINT `fk_docente_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`);

--
-- Filtros para la tabla `estudiante`
--
ALTER TABLE `estudiante`
  ADD CONSTRAINT `fk_estudiante_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`),
  ADD CONSTRAINT `fk_estudiante_plan` FOREIGN KEY (`id_plan`) REFERENCES `plan_estudio` (`id_plan`);

--
-- Filtros para la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  ADD CONSTRAINT `fk_inscripcion_estudiante` FOREIGN KEY (`id_estudiante`) REFERENCES `estudiante` (`id_persona`),
  ADD CONSTRAINT `fk_inscripcion_gestion` FOREIGN KEY (`id_gestion`) REFERENCES `gestion` (`id_gestion`);

--
-- Filtros para la tabla `nota`
--
ALTER TABLE `nota`
  ADD CONSTRAINT `fk_nota_criterio` FOREIGN KEY (`id_criterio`) REFERENCES `criterio_evaluacion` (`id_criterio`),
  ADD CONSTRAINT `fk_nota_detalle` FOREIGN KEY (`id_detalle`) REFERENCES `detalle_inscripcion` (`id_detalle`);

--
-- Filtros para la tabla `paralelo`
--
ALTER TABLE `paralelo`
  ADD CONSTRAINT `fk_paralelo_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_persona`),
  ADD CONSTRAINT `fk_paralelo_gestion` FOREIGN KEY (`id_gestion`) REFERENCES `gestion` (`id_gestion`),
  ADD CONSTRAINT `fk_paralelo_materia` FOREIGN KEY (`id_materia`) REFERENCES `materia` (`id_materia`);

--
-- Filtros para la tabla `plan_estudio`
--
ALTER TABLE `plan_estudio`
  ADD CONSTRAINT `fk_plan_carrera` FOREIGN KEY (`id_carrera`) REFERENCES `carrera` (`id_carrera`);

--
-- Filtros para la tabla `plan_materia`
--
ALTER TABLE `plan_materia`
  ADD CONSTRAINT `fk_planmateria_materia` FOREIGN KEY (`id_materia`) REFERENCES `materia` (`id_materia`),
  ADD CONSTRAINT `fk_planmateria_plan` FOREIGN KEY (`id_plan`) REFERENCES `plan_estudio` (`id_plan`);

--
-- Filtros para la tabla `prerequisito`
--
ALTER TABLE `prerequisito`
  ADD CONSTRAINT `fk_prereq_materia_actual` FOREIGN KEY (`id_plan`,`id_materia`) REFERENCES `plan_materia` (`id_plan`, `id_materia`),
  ADD CONSTRAINT `fk_prereq_materia_req` FOREIGN KEY (`id_plan`,`id_materia_req`) REFERENCES `plan_materia` (`id_plan`, `id_materia`);

--
-- Filtros para la tabla `se_cursa`
--
ALTER TABLE `se_cursa`
  ADD CONSTRAINT `fk_secursa_aula` FOREIGN KEY (`id_aula`) REFERENCES `aula` (`id_aula`),
  ADD CONSTRAINT `fk_secursa_horario` FOREIGN KEY (`id_horario`) REFERENCES `horario` (`id_horario`),
  ADD CONSTRAINT `fk_secursa_paralelo` FOREIGN KEY (`id_materia`,`id_paralelo`) REFERENCES `paralelo` (`id_materia`, `id_paralelo`);

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `fk_usuario_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`),
  ADD CONSTRAINT `fk_usuario_rol` FOREIGN KEY (`id_rol`) REFERENCES `rol` (`id_rol`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
