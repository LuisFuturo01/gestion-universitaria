-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 26-07-2026 a las 09:49:06
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_gestion` (IN `p_id_gestion` INT)   BEGIN
    DECLARE v_estado_gestion VARCHAR(20);
    DECLARE v_total_afectados INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;
    DECLARE v_reprobados INT DEFAULT 0;

    -- Manejador de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Verificar que la gestión existe y está activa
    SELECT estado INTO v_estado_gestion
    FROM gestion
    WHERE id_gestion = p_id_gestion;

    IF v_estado_gestion IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión no existe.';
    END IF;

    IF v_estado_gestion = 'Cerrada' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión ya está cerrada.';
    END IF;

    -- Actualizar nota_final y estado en detalle_inscripcion
    UPDATE detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    LEFT JOIN (
        SELECT 
            n.id_detalle,
            SUM(n.nota_obtenida * ce.ponderacion / 100) AS nota_calculada
        FROM nota n
        JOIN criterio_evaluacion ce ON n.id_criterio = ce.id_criterio
        GROUP BY n.id_detalle
    ) AS calculo ON di.id_detalle = calculo.id_detalle
    SET 
        di.nota_final = COALESCE(calculo.nota_calculada, 0),
        di.estado = CASE 
            WHEN COALESCE(calculo.nota_calculada, 0) >= 51 THEN 'Aprobado'
            ELSE 'Reprobado'
        END
    WHERE i.id_gestion = p_id_gestion
      AND di.estado = 'Inscrito';

    -- Contar afectados
    SELECT ROW_COUNT() INTO v_total_afectados;

    -- Contar aprobados y reprobados
    SELECT 
        COALESCE(SUM(CASE WHEN di.estado = 'Aprobado' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN di.estado = 'Reprobado' THEN 1 ELSE 0 END), 0)
    INTO v_aprobados, v_reprobados
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    WHERE i.id_gestion = p_id_gestion
      AND (di.estado = 'Aprobado' OR di.estado = 'Reprobado');

    -- Cambiar estado de la gestión a Cerrada
    UPDATE gestion 
    SET estado = 'Cerrada' 
    WHERE id_gestion = p_id_gestion;

    COMMIT;

    -- Devolver resumen final
    SELECT 
        g.periodo AS periodo,
        v_total_afectados AS total_procesados,
        v_aprobados AS aprobados,
        v_reprobados AS reprobados,
        'Cerrada' AS nuevo_estado
    FROM gestion g
    WHERE g.id_gestion = p_id_gestion;

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_preview_cierre_gestion` (IN `p_id_gestion` INT)   BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;
    DECLARE v_reprobados INT DEFAULT 0;
    DECLARE v_periodo VARCHAR(20);

    -- Verificar que la gestión existe
    SELECT periodo INTO v_periodo
    FROM gestion
    WHERE id_gestion = p_id_gestion;

    IF v_periodo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión no existe.';
    END IF;

    -- Calcular totales
    SELECT COUNT(*),
           COALESCE(SUM(CASE WHEN nota_proyectada >= 51 THEN 1 ELSE 0 END), 0),
           COALESCE(SUM(CASE WHEN nota_proyectada < 51 THEN 1 ELSE 0 END), 0)
    INTO v_total, v_aprobados, v_reprobados
    FROM (
        SELECT 
            di.id_detalle,
            COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) AS nota_proyectada
        FROM detalle_inscripcion di
        JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
        JOIN gestion g ON i.id_gestion = g.id_gestion
        LEFT JOIN criterio_evaluacion ce 
            ON di.id_materia = ce.id_materia 
            AND di.id_paralelo = ce.id_paralelo
        LEFT JOIN nota n 
            ON di.id_detalle = n.id_detalle 
            AND ce.id_criterio = n.id_criterio
        WHERE i.id_gestion = p_id_gestion
          AND di.estado = 'Inscrito'
          AND g.estado = 'Activa'
        GROUP BY di.id_detalle
    ) AS t;

    -- Devolver resumen
    SELECT 
        v_periodo AS periodo,
        v_total AS total,
        v_aprobados AS aprobados,
        v_reprobados AS reprobados;

    -- Devolver detalle por estudiante
    SELECT 
        CONCAT(p.nombres, ' ', p.apellidos) AS estudiante,
        e.ru AS ru,
        m.sigla AS sigla_materia,
        m.nombre AS materia,
        COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) AS nota_final_proyectada,
        CASE 
            WHEN COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) >= 51 THEN 'Aprobado'
            ELSE 'Reprobado'
        END AS estado_proyectado
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    JOIN gestion g ON i.id_gestion = g.id_gestion
    JOIN estudiante e ON i.id_estudiante = e.id_persona
    JOIN persona p ON e.id_persona = p.id_persona
    JOIN materia m ON di.id_materia = m.id_materia
    LEFT JOIN criterio_evaluacion ce 
        ON di.id_materia = ce.id_materia 
        AND di.id_paralelo = ce.id_paralelo
    LEFT JOIN nota n 
        ON di.id_detalle = n.id_detalle 
        AND ce.id_criterio = n.id_criterio
    WHERE i.id_gestion = p_id_gestion
      AND di.estado = 'Inscrito'
      AND g.estado = 'Activa'
    GROUP BY di.id_detalle, p.nombres, p.apellidos, e.ru, m.sigla, m.nombre
    ORDER BY p.apellidos, p.nombres, m.nombre;

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
(2, 'CIENCIAS DE LA COMUNICACIÓN'),
(1, 'INFORMÁTICA');

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
(1, 'INF-111', 'Programación I', 80, 'Activo'),
(2, 'INF-112', 'Fundamentos digitales', 80, 'Activo'),
(3, 'INF-113', 'Programación web I', 80, 'Activo'),
(4, 'INF-114', 'Algebra', 80, 'Activo'),
(5, 'INF-115', 'Calculo I', 80, 'Activo'),
(6, 'INF-117', 'Matemática discreta', 80, 'Activo'),
(7, 'INF-121', 'Programación II', 80, 'Activo'),
(8, 'INF-122', 'Programación web II', 80, 'Activo'),
(9, 'INF-123', 'Electrónica general I', 80, 'Activo'),
(10, 'INF-124', 'Estadística I', 80, 'Activo'),
(11, 'INF-125', 'Algebra lineal', 80, 'Activo'),
(12, 'INF-126', 'Cálculo II', 80, 'Activo'),
(13, 'INF-131', 'Programación III', 80, 'Activo'),
(14, 'INF-132', 'Base de datos I', 80, 'Activo'),
(15, 'INF-133', 'Programación web III', 80, 'Activo'),
(16, 'INF-134', 'Estadistica II', 80, 'Activo'),
(17, 'INF-135', 'Sistemas Operativos', 80, 'Activo'),
(18, 'TRA-136', 'Metodologia de la investigación', 80, 'Activo'),
(19, 'INF-241', 'Análisis y diseño de sistemas I', 80, 'Activo'),
(20, 'INF-242', 'Redes I', 80, 'Activo'),
(21, 'INF-243', 'Investigación Operativa I', 80, 'Activo'),
(22, 'INF-251', 'Ingeniería de software I', 80, 'Activo'),
(23, 'TRA-256', 'Legislación informática y ética', 80, 'Activo'),
(24, 'INF-265', 'Seguridad de la Información', 80, 'Activo'),
(25, 'INF-266', 'Taller de Técnico Superior', 80, 'Activo'),
(26, 'TRA-374', 'Práctica profesional', 80, 'Activo'),
(27, 'INF-384', 'Taller de graduación I', 80, 'Activo'),
(28, 'INF-391', 'Taller de graduación II', 80, 'Activo'),
(29, 'INF-116', 'Fisica', 80, 'Activo'),
(30, 'INF-244', 'Introducción a la Robótica', 80, 'Activo'),
(31, 'INF-245', 'Programación de dispositivos móviles I', 80, 'Activo'),
(32, 'INF-246', 'Fundamentos de diseño y animación', 80, 'Activo'),
(33, 'INF-252', 'Base de datos II', 80, 'Activo'),
(34, 'INF-253', 'Análisis y diseño de sistemas II', 80, 'Activo'),
(35, 'INF-254', 'Programación de dispositivos móviles II', 80, 'Activo'),
(36, 'INF-261', 'Ingeniería de Software II', 80, 'Activo'),
(37, 'INF-262', 'Base de Datos III', 80, 'Activo'),
(38, 'INF-263', 'Desarrollo de aplicaciones multimedia', 80, 'Activo'),
(39, 'INF-264', 'Emprendimiento e innovación tecnológica', 80, 'Activo'),
(40, 'INF-371', 'Seguridad de la información', 80, 'Activo'),
(41, 'INF-372', 'Inteligencia Artificial', 80, 'Activo'),
(42, 'INF-373', 'Métodos numéricos I', 80, 'Activo'),
(43, 'INF-381', 'Simulación de sistemas', 80, 'Activo'),
(44, 'INF-382', 'Ingeniería de software III', 80, 'Activo'),
(45, 'COM-244', 'Reconocimiento de patrones', 80, 'Activo'),
(46, 'COM-245', 'Lógica para la Ciencia de la Computación', 80, 'Activo'),
(47, 'INF-247', 'Calculo III', 80, 'Activo'),
(48, 'COM-252', 'Inteligencia artificial', 80, 'Activo'),
(49, 'COM-253', 'Criptografia I', 80, 'Activo'),
(50, 'COM-254', 'Métodos numéricos I', 80, 'Activo'),
(51, 'COM-261', 'Lenguajes Formales y autómatas', 80, 'Activo'),
(52, 'COM-262', 'Compiladores', 80, 'Activo'),
(53, 'COM-263', 'Computación paralela', 80, 'Activo'),
(54, 'COM-371', 'Simulación de Sistemas', 80, 'Activo'),
(55, 'COM-372', 'Arquitectura orientada a servicios', 80, 'Activo'),
(56, 'COM-381', 'Interacción Humano-Computador', 80, 'Activo'),
(57, 'COM-382', 'Web semántica', 80, 'Activo'),
(58, 'IID-135', 'Electrónica general II', 80, 'Activo'),
(59, 'IID-246', 'Electrónica industrial', 80, 'Activo'),
(60, 'IID-247', 'Cálculo III', 80, 'Activo'),
(61, 'IID-251', 'Sistemas de control', 80, 'Activo'),
(62, 'IID-252', 'Microcontroladores', 80, 'Activo'),
(63, 'IID-253', 'Aplicaciones informáticas industriales', 80, 'Activo'),
(64, 'IID-254', 'Controladores lógico programables', 80, 'Activo'),
(65, 'IID-261', 'Simulación de sistemas', 80, 'Activo'),
(66, 'IID-262', 'Robótica industrial', 80, 'Activo'),
(67, 'IID-263', 'Internet de las cosas', 80, 'Activo'),
(68, 'IID-264', 'Ingeniería de software I', 80, 'Activo'),
(69, 'IID-265', 'Redes industriales', 80, 'Activo'),
(70, 'IID-371', 'Gestión de proyectos industriales', 80, 'Activo'),
(71, 'IID-372', 'Automatización industrial', 80, 'Activo'),
(72, 'IID-381', 'Automatización de sistemas y procesos', 80, 'Activo'),
(73, 'IID-382', 'Gestión de la seguridad', 80, 'Activo'),
(74, 'SIS-245', 'Sistemas de información', 80, 'Activo'),
(75, 'SIS-246', 'Ingeniería de sistemas', 80, 'Activo'),
(76, 'SEG-252', 'Redes II', 80, 'Activo'),
(77, 'SIS-253', 'Preparación y evaluación de proyectos', 80, 'Activo'),
(78, 'SIS-255', 'Comercio electrónico y marketing digital', 80, 'Activo'),
(79, 'SIS-262', 'Dinámica de sistemas', 80, 'Activo'),
(80, 'SIS-263', 'Sistemas de gestión empresarial', 80, 'Activo'),
(81, 'SIS-371', 'Sistemas distribuidos', 80, 'Activo'),
(82, 'SIS-372', 'Computación en la nube', 80, 'Activo'),
(83, 'SIS-373', 'Organización y métodos', 80, 'Activo'),
(84, 'SIS-382', 'Auditoria de sistemas', 80, 'Activo'),
(85, 'DAT-135', 'Calculo III', 80, 'Activo'),
(86, 'DAT-241', 'Programación distribuida y paralela', 80, 'Activo'),
(87, 'DAT-242', 'Métodos numéricos I', 80, 'Activo'),
(88, 'DAT-245', 'Inteligencia artificial', 80, 'Activo'),
(89, 'DAT-246', 'Modelación estadística', 80, 'Activo'),
(90, 'DAT-251', 'Base de Datos III', 80, 'Activo'),
(91, 'DAT-252', 'Métodos numéricos II', 80, 'Activo'),
(92, 'DAT-253', 'Minería de Datos (Data Mining)', 80, 'Activo'),
(93, 'DAT-254', 'Investigación Operativa II', 80, 'Activo'),
(94, 'DAT-255', 'Aprendizaje automático (Machine Learning)', 80, 'Activo'),
(95, 'DAT-261', 'Procesamiento del Lenguaje Natural', 80, 'Activo'),
(96, 'DAT-262', 'Procesos estocásticos y análisis de series', 80, 'Activo'),
(97, 'DAT-263', 'Análisis de datos', 80, 'Activo'),
(98, 'DAT-264', 'Aprendizaje profundo (Deep Learning)', 80, 'Activo'),
(99, 'DAT-371', 'Inteligencia de negocios (BI)', 80, 'Activo'),
(100, 'DAT-381', 'Macrodatos y analitica de datos (Big Data)', 80, 'Activo'),
(101, 'DAT-382', 'Visualización de datos', 80, 'Activo'),
(102, 'TIC-135', 'Introducción a las redes', 80, 'Activo'),
(103, 'TIC-246', 'Sistemas Operativos', 80, 'Activo'),
(104, 'TIC-247', 'Laboratorio de redes', 80, 'Activo'),
(105, 'TIC-251', 'Aplicaciones y servicios multimedia', 80, 'Activo'),
(106, 'TIC-253', 'Dirección de proyectos informáticos', 80, 'Activo'),
(107, 'TIC-254', 'Redes inalámbricas', 80, 'Activo'),
(108, 'TIC-255', 'Aplicaciones y servicios TIC', 80, 'Activo'),
(109, 'TIC-261', 'Centro de datos (Data Center)', 80, 'Activo'),
(110, 'TIC-262', 'Sistemas de gestión de Red', 80, 'Activo'),
(111, 'TIC-263', 'Redes de Comunicación', 80, 'Activo'),
(112, 'TIC-371', 'Ingenieria de software I', 80, 'Activo'),
(113, 'TIC-372', 'Seguridad de Redes I', 80, 'Activo'),
(114, 'TIC-373', 'Redes de comunicación II', 80, 'Activo'),
(115, 'TIC-381', 'Administración de centros de datos y de red', 80, 'Activo'),
(116, 'TIC-382', 'Seguridad de Redes II', 80, 'Activo'),
(117, 'TIC-383', 'Redes de comunicación III', 80, 'Activo'),
(118, 'SEG-244', 'Seguridad de la Información', 80, 'Activo'),
(119, 'SEG-246', 'Criptografia I', 80, 'Activo'),
(120, 'SEG-253', 'Seguridad en Base de datos', 80, 'Activo'),
(121, 'SEG-254', 'Criptografia II', 80, 'Activo'),
(122, 'SEG-261', 'Hacking ético I', 80, 'Activo'),
(123, 'SEG-262', 'Seguridad de Redes I', 80, 'Activo'),
(124, 'SEG-263', 'Software malicioso', 80, 'Activo'),
(125, 'SEG-264', 'Redes inalámbricas', 80, 'Activo'),
(126, 'SEG-371', 'Gestión de incidentes y continuidad', 80, 'Activo'),
(127, 'SEG-372', 'Seguridad de Redes II', 80, 'Activo'),
(128, 'SEG-373', 'Informática forense', 80, 'Activo'),
(129, 'SEG-381', 'Gestión de Riesgos en Seguridad', 80, 'Activo'),
(130, 'SEG-383', 'Gestión de activos de información', 80, 'Activo'),
(131, 'COMU-111', 'Teoría de la Comunicación I', 80, 'Activo'),
(132, 'COMU-112', 'Taller de Redacción I', 80, 'Activo'),
(133, 'COMU-113', 'Fotografía Básica', 80, 'Activo'),
(134, 'COMU-114', 'Historia de los Medios', 80, 'Activo'),
(135, 'COMU-115', 'Sociología', 80, 'Activo'),
(136, 'COMU-116', 'Lenguaje y Gramática', 80, 'Activo'),
(137, 'COMU-121', 'Teoría de la Comunicación II', 80, 'Activo'),
(138, 'COMU-122', 'Taller de Redacción II', 80, 'Activo'),
(139, 'COMU-123', 'Lenguaje Audiovisual', 80, 'Activo'),
(140, 'COMU-124', 'Semiótica', 80, 'Activo'),
(141, 'COMU-125', 'Antropología', 80, 'Activo'),
(142, 'COMU-126', 'Psicología de la Comunicación', 80, 'Activo'),
(143, 'COMU-131', 'Metodología de la Investigación', 80, 'Activo'),
(144, 'COMU-132', 'Ética Periodística', 80, 'Activo'),
(145, 'COMU-133', 'Taller de Radio', 80, 'Activo'),
(146, 'COMU-134', 'Diseño Gráfico', 80, 'Activo'),
(147, 'COMU-135', 'Relaciones Públicas Básicas', 80, 'Activo'),
(148, 'COMU-136', 'Economía Política', 80, 'Activo'),
(149, 'COMU-241', 'Legislación de Medios', 80, 'Activo'),
(150, 'COMU-242', 'Taller de Televisión', 80, 'Activo'),
(151, 'COMU-243', 'Periodismo Informativo', 80, 'Activo'),
(152, 'COMU-244', 'Estadística para Ciencias Sociales', 80, 'Activo'),
(153, 'COMU-245', 'Publicidad', 80, 'Activo'),
(154, 'COMU-246', 'Opinión Pública', 80, 'Activo'),
(155, 'COMU-251', 'Periodismo Interpretativo', 80, 'Activo'),
(156, 'COMU-252', 'Marketing Básico', 80, 'Activo'),
(157, 'COMU-253', 'Comunicación Organizacional Básica', 80, 'Activo'),
(158, 'COMU-254', 'Proyectos de Comunicación', 80, 'Activo'),
(159, 'COMU-255', 'Comunicación y Cultura', 80, 'Activo'),
(160, 'COMU-256', 'Electiva I', 80, 'Activo'),
(161, 'COMU-384', 'Práctica Profesional', 80, 'Activo'),
(162, 'COMU-385', 'Taller de Graduación I', 80, 'Activo'),
(163, 'COMU-391', 'Taller de Graduación II', 80, 'Activo'),
(164, 'PER-261', 'Periodismo de Datos', 80, 'Activo'),
(165, 'PER-262', 'Gestión de Redes Sociales', 80, 'Activo'),
(166, 'PER-263', 'Edición Digital', 80, 'Activo'),
(167, 'PER-264', 'Periodismo de Investigación', 80, 'Activo'),
(168, 'PER-265', 'Taller Multimedia I', 80, 'Activo'),
(169, 'PER-371', 'Ciberperiodismo', 80, 'Activo'),
(170, 'PER-372', 'Diseño de Interfaces (UI/UX)', 80, 'Activo'),
(171, 'PER-373', 'Narrativas Transmedia', 80, 'Activo'),
(172, 'PER-374', 'Producción de Podcast', 80, 'Activo'),
(173, 'PER-375', 'Taller Multimedia II', 80, 'Activo'),
(174, 'PER-381', 'Periodismo Especializado', 80, 'Activo'),
(175, 'PER-382', 'Analítica Web', 80, 'Activo'),
(176, 'PER-383', 'Emprendimiento en Medios', 80, 'Activo'),
(177, 'AUD-261', 'Guion Cinematográfico', 80, 'Activo'),
(178, 'AUD-262', 'Producción de TV I', 80, 'Activo'),
(179, 'AUD-263', 'Dirección de Fotografía', 80, 'Activo'),
(180, 'AUD-264', 'Sonido y Musicalización', 80, 'Activo'),
(181, 'AUD-265', 'Historia del Cine', 80, 'Activo'),
(182, 'AUD-371', 'Edición y Postproducción', 80, 'Activo'),
(183, 'AUD-372', 'Producción de TV II', 80, 'Activo'),
(184, 'AUD-373', 'Dirección de Cine', 80, 'Activo'),
(185, 'AUD-374', 'Cine Documental', 80, 'Activo'),
(186, 'AUD-375', 'Animación Básica', 80, 'Activo'),
(187, 'AUD-381', 'Realización Cinematográfica', 80, 'Activo'),
(188, 'AUD-382', 'Crítica de Cine', 80, 'Activo'),
(189, 'AUD-383', 'Distribución Audiovisual', 80, 'Activo'),
(190, 'RRPP-261', 'Comunicación Organizacional Avanzada', 80, 'Activo'),
(191, 'RRPP-262', 'Relaciones Públicas Estratégicas', 80, 'Activo'),
(192, 'RRPP-263', 'Identidad Corporativa', 80, 'Activo'),
(193, 'RRPP-264', 'Protocolo y Eventos', 80, 'Activo'),
(194, 'RRPP-265', 'Comunicación Interna', 80, 'Activo'),
(195, 'RRPP-371', 'Gestión de Crisis y Reputación', 80, 'Activo'),
(196, 'RRPP-372', 'Marketing Político', 80, 'Activo'),
(197, 'RRPP-373', 'Responsabilidad Social Empresarial', 80, 'Activo'),
(198, 'RRPP-374', 'Media Training', 80, 'Activo'),
(199, 'RRPP-375', 'Asuntos Públicos (Lobby)', 80, 'Activo'),
(200, 'RRPP-381', 'Auditoría de Comunicación', 80, 'Activo'),
(201, 'RRPP-382', 'Campañas de RRPP', 80, 'Activo'),
(202, 'RRPP-383', 'Negociación y Resolución de Conflictos', 80, 'Activo'),
(203, 'COM-311', 'Sistemas estocásticos', 80, 'Activo'),
(204, 'COM-312', 'Programación Lógica', 80, 'Activo'),
(205, 'COM-313', 'Sistemas expertos', 80, 'Activo'),
(206, 'INF-314', 'Inglés técnico', 80, 'Activo'),
(207, 'INF-315', 'Preparación y evaluación de proyectos', 80, 'Activo'),
(208, 'COM-316', 'Procesamiento del lenguaje natural', 80, 'Activo'),
(209, 'COM-317', 'Geometría computacional', 80, 'Activo'),
(210, 'INF-318', 'Computación en la nube', 80, 'Activo'),
(211, 'INF-333', 'Redes II', 80, 'Activo'),
(212, 'COM-320', 'Especificación formal y verificación', 80, 'Activo'),
(213, 'COM-321', 'Sistemas Inteligentes', 80, 'Activo'),
(214, 'COM-322', 'Base de datos II', 80, 'Activo'),
(215, 'COM-323', 'Computabilidad y complejidad algorítmica', 80, 'Activo'),
(216, 'INF-324', 'Aprendizaje Profundo (Deep learning)', 80, 'Activo'),
(217, 'INF-331', 'Investigación operativa II', 80, 'Activo'),
(218, 'INF-336', 'Visión Artificial y manejo de imágenes', 80, 'Activo'),
(219, 'INF-311', 'Minería de datos (Data Mining)', 80, 'Activo'),
(220, 'INF-312', 'Bioinformática', 80, 'Activo'),
(221, 'INF-313', 'Realidad aumentada y virtual', 80, 'Activo'),
(222, 'INF-316', 'Informática Forense', 80, 'Activo'),
(223, 'INF-317', 'Internet de las cosas', 80, 'Activo'),
(224, 'INF-319', 'Programación a bajo nivel', 80, 'Activo'),
(225, 'INF-320', 'Auditoria de sistemas', 80, 'Activo'),
(226, 'INF-321', 'Cálculo III', 80, 'Activo'),
(227, 'INF-322', 'Macrodatos y analitica de datos (Big Data)', 80, 'Activo'),
(228, 'INF-323', 'Aprendizaje automático (Machine learning)', 80, 'Activo'),
(229, 'INF-325', 'Derecho informático', 80, 'Activo'),
(230, 'INF-326', 'Negociaciones y Toma de Decisiones', 80, 'Activo'),
(231, 'INF-327', 'Inteligencia de negocios (Bussines Intelligence)', 80, 'Activo'),
(232, 'INF-328', 'Visión por computadora', 80, 'Activo'),
(233, 'INF-329', 'Procesamiento digital de imágenes', 80, 'Activo'),
(234, 'INF-330', 'Informática Médica', 80, 'Activo'),
(235, 'INF-332', 'Hacking ético I', 80, 'Activo'),
(236, 'INF-334', 'Dirección de proyectos informáticos', 80, 'Activo'),
(237, 'IID-311', 'Programación de dispositivos móviles II', 80, 'Activo'),
(238, 'IID-312', 'Comunicaciones por satélite', 80, 'Activo'),
(239, 'IID-313', 'Sistemas avanzados de comunicaciones', 80, 'Activo'),
(240, 'IID-316', 'Lenguajes formales y autómatas', 80, 'Activo'),
(241, 'IID-317', 'Instrumentación de procesos para la industria minera', 80, 'Activo'),
(242, 'IID-320', 'Sistemas Hidráulicos y Neumáticos de Potencia', 80, 'Activo'),
(243, 'INF-335', 'Inteligencia artificial', 80, 'Activo'),
(244, 'SIS-313', 'Datawarehouse', 80, 'Activo'),
(245, 'SIS-315', 'Teoría General de sistemas', 80, 'Activo'),
(246, 'SIS-318', 'Ciberseguridad', 80, 'Activo'),
(247, 'SIS-320', 'Sistemas de Información Geográfica', 80, 'Activo'),
(248, 'SIS-324', 'Programación distribuida y paralela', 80, 'Activo'),
(249, 'SIS-325', 'Sistemas contables', 80, 'Activo'),
(250, 'SIS-328', 'Sistemas económicos', 80, 'Activo'),
(251, 'DAT-311', 'Cálculo IV', 80, 'Activo'),
(252, 'DAT-312', 'Modelos Generativos', 80, 'Activo'),
(253, 'DAT-313', 'Comercio electrónico y Marketing Digital', 80, 'Activo'),
(254, 'DAT-318', 'Simulación de sistemas', 80, 'Activo'),
(255, 'DAT-319', 'Programación de dispositivos móviles I', 80, 'Activo'),
(256, 'DAT-321', 'Seguridad de la Información', 80, 'Activo'),
(257, 'INF-337', 'Emprendimiento e innovación tecnológica', 80, 'Activo'),
(258, 'TIC-311', 'Sistemas embebidos', 80, 'Activo'),
(259, 'TIC-312', 'Administración de servidores', 80, 'Activo'),
(260, 'TIC-313', 'Gestión de la seguridad', 80, 'Activo'),
(261, 'TIC-316', 'Comunicaciones por satélite', 80, 'Activo'),
(262, 'TIC-319', 'Sistemas avanzados de comunicaciones (TIC)', 80, 'Activo'),
(263, 'TIC-322', 'Ingeniería de sistemas', 80, 'Activo'),
(264, 'TIC-323', 'Servicios en la nube', 80, 'Activo'),
(265, 'SEG-311', 'Redes de comunicación I', 80, 'Activo'),
(266, 'SEG-312', 'Redes de comunicación II', 80, 'Activo'),
(267, 'SEG-313', 'Arquitectura orientada a servicios', 80, 'Activo'),
(268, 'SEG-316', 'Hacking ético II', 80, 'Activo'),
(269, 'SEG-317', 'Administración de centros de operaciones de red', 80, 'Activo'),
(270, 'SEG-318', 'Gobierno y gestión de seguridad de la información', 80, 'Activo'),
(271, 'PER-E1', 'Taller de Crónica Urbana', 80, 'Activo'),
(272, 'PER-E2', 'Periodismo de Guerra e Internacional', 80, 'Activo'),
(273, 'PER-E3', 'Fotoperiodismo Avanzado', 80, 'Activo'),
(274, 'PER-E4', 'Monetización de Contenidos Digitales', 80, 'Activo'),
(275, 'PER-E5', 'Ética en el uso de IA para el Periodismo', 80, 'Activo'),
(276, 'AUD-E1', 'Actuación para Cine y TV', 80, 'Activo'),
(277, 'AUD-E2', 'Efectos Especiales Visuales (VFX)', 80, 'Activo'),
(278, 'AUD-E3', 'Documental de Naturaleza', 80, 'Activo'),
(279, 'AUD-E4', 'Creación de Series Web', 80, 'Activo'),
(280, 'AUD-E5', 'Marketing Audiovisual', 80, 'Activo'),
(281, 'RRPP-E1', 'Ceremonial y Protocolo Internacional', 80, 'Activo'),
(282, 'RRPP-E2', 'Gestión de Imagen de Funcionarios Públicos', 80, 'Activo'),
(283, 'RRPP-E3', 'Comunicación Interna y Clima Laboral', 80, 'Activo'),
(284, 'RRPP-E4', 'Organización de Mega Eventos', 80, 'Activo'),
(285, 'RRPP-E5', 'Relaciones Comunitarias y RSE', 80, 'Activo'),
(286, 'TSI-251', 'Procesamiento de imagen digital', 80, 'Activo'),
(287, 'TSI-261', 'Aprendizaje automático (Machine Learning)', 80, 'Activo'),
(288, 'TCS-251', 'Calidad de Software', 80, 'Activo'),
(289, 'TCS-261', 'Ingenieria de software II', 80, 'Activo'),
(290, 'TVD-251', 'Electiva I. Programación gráfica', 80, 'Activo'),
(291, 'TVD-261', 'Electiva II. Animación digital 2D y 3D', 80, 'Activo'),
(292, 'TIE-251', 'Electiva I. Administración de Entornos Virtuales de Aprendizaje', 80, 'Activo'),
(293, 'TIE-261', 'Electiva II. Desarrollo de software educativo', 80, 'Activo'),
(294, 'TAW-251', 'Electiva I. Desarrollo web BackEnd', 80, 'Activo'),
(295, 'TAW-261', 'Electiva II. Ingenieria Web', 80, 'Activo'),
(296, 'TAM-251', 'Electiva I. Sistemas embebidos', 80, 'Activo'),
(297, 'TAM-261', 'Electiva II. Desarrollo de aplicaciones móviles multiplataforma', 80, 'Activo'),
(298, 'TAR-251', 'Monitoreo y control de sistemas industriales', 80, 'Activo'),
(299, 'TAR-261', 'Sistemas domóticos', 80, 'Activo'),
(300, 'TIOT-251', 'Sistemas embebidos', 80, 'Activo'),
(301, 'TIOT-261', 'Desarrollo loT', 80, 'Activo'),
(302, 'TRC-251', 'Teoria de la Información y la codificación', 80, 'Activo'),
(303, 'TRC-261', 'Redes industriales', 80, 'Activo'),
(304, 'TAT-251', 'Sistemas móviles, multimedia y difusión', 80, 'Activo'),
(305, 'TAT-261', 'Aplicaciones y servicios distribuidos', 80, 'Activo'),
(306, 'TCP-251', 'Confiabilidad de sistemas tolerantes a fallos', 80, 'Activo'),
(307, 'TCP-261', 'Metodologias de desarrollo seguro de software', 80, 'Activo'),
(308, 'TSS-251', 'Administración de redes y servicios de infraestructura TI', 80, 'Activo'),
(309, 'TSS-261', 'Computación en la nube', 80, 'Activo');

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
(1, 'Ciencias de la Computación', 1),
(2, 'Desarrollo de Software e Innovación Tecnológica', 1),
(3, 'Informática Industrial', 1),
(4, 'Ingeniería de Sistemas', 1),
(5, 'Inteligencia Artificial y Ciencias de Datos', 1),
(6, 'Redes y Tecnologías de la Información y Comunicación (TIC)', 1),
(7, 'Seguridad de la Información', 1),
(8, 'Periodismo Digital', 2),
(9, 'Comunicación Audiovisual', 2),
(10, 'Relaciones Públicas y Corporativas', 2);

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
(1, 6, 1),
(1, 7, 2),
(1, 8, 2),
(1, 9, 2),
(1, 10, 2),
(1, 11, 2),
(1, 12, 2),
(1, 13, 3),
(1, 14, 3),
(1, 15, 3),
(1, 16, 3),
(1, 17, 3),
(1, 18, 3),
(1, 19, 4),
(1, 20, 4),
(1, 21, 4),
(1, 22, 5),
(1, 23, 5),
(1, 24, 6),
(1, 25, 6),
(1, 26, 7),
(1, 27, 8),
(1, 28, 9),
(1, 45, 4),
(1, 46, 4),
(1, 47, 4),
(1, 48, 5),
(1, 49, 5),
(1, 50, 5),
(1, 51, 6),
(1, 52, 6),
(1, 53, 6),
(1, 54, 7),
(1, 55, 7),
(1, 56, 8),
(1, 57, 8),
(1, 203, 7),
(1, 204, 7),
(1, 205, 7),
(1, 206, 7),
(1, 207, 7),
(1, 208, 7),
(1, 209, 7),
(1, 210, 7),
(1, 211, 8),
(1, 212, 8),
(1, 213, 8),
(1, 214, 8),
(1, 215, 8),
(1, 216, 8),
(1, 217, 8),
(1, 218, 8),
(1, 286, 5),
(1, 287, 6),
(1, 288, 5),
(1, 289, 6),
(2, 1, 1),
(2, 2, 1),
(2, 3, 1),
(2, 4, 1),
(2, 5, 1),
(2, 7, 2),
(2, 8, 2),
(2, 9, 2),
(2, 10, 2),
(2, 11, 2),
(2, 12, 2),
(2, 13, 3),
(2, 14, 3),
(2, 15, 3),
(2, 16, 3),
(2, 17, 3),
(2, 18, 3),
(2, 19, 4),
(2, 20, 4),
(2, 21, 4),
(2, 22, 5),
(2, 23, 5),
(2, 25, 6),
(2, 26, 7),
(2, 27, 8),
(2, 28, 9),
(2, 29, 1),
(2, 30, 4),
(2, 31, 4),
(2, 32, 4),
(2, 33, 5),
(2, 34, 5),
(2, 35, 5),
(2, 36, 6),
(2, 37, 6),
(2, 38, 6),
(2, 39, 6),
(2, 40, 7),
(2, 41, 7),
(2, 42, 7),
(2, 43, 8),
(2, 44, 8),
(2, 206, 7),
(2, 207, 7),
(2, 210, 7),
(2, 211, 8),
(2, 216, 8),
(2, 217, 8),
(2, 219, 7),
(2, 220, 7),
(2, 221, 7),
(2, 222, 7),
(2, 223, 7),
(2, 224, 7),
(2, 225, 7),
(2, 226, 8),
(2, 227, 8),
(2, 228, 8),
(2, 229, 8),
(2, 230, 8),
(2, 231, 8),
(2, 232, 8),
(2, 233, 8),
(2, 234, 8),
(2, 235, 8),
(2, 236, 8),
(2, 290, 5),
(2, 291, 6),
(2, 292, 5),
(2, 293, 6),
(2, 294, 5),
(2, 295, 6),
(2, 296, 5),
(2, 297, 6),
(3, 1, 1),
(3, 2, 1),
(3, 3, 1),
(3, 4, 1),
(3, 5, 1),
(3, 7, 2),
(3, 8, 2),
(3, 9, 2),
(3, 10, 2),
(3, 11, 2),
(3, 12, 2),
(3, 13, 3),
(3, 14, 3),
(3, 15, 3),
(3, 16, 3),
(3, 18, 3),
(3, 19, 4),
(3, 20, 4),
(3, 21, 4),
(3, 23, 5),
(3, 25, 6),
(3, 26, 7),
(3, 27, 8),
(3, 28, 9),
(3, 29, 1),
(3, 30, 4),
(3, 31, 4),
(3, 58, 3),
(3, 59, 4),
(3, 60, 4),
(3, 61, 5),
(3, 62, 5),
(3, 63, 5),
(3, 64, 5),
(3, 65, 6),
(3, 66, 6),
(3, 67, 6),
(3, 68, 6),
(3, 69, 6),
(3, 70, 7),
(3, 71, 7),
(3, 72, 8),
(3, 73, 8),
(3, 206, 7),
(3, 207, 7),
(3, 210, 8),
(3, 224, 8),
(3, 237, 7),
(3, 238, 7),
(3, 239, 7),
(3, 240, 8),
(3, 241, 8),
(3, 242, 8),
(3, 243, 8),
(3, 298, 5),
(3, 299, 6),
(3, 300, 5),
(3, 301, 6),
(4, 1, 1),
(4, 2, 1),
(4, 3, 1),
(4, 4, 1),
(4, 5, 1),
(4, 7, 2),
(4, 8, 2),
(4, 9, 2),
(4, 10, 2),
(4, 11, 2),
(4, 12, 2),
(4, 13, 3),
(4, 14, 3),
(4, 15, 3),
(4, 16, 3),
(4, 17, 3),
(4, 18, 3),
(4, 19, 4),
(4, 20, 4),
(4, 21, 4),
(4, 22, 5),
(4, 23, 5),
(4, 24, 6),
(4, 25, 6),
(4, 26, 7),
(4, 27, 8),
(4, 28, 9),
(4, 29, 1),
(4, 33, 4),
(4, 36, 6),
(4, 39, 6),
(4, 43, 8),
(4, 50, 5),
(4, 74, 4),
(4, 75, 4),
(4, 76, 5),
(4, 77, 5),
(4, 78, 5),
(4, 79, 6),
(4, 80, 6),
(4, 81, 7),
(4, 82, 7),
(4, 83, 7),
(4, 84, 8),
(4, 206, 7),
(4, 218, 8),
(4, 219, 7),
(4, 220, 7),
(4, 222, 7),
(4, 223, 7),
(4, 224, 7),
(4, 226, 8),
(4, 227, 8),
(4, 228, 8),
(4, 230, 8),
(4, 231, 8),
(4, 243, 8),
(4, 244, 7),
(4, 245, 7),
(4, 246, 7),
(4, 247, 7),
(4, 248, 8),
(4, 249, 8),
(4, 250, 8),
(5, 1, 1),
(5, 2, 1),
(5, 3, 1),
(5, 4, 1),
(5, 5, 1),
(5, 6, 1),
(5, 7, 2),
(5, 8, 2),
(5, 9, 2),
(5, 10, 2),
(5, 11, 2),
(5, 12, 2),
(5, 13, 3),
(5, 14, 3),
(5, 15, 3),
(5, 16, 3),
(5, 18, 3),
(5, 21, 4),
(5, 23, 5),
(5, 25, 6),
(5, 26, 7),
(5, 27, 8),
(5, 28, 9),
(5, 33, 4),
(5, 82, 7),
(5, 85, 3),
(5, 86, 4),
(5, 87, 4),
(5, 88, 4),
(5, 89, 4),
(5, 90, 5),
(5, 91, 5),
(5, 92, 5),
(5, 93, 5),
(5, 94, 5),
(5, 95, 6),
(5, 96, 6),
(5, 97, 6),
(5, 98, 6),
(5, 99, 7),
(5, 100, 8),
(5, 101, 8),
(5, 206, 7),
(5, 207, 7),
(5, 218, 8),
(5, 222, 7),
(5, 223, 7),
(5, 225, 8),
(5, 229, 8),
(5, 251, 7),
(5, 252, 7),
(5, 253, 7),
(5, 254, 8),
(5, 255, 8),
(5, 256, 8),
(5, 257, 8),
(6, 1, 1),
(6, 2, 1),
(6, 3, 1),
(6, 4, 1),
(6, 5, 1),
(6, 7, 2),
(6, 8, 2),
(6, 9, 2),
(6, 10, 2),
(6, 11, 2),
(6, 12, 2),
(6, 13, 3),
(6, 14, 3),
(6, 15, 3),
(6, 16, 3),
(6, 18, 3),
(6, 19, 4),
(6, 20, 4),
(6, 21, 4),
(6, 23, 5),
(6, 24, 6),
(6, 25, 6),
(6, 26, 7),
(6, 27, 8),
(6, 28, 9),
(6, 29, 1),
(6, 31, 4),
(6, 33, 4),
(6, 48, 5),
(6, 102, 3),
(6, 103, 4),
(6, 104, 4),
(6, 105, 5),
(6, 106, 5),
(6, 107, 5),
(6, 108, 5),
(6, 109, 6),
(6, 110, 6),
(6, 111, 6),
(6, 112, 7),
(6, 113, 7),
(6, 114, 7),
(6, 115, 8),
(6, 116, 8),
(6, 117, 8),
(6, 206, 7),
(6, 207, 7),
(6, 210, 8),
(6, 223, 7),
(6, 225, 8),
(6, 226, 8),
(6, 257, 8),
(6, 258, 7),
(6, 259, 7),
(6, 260, 7),
(6, 261, 7),
(6, 262, 8),
(6, 263, 8),
(6, 264, 8),
(6, 302, 5),
(6, 303, 6),
(6, 304, 5),
(6, 305, 6),
(7, 1, 1),
(7, 2, 1),
(7, 3, 1),
(7, 4, 1),
(7, 5, 1),
(7, 7, 2),
(7, 8, 2),
(7, 9, 2),
(7, 10, 2),
(7, 11, 2),
(7, 12, 2),
(7, 13, 3),
(7, 14, 3),
(7, 15, 3),
(7, 16, 3),
(7, 17, 3),
(7, 18, 3),
(7, 19, 4),
(7, 20, 4),
(7, 21, 4),
(7, 22, 5),
(7, 23, 5),
(7, 25, 6),
(7, 26, 7),
(7, 27, 8),
(7, 28, 9),
(7, 29, 1),
(7, 31, 4),
(7, 76, 5),
(7, 84, 8),
(7, 118, 4),
(7, 119, 4),
(7, 120, 5),
(7, 121, 5),
(7, 122, 6),
(7, 123, 6),
(7, 124, 6),
(7, 125, 6),
(7, 126, 7),
(7, 127, 7),
(7, 128, 7),
(7, 129, 8),
(7, 130, 8),
(7, 206, 7),
(7, 207, 7),
(7, 228, 8),
(7, 229, 8),
(7, 243, 8),
(7, 265, 7),
(7, 266, 7),
(7, 267, 7),
(7, 268, 7),
(7, 269, 8),
(7, 270, 8),
(7, 306, 5),
(7, 307, 6),
(7, 308, 5),
(7, 309, 6),
(8, 131, 1),
(8, 132, 1),
(8, 133, 1),
(8, 134, 1),
(8, 135, 1),
(8, 136, 1),
(8, 137, 2),
(8, 138, 2),
(8, 139, 2),
(8, 140, 2),
(8, 141, 2),
(8, 142, 2),
(8, 143, 3),
(8, 144, 3),
(8, 145, 3),
(8, 146, 3),
(8, 147, 3),
(8, 148, 3),
(8, 149, 4),
(8, 150, 4),
(8, 151, 4),
(8, 152, 4),
(8, 153, 4),
(8, 154, 4),
(8, 155, 5),
(8, 156, 5),
(8, 157, 5),
(8, 158, 5),
(8, 159, 5),
(8, 160, 5),
(8, 161, 8),
(8, 162, 8),
(8, 163, 9),
(8, 164, 6),
(8, 165, 6),
(8, 166, 6),
(8, 167, 6),
(8, 168, 6),
(8, 169, 7),
(8, 170, 7),
(8, 171, 7),
(8, 172, 7),
(8, 173, 7),
(8, 174, 8),
(8, 175, 8),
(8, 176, 8),
(8, 271, 7),
(8, 272, 7),
(8, 273, 7),
(8, 274, 7),
(8, 275, 7),
(9, 131, 1),
(9, 132, 1),
(9, 133, 1),
(9, 134, 1),
(9, 135, 1),
(9, 136, 1),
(9, 137, 2),
(9, 138, 2),
(9, 139, 2),
(9, 140, 2),
(9, 141, 2),
(9, 142, 2),
(9, 143, 3),
(9, 144, 3),
(9, 145, 3),
(9, 146, 3),
(9, 147, 3),
(9, 148, 3),
(9, 149, 4),
(9, 150, 4),
(9, 151, 4),
(9, 152, 4),
(9, 153, 4),
(9, 154, 4),
(9, 155, 5),
(9, 156, 5),
(9, 157, 5),
(9, 158, 5),
(9, 159, 5),
(9, 160, 5),
(9, 161, 8),
(9, 162, 8),
(9, 163, 9),
(9, 177, 6),
(9, 178, 6),
(9, 179, 6),
(9, 180, 6),
(9, 181, 6),
(9, 182, 7),
(9, 183, 7),
(9, 184, 7),
(9, 185, 7),
(9, 186, 7),
(9, 187, 8),
(9, 188, 8),
(9, 189, 8),
(9, 276, 7),
(9, 277, 7),
(9, 278, 7),
(9, 279, 7),
(9, 280, 7),
(10, 131, 1),
(10, 132, 1),
(10, 133, 1),
(10, 134, 1),
(10, 135, 1),
(10, 136, 1),
(10, 137, 2),
(10, 138, 2),
(10, 139, 2),
(10, 140, 2),
(10, 141, 2),
(10, 142, 2),
(10, 143, 3),
(10, 144, 3),
(10, 145, 3),
(10, 146, 3),
(10, 147, 3),
(10, 148, 3),
(10, 149, 4),
(10, 150, 4),
(10, 151, 4),
(10, 152, 4),
(10, 153, 4),
(10, 154, 4),
(10, 155, 5),
(10, 156, 5),
(10, 157, 5),
(10, 158, 5),
(10, 159, 5),
(10, 160, 5),
(10, 161, 8),
(10, 162, 8),
(10, 163, 9),
(10, 190, 6),
(10, 191, 6),
(10, 192, 6),
(10, 193, 6),
(10, 194, 6),
(10, 195, 7),
(10, 196, 7),
(10, 197, 7),
(10, 198, 7),
(10, 199, 7),
(10, 200, 8),
(10, 201, 8),
(10, 202, 8),
(10, 281, 7),
(10, 282, 7),
(10, 283, 7),
(10, 284, 7),
(10, 285, 7);

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
(1, 7, 1),
(1, 8, 3),
(1, 9, 2),
(1, 10, 4),
(1, 10, 6),
(1, 11, 4),
(1, 12, 5),
(1, 13, 7),
(1, 14, 7),
(1, 14, 8),
(1, 15, 1),
(1, 15, 8),
(1, 16, 10),
(1, 17, 7),
(1, 18, 10),
(1, 18, 11),
(1, 19, 14),
(1, 19, 15),
(1, 20, 16),
(1, 20, 17),
(1, 21, 16),
(1, 22, 19),
(1, 24, 20),
(1, 24, 49),
(1, 45, 13),
(1, 46, 11),
(1, 47, 12),
(1, 48, 11),
(1, 48, 16),
(1, 49, 11),
(1, 49, 13),
(1, 49, 16),
(1, 50, 47),
(1, 51, 46),
(1, 52, 13),
(1, 52, 17),
(1, 53, 45),
(1, 54, 50),
(1, 55, 22),
(1, 203, 24),
(1, 203, 25),
(1, 203, 51),
(1, 203, 52),
(1, 203, 53),
(1, 204, 24),
(1, 204, 25),
(1, 204, 51),
(1, 204, 52),
(1, 204, 53),
(1, 205, 24),
(1, 205, 25),
(1, 205, 51),
(1, 205, 52),
(1, 205, 53),
(1, 206, 24),
(1, 206, 25),
(1, 206, 51),
(1, 206, 52),
(1, 206, 53),
(1, 207, 24),
(1, 207, 25),
(1, 207, 51),
(1, 207, 52),
(1, 207, 53),
(1, 208, 24),
(1, 208, 25),
(1, 208, 51),
(1, 208, 52),
(1, 208, 53),
(1, 209, 24),
(1, 209, 25),
(1, 209, 51),
(1, 209, 52),
(1, 209, 53),
(1, 210, 24),
(1, 210, 25),
(1, 210, 51),
(1, 210, 52),
(1, 210, 53),
(1, 211, 24),
(1, 211, 25),
(1, 211, 51),
(1, 211, 52),
(1, 211, 53),
(1, 212, 24),
(1, 212, 25),
(1, 212, 51),
(1, 212, 52),
(1, 212, 53),
(1, 213, 24),
(1, 213, 25),
(1, 213, 51),
(1, 213, 52),
(1, 213, 53),
(1, 214, 24),
(1, 214, 25),
(1, 214, 51),
(1, 214, 52),
(1, 214, 53),
(1, 215, 24),
(1, 215, 25),
(1, 215, 51),
(1, 215, 52),
(1, 215, 53),
(1, 216, 24),
(1, 216, 25),
(1, 216, 51),
(1, 216, 52),
(1, 216, 53),
(1, 217, 24),
(1, 217, 25),
(1, 217, 51),
(1, 217, 52),
(1, 217, 53),
(1, 218, 24),
(1, 218, 25),
(1, 218, 51),
(1, 218, 52),
(1, 218, 53),
(1, 286, 19),
(1, 286, 20),
(1, 286, 21),
(1, 286, 45),
(1, 286, 46),
(1, 286, 47),
(1, 287, 22),
(1, 287, 23),
(1, 287, 48),
(1, 287, 49),
(1, 287, 50),
(1, 287, 286),
(1, 287, 288),
(1, 288, 19),
(1, 288, 20),
(1, 288, 21),
(1, 288, 45),
(1, 288, 46),
(1, 288, 47),
(1, 289, 22),
(1, 289, 23),
(1, 289, 48),
(1, 289, 49),
(1, 289, 50),
(1, 289, 286),
(1, 289, 288),
(2, 7, 1),
(2, 8, 3),
(2, 9, 2),
(2, 9, 29),
(2, 10, 4),
(2, 11, 4),
(2, 12, 5),
(2, 13, 7),
(2, 14, 7),
(2, 15, 1),
(2, 15, 8),
(2, 16, 10),
(2, 17, 7),
(2, 18, 10),
(2, 18, 11),
(2, 19, 14),
(2, 20, 17),
(2, 21, 16),
(2, 22, 19),
(2, 30, 9),
(2, 30, 10),
(2, 31, 13),
(2, 31, 15),
(2, 32, 11),
(2, 32, 15),
(2, 33, 14),
(2, 34, 19),
(2, 35, 31),
(2, 36, 22),
(2, 37, 33),
(2, 38, 32),
(2, 40, 20),
(2, 41, 37),
(2, 42, 12),
(2, 43, 21),
(2, 44, 36),
(2, 206, 25),
(2, 206, 36),
(2, 206, 37),
(2, 206, 38),
(2, 206, 39),
(2, 207, 25),
(2, 207, 36),
(2, 207, 37),
(2, 207, 38),
(2, 207, 39),
(2, 210, 25),
(2, 210, 36),
(2, 210, 37),
(2, 210, 38),
(2, 210, 39),
(2, 211, 25),
(2, 211, 36),
(2, 211, 37),
(2, 211, 38),
(2, 211, 39),
(2, 216, 25),
(2, 216, 36),
(2, 216, 37),
(2, 216, 38),
(2, 216, 39),
(2, 217, 25),
(2, 217, 36),
(2, 217, 37),
(2, 217, 38),
(2, 217, 39),
(2, 219, 25),
(2, 219, 36),
(2, 219, 37),
(2, 219, 38),
(2, 219, 39),
(2, 220, 25),
(2, 220, 36),
(2, 220, 37),
(2, 220, 38),
(2, 220, 39),
(2, 221, 25),
(2, 221, 36),
(2, 221, 37),
(2, 221, 38),
(2, 221, 39),
(2, 222, 25),
(2, 222, 36),
(2, 222, 37),
(2, 222, 38),
(2, 222, 39),
(2, 223, 25),
(2, 223, 36),
(2, 223, 37),
(2, 223, 38),
(2, 223, 39),
(2, 224, 25),
(2, 224, 36),
(2, 224, 37),
(2, 224, 38),
(2, 224, 39),
(2, 225, 25),
(2, 225, 36),
(2, 225, 37),
(2, 225, 38),
(2, 225, 39),
(2, 226, 25),
(2, 226, 36),
(2, 226, 37),
(2, 226, 38),
(2, 226, 39),
(2, 227, 25),
(2, 227, 36),
(2, 227, 37),
(2, 227, 38),
(2, 227, 39),
(2, 228, 25),
(2, 228, 36),
(2, 228, 37),
(2, 228, 38),
(2, 228, 39),
(2, 229, 25),
(2, 229, 36),
(2, 229, 37),
(2, 229, 38),
(2, 229, 39),
(2, 230, 25),
(2, 230, 36),
(2, 230, 37),
(2, 230, 38),
(2, 230, 39),
(2, 231, 25),
(2, 231, 36),
(2, 231, 37),
(2, 231, 38),
(2, 231, 39),
(2, 232, 25),
(2, 232, 36),
(2, 232, 37),
(2, 232, 38),
(2, 232, 39),
(2, 233, 25),
(2, 233, 36),
(2, 233, 37),
(2, 233, 38),
(2, 233, 39),
(2, 234, 25),
(2, 234, 36),
(2, 234, 37),
(2, 234, 38),
(2, 234, 39),
(2, 235, 25),
(2, 235, 36),
(2, 235, 37),
(2, 235, 38),
(2, 235, 39),
(2, 236, 25),
(2, 236, 36),
(2, 236, 37),
(2, 236, 38),
(2, 236, 39),
(2, 290, 32),
(2, 291, 290),
(2, 292, 32),
(2, 293, 292),
(2, 294, 15),
(2, 295, 294),
(2, 296, 31),
(2, 297, 296),
(3, 7, 1),
(3, 8, 3),
(3, 9, 2),
(3, 9, 29),
(3, 10, 4),
(3, 11, 4),
(3, 12, 5),
(3, 13, 7),
(3, 14, 7),
(3, 14, 8),
(3, 15, 1),
(3, 15, 8),
(3, 16, 10),
(3, 18, 10),
(3, 18, 11),
(3, 19, 14),
(3, 20, 58),
(3, 21, 16),
(3, 30, 58),
(3, 31, 13),
(3, 58, 9),
(3, 59, 58),
(3, 60, 12),
(3, 61, 20),
(3, 62, 30),
(3, 63, 59),
(3, 64, 59),
(3, 65, 61),
(3, 66, 62),
(3, 67, 64),
(3, 68, 19),
(3, 69, 61),
(3, 70, 68),
(3, 71, 66),
(3, 72, 71),
(3, 73, 70),
(3, 206, 25),
(3, 206, 65),
(3, 206, 66),
(3, 206, 67),
(3, 206, 68),
(3, 206, 69),
(3, 207, 25),
(3, 207, 65),
(3, 207, 66),
(3, 207, 67),
(3, 207, 68),
(3, 207, 69),
(3, 210, 25),
(3, 210, 65),
(3, 210, 66),
(3, 210, 67),
(3, 210, 68),
(3, 210, 69),
(3, 224, 25),
(3, 224, 65),
(3, 224, 66),
(3, 224, 67),
(3, 224, 68),
(3, 224, 69),
(3, 237, 25),
(3, 237, 65),
(3, 237, 66),
(3, 237, 67),
(3, 237, 68),
(3, 237, 69),
(3, 238, 25),
(3, 238, 65),
(3, 238, 66),
(3, 238, 67),
(3, 238, 68),
(3, 238, 69),
(3, 239, 25),
(3, 239, 65),
(3, 239, 66),
(3, 239, 67),
(3, 239, 68),
(3, 239, 69),
(3, 240, 25),
(3, 240, 65),
(3, 240, 66),
(3, 240, 67),
(3, 240, 68),
(3, 240, 69),
(3, 241, 25),
(3, 241, 65),
(3, 241, 66),
(3, 241, 67),
(3, 241, 68),
(3, 241, 69),
(3, 242, 25),
(3, 242, 65),
(3, 242, 66),
(3, 242, 67),
(3, 242, 68),
(3, 242, 69),
(3, 243, 25),
(3, 243, 65),
(3, 243, 66),
(3, 243, 67),
(3, 243, 68),
(3, 243, 69),
(3, 298, 59),
(3, 299, 298),
(3, 300, 59),
(3, 301, 300),
(4, 7, 1),
(4, 8, 3),
(4, 9, 2),
(4, 9, 29),
(4, 10, 4),
(4, 11, 4),
(4, 12, 5),
(4, 13, 7),
(4, 14, 7),
(4, 14, 8),
(4, 15, 1),
(4, 15, 8),
(4, 16, 10),
(4, 17, 7),
(4, 18, 10),
(4, 18, 11),
(4, 19, 14),
(4, 20, 9),
(4, 20, 17),
(4, 21, 16),
(4, 22, 19),
(4, 24, 76),
(4, 33, 14),
(4, 36, 22),
(4, 43, 50),
(4, 50, 12),
(4, 74, 17),
(4, 75, 13),
(4, 76, 20),
(4, 77, 21),
(4, 77, 74),
(4, 78, 15),
(4, 79, 75),
(4, 80, 77),
(4, 82, 24),
(4, 83, 80),
(4, 84, 82),
(4, 206, 24),
(4, 206, 25),
(4, 206, 36),
(4, 206, 39),
(4, 206, 79),
(4, 206, 80),
(4, 218, 24),
(4, 218, 25),
(4, 218, 36),
(4, 218, 39),
(4, 218, 79),
(4, 218, 80),
(4, 219, 24),
(4, 219, 25),
(4, 219, 36),
(4, 219, 39),
(4, 219, 79),
(4, 219, 80),
(4, 220, 24),
(4, 220, 25),
(4, 220, 36),
(4, 220, 39),
(4, 220, 79),
(4, 220, 80),
(4, 222, 24),
(4, 222, 25),
(4, 222, 36),
(4, 222, 39),
(4, 222, 79),
(4, 222, 80),
(4, 223, 24),
(4, 223, 25),
(4, 223, 36),
(4, 223, 39),
(4, 223, 79),
(4, 223, 80),
(4, 224, 24),
(4, 224, 25),
(4, 224, 36),
(4, 224, 39),
(4, 224, 79),
(4, 224, 80),
(4, 226, 24),
(4, 226, 25),
(4, 226, 36),
(4, 226, 39),
(4, 226, 79),
(4, 226, 80),
(4, 227, 24),
(4, 227, 25),
(4, 227, 36),
(4, 227, 39),
(4, 227, 79),
(4, 227, 80),
(4, 228, 24),
(4, 228, 25),
(4, 228, 36),
(4, 228, 39),
(4, 228, 79),
(4, 228, 80),
(4, 230, 24),
(4, 230, 25),
(4, 230, 36),
(4, 230, 39),
(4, 230, 79),
(4, 230, 80),
(4, 231, 24),
(4, 231, 25),
(4, 231, 36),
(4, 231, 39),
(4, 231, 79),
(4, 231, 80),
(4, 243, 24),
(4, 243, 25),
(4, 243, 36),
(4, 243, 39),
(4, 243, 79),
(4, 243, 80),
(4, 244, 24),
(4, 244, 25),
(4, 244, 36),
(4, 244, 39),
(4, 244, 79),
(4, 244, 80),
(4, 245, 24),
(4, 245, 25),
(4, 245, 36),
(4, 245, 39),
(4, 245, 79),
(4, 245, 80),
(4, 246, 24),
(4, 246, 25),
(4, 246, 36),
(4, 246, 39),
(4, 246, 79),
(4, 246, 80),
(4, 247, 24),
(4, 247, 25),
(4, 247, 36),
(4, 247, 39),
(4, 247, 79),
(4, 247, 80),
(4, 248, 24),
(4, 248, 25),
(4, 248, 36),
(4, 248, 39),
(4, 248, 79),
(4, 248, 80),
(4, 249, 24),
(4, 249, 25),
(4, 249, 36),
(4, 249, 39),
(4, 249, 79),
(4, 249, 80),
(4, 250, 24),
(4, 250, 25),
(4, 250, 36),
(4, 250, 39),
(4, 250, 79),
(4, 250, 80),
(5, 7, 1),
(5, 8, 3),
(5, 9, 2),
(5, 10, 4),
(5, 11, 4),
(5, 12, 5),
(5, 13, 7),
(5, 14, 7),
(5, 14, 8),
(5, 15, 1),
(5, 15, 8),
(5, 16, 10),
(5, 18, 10),
(5, 18, 11),
(5, 21, 16),
(5, 33, 14),
(5, 82, 95),
(5, 85, 12),
(5, 86, 13),
(5, 87, 85),
(5, 88, 9),
(5, 88, 11),
(5, 89, 16),
(5, 90, 33),
(5, 91, 87),
(5, 92, 89),
(5, 93, 21),
(5, 94, 89),
(5, 95, 90),
(5, 96, 16),
(5, 96, 85),
(5, 97, 92),
(5, 97, 93),
(5, 97, 94),
(5, 98, 94),
(5, 99, 93),
(5, 99, 98),
(5, 100, 99),
(5, 101, 97),
(5, 206, 25),
(5, 206, 95),
(5, 206, 96),
(5, 206, 97),
(5, 206, 98),
(5, 207, 25),
(5, 207, 95),
(5, 207, 96),
(5, 207, 97),
(5, 207, 98),
(5, 218, 25),
(5, 218, 95),
(5, 218, 96),
(5, 218, 97),
(5, 218, 98),
(5, 222, 25),
(5, 222, 95),
(5, 222, 96),
(5, 222, 97),
(5, 222, 98),
(5, 223, 25),
(5, 223, 95),
(5, 223, 96),
(5, 223, 97),
(5, 223, 98),
(5, 225, 25),
(5, 225, 95),
(5, 225, 96),
(5, 225, 97),
(5, 225, 98),
(5, 229, 25),
(5, 229, 95),
(5, 229, 96),
(5, 229, 97),
(5, 229, 98),
(5, 251, 25),
(5, 251, 95),
(5, 251, 96),
(5, 251, 97),
(5, 251, 98),
(5, 252, 25),
(5, 252, 95),
(5, 252, 96),
(5, 252, 97),
(5, 252, 98),
(5, 253, 25),
(5, 253, 95),
(5, 253, 96),
(5, 253, 97),
(5, 253, 98),
(5, 254, 25),
(5, 254, 95),
(5, 254, 96),
(5, 254, 97),
(5, 254, 98),
(5, 255, 25),
(5, 255, 95),
(5, 255, 96),
(5, 255, 97),
(5, 255, 98),
(5, 256, 25),
(5, 256, 95),
(5, 256, 96),
(5, 256, 97),
(5, 256, 98),
(5, 257, 25),
(5, 257, 95),
(5, 257, 96),
(5, 257, 97),
(5, 257, 98),
(6, 7, 1),
(6, 8, 3),
(6, 9, 2),
(6, 9, 29),
(6, 10, 4),
(6, 11, 4),
(6, 12, 5),
(6, 13, 7),
(6, 14, 7),
(6, 14, 8),
(6, 15, 1),
(6, 15, 8),
(6, 16, 10),
(6, 18, 10),
(6, 18, 11),
(6, 19, 14),
(6, 20, 102),
(6, 21, 16),
(6, 24, 107),
(6, 31, 13),
(6, 33, 14),
(6, 48, 31),
(6, 102, 7),
(6, 103, 13),
(6, 104, 102),
(6, 105, 20),
(6, 106, 20),
(6, 107, 20),
(6, 108, 20),
(6, 109, 108),
(6, 110, 48),
(6, 111, 106),
(6, 112, 19),
(6, 112, 109),
(6, 113, 24),
(6, 114, 111),
(6, 115, 109),
(6, 116, 113),
(6, 117, 114),
(6, 206, 24),
(6, 206, 25),
(6, 206, 109),
(6, 206, 110),
(6, 206, 111),
(6, 207, 24),
(6, 207, 25),
(6, 207, 109),
(6, 207, 110),
(6, 207, 111),
(6, 210, 24),
(6, 210, 25),
(6, 210, 109),
(6, 210, 110),
(6, 210, 111),
(6, 223, 24),
(6, 223, 25),
(6, 223, 109),
(6, 223, 110),
(6, 223, 111),
(6, 225, 24),
(6, 225, 25),
(6, 225, 109),
(6, 225, 110),
(6, 225, 111),
(6, 226, 24),
(6, 226, 25),
(6, 226, 109),
(6, 226, 110),
(6, 226, 111),
(6, 257, 24),
(6, 257, 25),
(6, 257, 109),
(6, 257, 110),
(6, 257, 111),
(6, 258, 24),
(6, 258, 25),
(6, 258, 109),
(6, 258, 110),
(6, 258, 111),
(6, 259, 24),
(6, 259, 25),
(6, 259, 109),
(6, 259, 110),
(6, 259, 111),
(6, 260, 24),
(6, 260, 25),
(6, 260, 109),
(6, 260, 110),
(6, 260, 111),
(6, 261, 24),
(6, 261, 25),
(6, 261, 109),
(6, 261, 110),
(6, 261, 111),
(6, 262, 24),
(6, 262, 25),
(6, 262, 109),
(6, 262, 110),
(6, 262, 111),
(6, 263, 24),
(6, 263, 25),
(6, 263, 109),
(6, 263, 110),
(6, 263, 111),
(6, 264, 24),
(6, 264, 25),
(6, 264, 109),
(6, 264, 110),
(6, 264, 111),
(6, 302, 21),
(6, 303, 107),
(6, 304, 19),
(6, 305, 105),
(7, 7, 1),
(7, 8, 3),
(7, 9, 2),
(7, 9, 29),
(7, 10, 4),
(7, 11, 4),
(7, 12, 5),
(7, 13, 7),
(7, 14, 7),
(7, 14, 8),
(7, 15, 1),
(7, 15, 8),
(7, 16, 10),
(7, 17, 7),
(7, 18, 10),
(7, 18, 11),
(7, 19, 13),
(7, 19, 14),
(7, 20, 17),
(7, 21, 16),
(7, 22, 19),
(7, 31, 13),
(7, 31, 15),
(7, 76, 20),
(7, 84, 126),
(7, 118, 17),
(7, 119, 11),
(7, 119, 16),
(7, 120, 14),
(7, 120, 118),
(7, 121, 119),
(7, 122, 120),
(7, 123, 76),
(7, 124, 121),
(7, 125, 76),
(7, 126, 122),
(7, 127, 123),
(7, 128, 124),
(7, 129, 126),
(7, 130, 126),
(7, 206, 25),
(7, 206, 122),
(7, 206, 123),
(7, 206, 124),
(7, 206, 125),
(7, 207, 25),
(7, 207, 122),
(7, 207, 123),
(7, 207, 124),
(7, 207, 125),
(7, 228, 25),
(7, 228, 122),
(7, 228, 123),
(7, 228, 124),
(7, 228, 125),
(7, 229, 25),
(7, 229, 122),
(7, 229, 123),
(7, 229, 124),
(7, 229, 125),
(7, 243, 25),
(7, 243, 122),
(7, 243, 123),
(7, 243, 124),
(7, 243, 125),
(7, 265, 25),
(7, 265, 122),
(7, 265, 123),
(7, 265, 124),
(7, 265, 125),
(7, 266, 25),
(7, 266, 122),
(7, 266, 123),
(7, 266, 124),
(7, 266, 125),
(7, 267, 25),
(7, 267, 122),
(7, 267, 123),
(7, 267, 124),
(7, 267, 125),
(7, 268, 25),
(7, 268, 122),
(7, 268, 123),
(7, 268, 124),
(7, 268, 125),
(7, 269, 25),
(7, 269, 122),
(7, 269, 123),
(7, 269, 124),
(7, 269, 125),
(7, 270, 25),
(7, 270, 122),
(7, 270, 123),
(7, 270, 124),
(7, 270, 125),
(7, 306, 19),
(7, 306, 20),
(7, 306, 21),
(7, 306, 31),
(7, 306, 118),
(7, 306, 119),
(7, 307, 306),
(7, 308, 19),
(7, 308, 20),
(7, 308, 21),
(7, 308, 31),
(7, 308, 118),
(7, 308, 119),
(7, 309, 308),
(8, 137, 131),
(8, 138, 132),
(8, 139, 133),
(8, 140, 131),
(8, 141, 135),
(8, 142, 135),
(8, 143, 137),
(8, 144, 138),
(8, 145, 139),
(8, 146, 133),
(8, 147, 142),
(8, 148, 141),
(8, 149, 144),
(8, 150, 145),
(8, 151, 138),
(8, 152, 143),
(8, 153, 146),
(8, 154, 143),
(8, 155, 151),
(8, 156, 153),
(8, 157, 147),
(8, 158, 143),
(8, 159, 141),
(8, 161, 158),
(8, 162, 169),
(8, 163, 162),
(8, 164, 152),
(8, 165, 153),
(8, 166, 146),
(8, 167, 155),
(8, 168, 150),
(8, 169, 164),
(8, 170, 166),
(8, 171, 168),
(8, 172, 165),
(8, 173, 168),
(8, 174, 169),
(8, 175, 169),
(8, 176, 158),
(8, 271, 155),
(8, 271, 156),
(8, 271, 157),
(8, 271, 158),
(8, 271, 159),
(8, 271, 160),
(8, 272, 155),
(8, 272, 156),
(8, 272, 157),
(8, 272, 158),
(8, 272, 159),
(8, 272, 160),
(8, 273, 155),
(8, 273, 156),
(8, 273, 157),
(8, 273, 158),
(8, 273, 159),
(8, 273, 160),
(8, 274, 155),
(8, 274, 156),
(8, 274, 157),
(8, 274, 158),
(8, 274, 159),
(8, 274, 160),
(8, 275, 155),
(8, 275, 156),
(8, 275, 157),
(8, 275, 158),
(8, 275, 159),
(8, 275, 160),
(9, 137, 131),
(9, 138, 132),
(9, 139, 133),
(9, 140, 131),
(9, 141, 135),
(9, 142, 135),
(9, 143, 137),
(9, 144, 138),
(9, 145, 139),
(9, 146, 133),
(9, 147, 142),
(9, 148, 141),
(9, 149, 144),
(9, 150, 145),
(9, 151, 138),
(9, 152, 143),
(9, 153, 146),
(9, 154, 143),
(9, 155, 151),
(9, 156, 153),
(9, 157, 147),
(9, 158, 143),
(9, 159, 141),
(9, 161, 158),
(9, 162, 184),
(9, 163, 162),
(9, 177, 150),
(9, 178, 150),
(9, 179, 133),
(9, 180, 145),
(9, 181, 134),
(9, 182, 178),
(9, 183, 178),
(9, 184, 177),
(9, 185, 177),
(9, 186, 146),
(9, 187, 184),
(9, 188, 181),
(9, 189, 182),
(9, 276, 155),
(9, 276, 156),
(9, 276, 157),
(9, 276, 158),
(9, 276, 159),
(9, 276, 160),
(9, 277, 155),
(9, 277, 156),
(9, 277, 157),
(9, 277, 158),
(9, 277, 159),
(9, 277, 160),
(9, 278, 155),
(9, 278, 156),
(9, 278, 157),
(9, 278, 158),
(9, 278, 159),
(9, 278, 160),
(9, 279, 155),
(9, 279, 156),
(9, 279, 157),
(9, 279, 158),
(9, 279, 159),
(9, 279, 160),
(9, 280, 155),
(9, 280, 156),
(9, 280, 157),
(9, 280, 158),
(9, 280, 159),
(9, 280, 160),
(10, 137, 131),
(10, 138, 132),
(10, 139, 133),
(10, 140, 131),
(10, 141, 135),
(10, 142, 135),
(10, 143, 137),
(10, 144, 138),
(10, 145, 139),
(10, 146, 133),
(10, 147, 142),
(10, 148, 141),
(10, 149, 144),
(10, 150, 145),
(10, 151, 138),
(10, 152, 143),
(10, 153, 146),
(10, 154, 143),
(10, 155, 151),
(10, 156, 153),
(10, 157, 147),
(10, 158, 143),
(10, 159, 141),
(10, 161, 158),
(10, 162, 195),
(10, 163, 162),
(10, 190, 157),
(10, 191, 157),
(10, 192, 146),
(10, 193, 157),
(10, 194, 157),
(10, 195, 191),
(10, 196, 156),
(10, 197, 190),
(10, 198, 194),
(10, 199, 191),
(10, 200, 195),
(10, 201, 196),
(10, 202, 194),
(10, 281, 155),
(10, 281, 156),
(10, 281, 157),
(10, 281, 158),
(10, 281, 159),
(10, 281, 160),
(10, 282, 155),
(10, 282, 156),
(10, 282, 157),
(10, 282, 158),
(10, 282, 159),
(10, 282, 160),
(10, 283, 155),
(10, 283, 156),
(10, 283, 157),
(10, 283, 158),
(10, 283, 159),
(10, 283, 160),
(10, 284, 155),
(10, 284, 156),
(10, 284, 157),
(10, 284, 158),
(10, 284, 159),
(10, 284, 160),
(10, 285, 155),
(10, 285, 156),
(10, 285, 157),
(10, 285, 158),
(10, 285, 159),
(10, 285, 160);

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
  MODIFY `id_carrera` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

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
  MODIFY `id_materia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=310;

--
-- AUTO_INCREMENT de la tabla `nota`
--
ALTER TABLE `nota`
  MODIFY `id_nota` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `persona`
--
ALTER TABLE `persona`
  MODIFY `id_persona` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `plan_estudio`
--
ALTER TABLE `plan_estudio`
  MODIFY `id_plan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT;

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
