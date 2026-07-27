-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 27-07-2026 a las 03:40:16
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
CREATE PROCEDURE `sp_actualizar_aula` (IN `p_id_aula` INT, IN `p_nombre` VARCHAR(50), IN `p_piso` VARCHAR(20), IN `p_ubicacion` VARCHAR(100), IN `p_capacidad` INT)   BEGIN
    UPDATE aula SET nombre = p_nombre, piso = p_piso, ubicacion = p_ubicacion, capacidad = p_capacidad WHERE id_aula = p_id_aula;
END$$

CREATE PROCEDURE `sp_actualizar_carrera` (IN `p_id_carrera` INT, IN `p_nombre` VARCHAR(100))   BEGIN
    UPDATE carrera SET nombre = p_nombre WHERE id_carrera = p_id_carrera;
END$$

CREATE PROCEDURE `sp_actualizar_criterio` (IN `p_id_criterio` INT, IN `p_nombre` VARCHAR(50), IN `p_ponderacion` FLOAT)   BEGIN
    UPDATE criterio_evaluacion SET nombre = p_nombre, ponderacion = p_ponderacion WHERE id_criterio = p_id_criterio;
END$$

CREATE PROCEDURE `sp_actualizar_gestion` (IN `p_id_gestion` INT, IN `p_periodo` VARCHAR(20))   BEGIN
    UPDATE gestion SET periodo = p_periodo WHERE id_gestion = p_id_gestion;
END$$

CREATE PROCEDURE `sp_actualizar_horario` (IN `p_id_horario` INT, IN `p_dia` VARCHAR(15), IN `p_hora_inicio` TIME, IN `p_hora_fin` TIME)   BEGIN
    UPDATE horario SET dia = p_dia, hora_inicio = p_hora_inicio, hora_fin = p_hora_fin WHERE id_horario = p_id_horario;
END$$

CREATE PROCEDURE `sp_actualizar_materia` (IN `p_id` INT, IN `p_sigla` VARCHAR(15), IN `p_nombre` VARCHAR(100), IN `p_carga_horaria` INT)   BEGIN
    UPDATE materia SET sigla = p_sigla, nombre = p_nombre, carga_horaria = p_carga_horaria WHERE id_materia = p_id;
END$$

CREATE PROCEDURE `sp_actualizar_nota` (IN `p_id_nota` INT, IN `p_puntaje` FLOAT)   BEGIN
    UPDATE nota SET nota_obtenida = p_puntaje WHERE id_nota = p_id_nota;
END$$

CREATE PROCEDURE `sp_actualizar_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT)   BEGIN
    UPDATE paralelo
    SET nombre = p_nombre, cupo_maximo = p_cupo_maximo, id_docente = p_id_docente, id_gestion = p_id_gestion
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE PROCEDURE `sp_actualizar_plan_estudio` (IN `p_id_plan` INT, IN `p_nombre` VARCHAR(100), IN `p_id_carrera` INT)   BEGIN
    UPDATE plan_estudio SET nombre = p_nombre, id_carrera = p_id_carrera WHERE id_plan = p_id_plan;
END$$

CREATE PROCEDURE `sp_actualizar_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_semestre` INT)   BEGIN
    UPDATE plan_materia SET semestre = p_semestre WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

CREATE PROCEDURE `sp_actualizar_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_old_req` INT, IN `p_new_req` INT)   BEGIN
    UPDATE prerequisito SET id_materia_req = p_new_req WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_old_req;
END$$

CREATE PROCEDURE `sp_actualizar_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_old_aula` INT, IN `p_old_horario` INT, IN `p_new_aula` INT, IN `p_new_horario` INT)   BEGIN
    UPDATE se_cursa SET id_aula = p_new_aula, id_horario = p_new_horario
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_old_aula AND id_horario = p_old_horario;
END$$

CREATE PROCEDURE `sp_aperturar_paralelo_completo` (IN `p_id_materia` INT, IN `p_nombre_paralelo` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    DECLARE v_id_paralelo INT;
    
    -- Manejador de errores para revertir cambios si algo falla (ej. choques de horario)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 1. Autogenerar el id_paralelo correlativo para la materia específica
    SELECT COALESCE(MAX(id_paralelo), 0) + 1 INTO v_id_paralelo
    FROM paralelo
    WHERE id_materia = p_id_materia;
    
    -- 2. Insertar el paralelo con el cupo en 0
    INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
    VALUES (p_id_materia, v_id_paralelo, p_nombre_paralelo, p_cupo_maximo, 0, p_id_docente, p_id_gestion);
    
    -- 3. Asignar la programación académica (aula y horario)
    INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario)
    VALUES (p_id_materia, v_id_paralelo, p_id_aula, p_id_horario);
    
    COMMIT;
    
    -- Devolver el ID generado al backend
    SELECT v_id_paralelo AS id_paralelo_generado;
END$$

CREATE PROCEDURE `sp_asignar_aulas_horarios_con_reintentos` (IN `p_id_gestion` INT, IN `p_max_intentos` INT)   BEGIN
    DECLARE v_id_materia INT;
    DECLARE v_id_paralelo INT;
    DECLARE v_id_aula INT;
    DECLARE v_id_horario INT;
    DECLARE v_intentos INT;
    DECLARE v_finished INT DEFAULT 0;
    DECLARE v_exito INT DEFAULT 0;
    DECLARE v_total_paralelos INT DEFAULT 0;
    DECLARE v_asignados INT DEFAULT 0;
    DECLARE v_error_msg VARCHAR(255);
    
    -- Cursor para recorrer paralelos
    DECLARE cur_paralelos CURSOR FOR
        SELECT id_materia, id_paralelo
        FROM paralelo
        WHERE id_gestion = p_id_gestion
        ORDER BY id_materia, id_paralelo;
    
    -- Manejador para cuando el cursor llega al final
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    
    -- Manejador de errores generales
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Contar total de paralelos
    SELECT COUNT(*) INTO v_total_paralelos
    FROM paralelo
    WHERE id_gestion = p_id_gestion;
    
    IF v_total_paralelos = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay paralelos en la gestion especificada.';
    END IF;
    
    -- Abrir cursor
    OPEN cur_paralelos;
    
    loop_paralelos: LOOP
        FETCH cur_paralelos INTO v_id_materia, v_id_paralelo;
        
        IF v_finished = 1 THEN
            LEAVE loop_paralelos;
        END IF;
        
        -- Inicializar variables
        SET v_exito = 0;
        SET v_intentos = 0;
        
        -- BUCLE DE REINTENTOS
        WHILE v_exito = 0 AND v_intentos < p_max_intentos DO
            SET v_intentos = v_intentos + 1;
            
            -- Elegir aula y horario aleatorio
            SELECT id_aula INTO v_id_aula 
            FROM aula 
            ORDER BY RAND() 
            LIMIT 1;
            
            SELECT id_horario INTO v_id_horario 
            FROM horario 
            ORDER BY RAND() 
            LIMIT 1;
            
            -- Verificar si la combinación está disponible (sin conflicto de aula)
            IF NOT EXISTS (
                SELECT 1 
                FROM se_cursa sc
                JOIN paralelo p ON sc.id_materia = p.id_materia 
                    AND sc.id_paralelo = p.id_paralelo
                WHERE sc.id_aula = v_id_aula 
                  AND sc.id_horario = v_id_horario
                  AND p.id_gestion = p_id_gestion
            ) THEN
                -- También verificar que el docente no tenga conflicto
                IF NOT EXISTS (
                    SELECT 1 
                    FROM se_cursa sc
                    JOIN paralelo p ON sc.id_materia = p.id_materia 
                        AND sc.id_paralelo = p.id_paralelo
                    JOIN paralelo p_actual ON v_id_materia = p_actual.id_materia 
                        AND v_id_paralelo = p_actual.id_paralelo
                    WHERE p.id_docente = p_actual.id_docente
                      AND sc.id_horario = v_id_horario
                      AND p.id_gestion = p_id_gestion
                ) THEN
                    SET v_exito = 1;
                END IF;
            END IF;
        END WHILE;
        
        -- Si no encontró combinación válida después de los intentos
        IF v_exito = 0 THEN
            -- Construir mensaje de error sin CONCAT en SIGNAL
            SET v_error_msg = CONCAT(
                'No se pudo asignar aula/horario despues de ',
                CAST(p_max_intentos AS CHAR),
                ' intentos para materia ID=',
                CAST(v_id_materia AS CHAR),
                ' paralelo=',
                CAST(v_id_paralelo AS CHAR)
            );
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = v_error_msg;
        END IF;
        
        -- Insertar la asignación
        INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario)
        VALUES (v_id_materia, v_id_paralelo, v_id_aula, v_id_horario)
        ON DUPLICATE KEY UPDATE 
            id_aula = VALUES(id_aula),
            id_horario = VALUES(id_horario);
        
        SET v_asignados = v_asignados + 1;
        
    END LOOP;
    
    CLOSE cur_paralelos;
    
    COMMIT;
    
    -- Mostrar resumen
    SELECT 
        p_id_gestion AS id_gestion,
        v_total_paralelos AS total_paralelos,
        v_asignados AS asignados_exitosos,
        p_max_intentos AS max_intentos_por_paralelo;
    
END$$

CREATE PROCEDURE `sp_asignar_horarios_sin_choque` (IN `p_id_gestion` INT)   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_materia INT;
    DECLARE v_id_paralelo INT;
    DECLARE v_id_aula INT;
    DECLARE v_id_horario INT;
    DECLARE v_intentos INT;
    DECLARE v_asignado INT;
    DECLARE v_conflicto INT;
    DECLARE v_periodo VARCHAR(50) DEFAULT '';
    DECLARE v_es_temporada INT DEFAULT 0;
    DECLARE v_hora_ini TIME;
    DECLARE v_hora_fin TIME;

    -- 1. DECLARACIÓN DEL CURSOR DE PARALELOS
    DECLARE cur_paralelos CURSOR FOR 
        SELECT p.id_materia, p.id_paralelo 
        FROM paralelo p
        WHERE p.id_gestion = p_id_gestion;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 2. VERIFICAR SI ES GESTIÓN DE TEMPORADA (INVIERNO O VERANO)
    SELECT periodo INTO v_periodo FROM gestion WHERE id_gestion = p_id_gestion;
    IF v_periodo LIKE 'Invierno%' OR v_periodo LIKE 'Verano%' THEN
        SET v_es_temporada = 1;
    END IF;

    OPEN cur_paralelos;

    read_loop: LOOP
        FETCH cur_paralelos INTO v_id_materia, v_id_paralelo;
        IF done THEN
            LEAVE read_loop;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM se_cursa WHERE id_materia = v_id_materia AND id_paralelo = v_id_paralelo) THEN
            SET v_intentos = 0;
            SET v_asignado = 0;

            while_loop: WHILE v_intentos < 100 AND v_asignado = 0 DO
                SET v_intentos = v_intentos + 1;

                -- Aula aleatoria
                SELECT id_aula INTO v_id_aula 
                FROM aula 
                ORDER BY RAND() 
                LIMIT 1;

                IF v_es_temporada = 1 THEN
                    -- Bloque intensivo de 4 horas (08-12, 12-16 o 16-20)
                    SELECT DISTINCT hora_inicio, hora_fin 
                    INTO v_hora_ini, v_hora_fin
                    FROM horario 
                    WHERE TIMESTAMPDIFF(HOUR, hora_inicio, hora_fin) = 4
                    ORDER BY RAND() 
                    LIMIT 1;

                    -- Validar que NO haya choque de AULA ni choque de DOCENTE
                    SELECT COUNT(*) INTO v_conflicto
                    FROM se_cursa sc
                    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
                    JOIN paralelo p_actual ON p_actual.id_materia = v_id_materia AND p_actual.id_paralelo = v_id_paralelo AND p_actual.id_gestion = p_id_gestion
                    JOIN horario h ON sc.id_horario = h.id_horario
                    WHERE p.id_gestion = p_id_gestion
                      AND h.hora_inicio = v_hora_ini 
                      AND h.hora_fin = v_hora_fin
                      AND (
                          sc.id_aula = v_id_aula 
                          OR (p_actual.id_docente IS NOT NULL AND p.id_docente = p_actual.id_docente AND (sc.id_materia != v_id_materia OR sc.id_paralelo != v_id_paralelo))
                      );

                    IF v_conflicto = 0 THEN
                        INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario)
                        SELECT v_id_materia, v_id_paralelo, v_id_aula, h.id_horario
                        FROM horario h
                        WHERE h.hora_inicio = v_hora_ini 
                          AND h.hora_fin = v_hora_fin
                          AND h.dia IN ('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes');
                        
                        SET v_asignado = 1;
                    END IF;
                ELSE
                    -- Semestre regular
                    SELECT id_horario INTO v_id_horario
                    FROM horario 
                    WHERE TIMESTAMPDIFF(HOUR, hora_inicio, hora_fin) = 2
                    ORDER BY RAND() 
                    LIMIT 1;

                    SELECT COUNT(*) INTO v_conflicto
                    FROM se_cursa sc
                    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
                    JOIN paralelo p_actual ON p_actual.id_materia = v_id_materia AND p_actual.id_paralelo = v_id_paralelo AND p_actual.id_gestion = p_id_gestion
                    WHERE p.id_gestion = p_id_gestion
                      AND sc.id_horario = v_id_horario
                      AND (
                          sc.id_aula = v_id_aula 
                          OR (p_actual.id_docente IS NOT NULL AND p.id_docente = p_actual.id_docente AND (sc.id_materia != v_id_materia OR sc.id_paralelo != v_id_paralelo))
                      );

                    IF v_conflicto = 0 THEN
                        INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario)
                        VALUES (v_id_materia, v_id_paralelo, v_id_aula, v_id_horario);
                        SET v_asignado = 1;
                    END IF;
                END IF;
            END WHILE;
        END IF;
    END LOOP;

    CLOSE cur_paralelos;
END$$

CREATE PROCEDURE `sp_cerrar_gestion` (IN `p_id_gestion` INT)   BEGIN
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

CREATE PROCEDURE `sp_crear_aula` (IN `p_nombre` VARCHAR(50), IN `p_piso` VARCHAR(20), IN `p_ubicacion` VARCHAR(100), IN `p_capacidad` INT)   BEGIN
    INSERT INTO aula (nombre, piso, ubicacion, capacidad) VALUES (p_nombre, p_piso, p_ubicacion, p_capacidad);
END$$

CREATE PROCEDURE `sp_crear_carrera` (IN `p_nombre` VARCHAR(100))   BEGIN
    INSERT INTO carrera (nombre) VALUES (p_nombre);
    SELECT LAST_INSERT_ID() AS id_carrera;
END$$

CREATE PROCEDURE `sp_crear_criterio` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(50), IN `p_ponderacion` FLOAT)   BEGIN
    INSERT INTO criterio_evaluacion (id_materia, id_paralelo, nombre, ponderacion) VALUES (p_id_materia, p_id_paralelo, p_nombre, p_ponderacion);
    SELECT LAST_INSERT_ID() AS id_criterio;
END$$

CREATE PROCEDURE `sp_crear_gestion` (IN `p_periodo` VARCHAR(20))   BEGIN
    INSERT INTO gestion (periodo) VALUES (p_periodo);
END$$

CREATE PROCEDURE `sp_crear_horario` (IN `p_dia` VARCHAR(15), IN `p_hora_inicio` TIME, IN `p_hora_fin` TIME)   BEGIN
    INSERT INTO horario (dia, hora_inicio, hora_fin) VALUES (p_dia, p_hora_inicio, p_hora_fin);
END$$

CREATE PROCEDURE `sp_crear_materia` (IN `p_sigla` VARCHAR(15), IN `p_nombre` VARCHAR(100), IN `p_carga_horaria` INT)   BEGIN
    INSERT INTO materia (sigla, nombre, carga_horaria) VALUES (p_sigla, p_nombre, p_carga_horaria);
END$$

CREATE PROCEDURE `sp_crear_nota` (IN `p_id_detalle` INT, IN `p_id_criterio` INT, IN `p_puntaje` FLOAT)   BEGIN
    INSERT INTO nota (id_detalle, id_criterio, nota_obtenida) VALUES (p_id_detalle, p_id_criterio, p_puntaje);
    SELECT LAST_INSERT_ID() AS id_nota;
END$$

CREATE PROCEDURE `sp_crear_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT)   BEGIN
    INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion)
    VALUES (p_id_materia, p_id_paralelo, p_nombre, p_cupo_maximo, p_id_docente, p_id_gestion);
END$$

CREATE PROCEDURE `sp_crear_plan_estudio` (IN `p_nombre` VARCHAR(100), IN `p_id_carrera` INT)   BEGIN
    INSERT INTO plan_estudio (nombre, id_carrera) VALUES (p_nombre, p_id_carrera);
    SELECT LAST_INSERT_ID() AS id_plan;
END$$

CREATE PROCEDURE `sp_crear_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_semestre` INT)   BEGIN
    INSERT INTO plan_materia (id_plan, id_materia, semestre) VALUES (p_id_plan, p_id_materia, p_semestre);
END$$

CREATE PROCEDURE `sp_crear_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_materia_req` INT)   BEGIN
    INSERT INTO prerequisito (id_plan, id_materia, id_materia_req) VALUES (p_id_plan, p_id_materia, p_id_materia_req);
END$$

CREATE PROCEDURE `sp_crear_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) VALUES (p_id_materia, p_id_paralelo, p_id_aula, p_id_horario);
END$$

CREATE PROCEDURE `sp_eliminar_aula` (IN `p_id_aula` INT)   BEGIN
    DELETE FROM aula WHERE id_aula = p_id_aula;
END$$

CREATE PROCEDURE `sp_eliminar_carrera` (IN `p_id_carrera` INT)   BEGIN
    DELETE FROM carrera WHERE id_carrera = p_id_carrera;
END$$

CREATE PROCEDURE `sp_eliminar_criterio` (IN `p_id_criterio` INT)   BEGIN
    DELETE FROM criterio_evaluacion WHERE id_criterio = p_id_criterio;
END$$

CREATE PROCEDURE `sp_eliminar_gestion` (IN `p_id_gestion` INT)   BEGIN
    DELETE FROM gestion WHERE id_gestion = p_id_gestion;
END$$

CREATE PROCEDURE `sp_eliminar_horario` (IN `p_id_horario` INT)   BEGIN
    DELETE FROM horario WHERE id_horario = p_id_horario;
END$$

CREATE PROCEDURE `sp_eliminar_materia` (IN `p_id` INT)   BEGIN
    DELETE FROM materia WHERE id_materia = p_id;
END$$

CREATE PROCEDURE `sp_eliminar_nota` (IN `p_id_nota` INT)   BEGIN
    DELETE FROM nota WHERE id_nota = p_id_nota;
END$$

CREATE PROCEDURE `sp_eliminar_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    DELETE FROM paralelo WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE PROCEDURE `sp_eliminar_plan_estudio` (IN `p_id_plan` INT)   BEGIN
    DELETE FROM plan_estudio WHERE id_plan = p_id_plan;
END$$

CREATE PROCEDURE `sp_eliminar_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT)   BEGIN
    DELETE FROM plan_materia WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

CREATE PROCEDURE `sp_eliminar_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_materia_req` INT)   BEGIN
    DELETE FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_id_materia_req;
END$$

CREATE PROCEDURE `sp_eliminar_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    DELETE FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_id_aula AND id_horario = p_id_horario;
END$$

CREATE PROCEDURE `sp_insertar_estudiante_completo` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_plan` INT, IN `p_anio_ingreso` VARCHAR(20))   BEGIN
    DECLARE v_id_persona INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_email VARCHAR(120);
    DECLARE v_password VARCHAR(20);
    DECLARE v_ru INT;
    DECLARE v_lock_status INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Liberar el candado en caso de error
        DO RELEASE_LOCK('lock_creacion_usuario');
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Adquirir un candado exclusivo por 10 segundos
    SELECT GET_LOCK('lock_creacion_usuario', 10) INTO v_lock_status;
    
    IF v_lock_status = 1 THEN
        START TRANSACTION;
        
        -- Ahora es 100% seguro generar esto, nadie más lo está haciendo al mismo tiempo
        SET v_username = fn_generar_username(p_nombres, p_apellidos);
        SET v_email = fn_generar_email(v_username);
        SET v_password = '123456';
        
        INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
        VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, v_email, 'Activo');
        
        SET v_id_persona = LAST_INSERT_ID();
        
        INSERT INTO estudiante (id_persona, id_plan, anio_ingreso)
        VALUES (v_id_persona, p_id_plan, p_anio_ingreso);
        
        SELECT ru INTO v_ru FROM estudiante WHERE id_persona = v_id_persona;
        
        INSERT INTO usuario (username, password_hash, id_persona, id_rol, estado)
        VALUES (v_username, v_password, v_id_persona, 4, 'Activo');
        
        COMMIT;
        
        -- Soltar el candado para que pase el siguiente
        DO RELEASE_LOCK('lock_creacion_usuario');
        
        SELECT v_id_persona AS id_persona, v_ru AS ru, v_username AS username, v_email AS email;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servidor ocupado: Timeout al intentar generar el usuario. Intente nuevamente.';
    END IF;
END$$

CREATE PROCEDURE `sp_insertar_estudiante_completo_seguro` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_plan` INT, IN `p_anio_ingreso` VARCHAR(20), IN `p_password_hash` VARCHAR(255), IN `p_usuario_audit` INT)   BEGIN
    DECLARE v_id_persona INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_email VARCHAR(120);
    DECLARE v_ru INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Configurar usuario de auditoría
    SET @current_user_id = p_usuario_audit;
    
    -- Generar username y email
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    
    -- Insertar persona
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
    VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, v_email, 'Activo');
    
    SET v_id_persona = LAST_INSERT_ID();
    
    -- Insertar estudiante
    INSERT INTO estudiante (id_persona, id_plan, anio_ingreso)
    VALUES (v_id_persona, p_id_plan, p_anio_ingreso);
    
    SELECT ru INTO v_ru FROM estudiante WHERE id_persona = v_id_persona;
    
    -- Insertar usuario con HASH (NO texto plano)
    INSERT INTO usuario (username, password_hash, id_persona, id_rol, estado)
    VALUES (v_username, p_password_hash, v_id_persona, 4, 'Activo');
    
    COMMIT;
    
    -- Devolver resultados
    SELECT 
        v_id_persona AS id_persona,
        v_ru AS ru,
        v_username AS username,
        v_email AS email
    ;
    
END$$

CREATE PROCEDURE `sp_insertar_persona_usuario` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_rol` INT, IN `p_estado` VARCHAR(20))   BEGIN
    DECLARE v_id_persona INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_email VARCHAR(120);
    DECLARE v_password VARCHAR(20);
    DECLARE v_existe INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Generar username base
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    
    -- Generar email basado en el username
    SET v_email = fn_generar_email(v_username);
    
    -- Verificar que el email no exista ya
    SELECT COUNT(*) INTO v_existe FROM persona WHERE email = v_email;
    IF v_existe > 0 THEN
        SET v_email = CONCAT(v_username, '2@fcpn.edu.bo');
    END IF;
    
    -- Generar password por defecto 123456
    SET v_password = '123456';
    
    -- Insertar persona
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
    VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, v_email, p_estado);
    
    SET v_id_persona = LAST_INSERT_ID();
    
    -- Insertar usuario con el mismo username que generó el email
    INSERT INTO usuario (username, password_hash, id_persona, id_rol, estado)
    VALUES (v_username, v_password, v_id_persona, p_id_rol, p_estado);

    -- Insertar en la tabla del rol si corresponde
    IF p_id_rol = 4 THEN
        INSERT IGNORE INTO estudiante (id_persona, ru, id_plan, anio_ingreso)
        VALUES (v_id_persona, CONCAT('RU-', v_id_persona), 1, YEAR(CURDATE()));
    ELSEIF p_id_rol = 3 THEN
        INSERT IGNORE INTO docente (id_persona, registro_docente, grado_academico)
        VALUES (v_id_persona, CONCAT('DOC-', v_id_persona), 'Lic.');
    ELSEIF p_id_rol = 1 THEN
        INSERT IGNORE INTO administrativo (id_persona, item, id_carrera)
        VALUES (v_id_persona, CONCAT('ADM-', v_id_persona), 1);
    END IF;
    
    COMMIT;
    
    SELECT v_id_persona AS id_persona, v_username AS username, v_email AS email, v_password AS password;
END$$

CREATE PROCEDURE `sp_insertar_persona_usuario_seguro` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_rol` INT, IN `p_password_hash` VARCHAR(255), IN `p_usuario_audit` INT)   BEGIN
    DECLARE v_id_persona INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_email VARCHAR(120);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Configurar usuario de auditoría
    SET @current_user_id = p_usuario_audit;
    
    -- Generar username y email
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    
    -- Insertar persona
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
    VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, v_email, 'Activo');
    
    SET v_id_persona = LAST_INSERT_ID();
    
    -- Insertar usuario con HASH
    INSERT INTO usuario (username, password_hash, id_persona, id_rol, estado)
    VALUES (v_username, p_password_hash, v_id_persona, p_id_rol, 'Activo');
    
    COMMIT;
    
    SELECT 
        v_id_persona AS id_persona,
        v_username AS username,
        v_email AS email
    ;
    
END$$

CREATE PROCEDURE `sp_obtener_aulas` ()   BEGIN
    SELECT * FROM aula;
END$$

CREATE PROCEDURE `sp_obtener_aula_por_id` (IN `p_id_aula` INT)   BEGIN
    SELECT * FROM aula WHERE id_aula = p_id_aula;
END$$

CREATE PROCEDURE `sp_obtener_carreras` ()   BEGIN
    SELECT * FROM carrera;
END$$

CREATE PROCEDURE `sp_obtener_carrera_por_id` (IN `p_id_carrera` INT)   BEGIN
    SELECT * FROM carrera WHERE id_carrera = p_id_carrera;
END$$

CREATE PROCEDURE `sp_obtener_criterios_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    SELECT * FROM criterio_evaluacion WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE PROCEDURE `sp_obtener_gestiones` ()   BEGIN
    SELECT * FROM gestion;
END$$

CREATE PROCEDURE `sp_obtener_horarios` ()   BEGIN
    SELECT * FROM horario;
END$$

CREATE PROCEDURE `sp_obtener_horario_por_id` (IN `p_id_horario` INT)   BEGIN
    SELECT * FROM horario WHERE id_horario = p_id_horario;
END$$

CREATE PROCEDURE `sp_obtener_materias` ()   BEGIN
    SELECT * FROM materia;
END$$

CREATE PROCEDURE `sp_obtener_materias_por_plan` (IN `p_id_plan` INT)   BEGIN
    SELECT * FROM plan_materia WHERE id_plan = p_id_plan;
END$$

CREATE PROCEDURE `sp_obtener_materia_por_id` (IN `p_id` INT)   BEGIN
    SELECT * FROM materia WHERE id_materia = p_id;
END$$

CREATE PROCEDURE `sp_obtener_notas_detalle` (IN `p_id_detalle` INT)   BEGIN
    SELECT * FROM nota WHERE id_detalle = p_id_detalle;
END$$

CREATE PROCEDURE `sp_obtener_paralelos` ()   BEGIN
    SELECT 
        p.id_materia,
        p.id_paralelo,
        p.nombre,
        p.cupo_maximo,
        -- Conteo dinámico de inscritos activos desde la tabla detalle_inscripcion
        COALESCE(
            (SELECT COUNT(*) 
             FROM detalle_inscripcion d
             JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
             WHERE d.id_materia = p.id_materia 
               AND d.id_paralelo = p.id_paralelo 
               AND i.id_gestion = p.id_gestion 
               AND d.estado = 'Inscrito'), 
            0
        ) AS cupo_actual,
        -- Cálculo dinámico de vacantes disponibles en la base de datos
        GREATEST(0, p.cupo_maximo - COALESCE(
            (SELECT COUNT(*) 
             FROM detalle_inscripcion d
             JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
             WHERE d.id_materia = p.id_materia 
               AND d.id_paralelo = p.id_paralelo 
               AND i.id_gestion = p.id_gestion 
               AND d.estado = 'Inscrito'), 
            0
        )) AS cupo_disponible,
        p.id_docente,
        p.id_gestion
    FROM paralelo p;
END$$

CREATE PROCEDURE `sp_obtener_planes_estudio` ()   BEGIN
    SELECT * FROM plan_estudio;
END$$

CREATE PROCEDURE `sp_obtener_plan_estudio_por_id` (IN `p_id_plan` INT)   BEGIN
    SELECT * FROM plan_estudio WHERE id_plan = p_id_plan;
END$$

CREATE PROCEDURE `sp_obtener_plan_materias` ()   BEGIN
    SELECT * FROM plan_materia;
END$$

CREATE PROCEDURE `sp_obtener_prerequisitos` ()   BEGIN
    SELECT * FROM prerequisito;
END$$

CREATE PROCEDURE `sp_obtener_prerequisitos_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT)   BEGIN
    SELECT * FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

CREATE PROCEDURE `sp_obtener_se_cursa` ()   BEGIN
    SELECT * FROM se_cursa;
END$$

CREATE PROCEDURE `sp_obtener_se_cursa_por_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    SELECT * FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

CREATE PROCEDURE `sp_preview_cierre_gestion` (IN `p_id_gestion` INT)   BEGIN
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

CREATE PROCEDURE `sp_realizar_inscripcion` (IN `p_id_estudiante` INT, IN `p_id_gestion` INT, IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    DECLARE v_id_inscripcion INT DEFAULT NULL;
    DECLARE v_cupo_max INT DEFAULT 35;
    DECLARE v_cupo_act INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT fn_existe_estudiante(p_id_estudiante) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El estudiante no existe.';
    END IF;
    IF NOT fn_existe_gestion(p_id_gestion) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La gestion no existe.';
    END IF;
    IF NOT fn_existe_materia(p_id_materia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La materia no existe.';
    END IF;

    -- Validar que el paralelo exista en esa gestión específica
    IF NOT EXISTS (SELECT 1 FROM paralelo WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_gestion = p_id_gestion) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El paralelo no existe en la gestión seleccionada.';
    END IF;

    IF fn_ya_inscrito(p_id_estudiante, p_id_gestion, p_id_materia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El estudiante ya está inscrito en esa materia.';
    END IF;

    IF NOT fn_tiene_prerrequisitos(p_id_estudiante, p_id_plan, p_id_materia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No cumple los prerrequisitos de la materia.';
    END IF;

    -- Obtener o crear cabecera de inscripción
    SELECT id_inscripcion INTO v_id_inscripcion
    FROM inscripcion
    WHERE id_estudiante = p_id_estudiante AND id_gestion = p_id_gestion
    LIMIT 1;

    IF v_id_inscripcion IS NULL THEN
        INSERT INTO inscripcion (id_estudiante, id_gestion, fecha_registro)
        VALUES (p_id_estudiante, p_id_gestion, CURDATE());
        SET v_id_inscripcion = LAST_INSERT_ID();
    END IF;

    -- Insertar el detalle de inscripción
    INSERT INTO detalle_inscripcion (id_inscripcion, id_materia, id_paralelo, estado, nota_final)
    VALUES (v_id_inscripcion, p_id_materia, p_id_paralelo, 'Inscrito', 0);

    COMMIT;
END$$

CREATE PROCEDURE `sp_retirar_inscripcion` (IN `p_id_detalle` INT)   BEGIN
    DECLARE v_id_materia INT;
    DECLARE v_id_paralelo INT;
    DECLARE v_id_gestion INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS(SELECT 1 FROM detalle_inscripcion WHERE id_detalle = p_id_detalle) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La inscripción no existe.';
    END IF;

    -- Obtener la materia, paralelo y gestión para liberar el cupo
    SELECT d.id_materia, d.id_paralelo, i.id_gestion 
    INTO v_id_materia, v_id_paralelo, v_id_gestion
    FROM detalle_inscripcion d
    JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
    WHERE d.id_detalle = p_id_detalle
    LIMIT 1;

    -- Eliminar la asignación de notas asociadas si existieran
    DELETE FROM nota WHERE id_detalle = p_id_detalle;

    -- Eliminar la materia inscrita de la planilla
    DELETE FROM detalle_inscripcion WHERE id_detalle = p_id_detalle;

    -- Decrementar el cupo ocupado en el paralelo de la gestión correspondiente
    UPDATE paralelo
    SET cupo_actual = GREATEST(cupo_actual - 1, 0)
    WHERE id_materia = v_id_materia 
      AND id_paralelo = v_id_paralelo 
      AND id_gestion = v_id_gestion;

    COMMIT;
END$$

CREATE PROCEDURE `sp_set_audit_user` (IN `p_id_usuario` INT)   BEGIN
    SET @current_user_id = p_id_usuario;
END$$

--
-- Funciones
--
CREATE FUNCTION `fn_aula_disponible` (`p_id_aula` INT, `p_id_horario` INT, `p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    WHERE sc.id_aula = p_id_aula AND sc.id_horario = p_id_horario AND p.id_gestion = p_id_gestion;
    RETURN v_count = 0;
END$$

CREATE FUNCTION `fn_calcular_nota_final` (`p_id_detalle` INT) RETURNS FLOAT DETERMINISTIC BEGIN
    DECLARE v_nota FLOAT;
    SELECT COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0)
    INTO v_nota
    FROM nota n
    JOIN criterio_evaluacion ce ON n.id_criterio = ce.id_criterio
    WHERE n.id_detalle = p_id_detalle;
    RETURN v_nota;
END$$

CREATE FUNCTION `fn_cupo_disponible` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_max INT;
DECLARE v_actual INT;
SELECT cupo_maximo, cupo_actual INTO v_max, v_actual FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
RETURN v_actual < v_max;
END$$

CREATE FUNCTION `fn_existe_estudiante` (`p_id_estudiante` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM ESTUDIANTE WHERE id_persona = p_id_estudiante;
RETURN v_existe > 0;
END$$

CREATE FUNCTION `fn_existe_gestion` (`p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM GESTION WHERE id_gestion=p_id_gestion;
RETURN v_existe>0;
END$$

CREATE FUNCTION `fn_existe_materia` (`p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM MATERIA WHERE id_materia=p_id_materia;
RETURN v_existe>0;
END$$

CREATE FUNCTION `fn_existe_paralelo` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_existe INT;
SELECT COUNT(*) INTO v_existe FROM PARALELO WHERE id_materia=p_id_materia AND id_paralelo=p_id_paralelo;
RETURN v_existe>0;
END$$

CREATE FUNCTION `fn_extraer_numero_ci` (`p_ci` VARCHAR(20)) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_numero VARCHAR(20) DEFAULT '';
    DECLARE v_char CHAR(1);
    DECLARE v_len INT;
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_done INT DEFAULT 0;
    
    SET v_len = CHAR_LENGTH(p_ci);
    
    WHILE v_i <= v_len AND v_done = 0 DO
        SET v_char = SUBSTRING(p_ci, v_i, 1);
        IF v_char REGEXP '[0-9]' THEN
            SET v_numero = CONCAT(v_numero, v_char);
        ELSE
            SET v_done = 1;
        END IF;
        SET v_i = v_i + 1;
    END WHILE;
    
    RETURN v_numero;
END$$

CREATE FUNCTION `fn_generar_email` (`p_username` VARCHAR(50)) RETURNS VARCHAR(120) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_base VARCHAR(120);
    DECLARE v_final VARCHAR(120);
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_done INT DEFAULT 0;
    
    SET v_base = CONCAT(p_username, '@fcpn.edu.bo');
    SET v_final = v_base;
    
    WHILE v_done = 0 DO
        IF EXISTS (SELECT 1 FROM persona WHERE email = v_final) THEN
            SET v_contador = v_contador + 1;
            SET v_final = CONCAT(p_username, v_contador, '@fcpn.edu.bo');
        ELSE
            SET v_done = 1;
        END IF;
    END WHILE;
    
    RETURN v_final;
END$$

CREATE FUNCTION `fn_generar_username` (`p_nombres` VARCHAR(80), `p_apellidos` VARCHAR(80)) RETURNS VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_inicial_nombre CHAR(1);
    DECLARE v_apellido_paterno VARCHAR(40);
    DECLARE v_inicial_materno CHAR(1);
    DECLARE v_base VARCHAR(50);
    DECLARE v_final VARCHAR(50);
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_done INT DEFAULT 0;
    
    SET v_inicial_nombre = LOWER(LEFT(TRIM(p_nombres), 1));
    SET v_apellido_paterno = LOWER(SUBSTRING_INDEX(TRIM(p_apellidos), ' ', 1));
    
    IF LOCATE(' ', TRIM(p_apellidos)) > 0 THEN
        SET v_inicial_materno = LOWER(LEFT(SUBSTRING_INDEX(TRIM(p_apellidos), ' ', -1), 1));
        SET v_base = CONCAT(v_inicial_nombre, v_apellido_paterno, v_inicial_materno);
    ELSE
        SET v_base = CONCAT(v_inicial_nombre, v_apellido_paterno);
    END IF;
    
    SET v_final = v_base;
    
    WHILE v_done = 0 DO
        IF EXISTS (SELECT 1 FROM usuario WHERE username = v_final) THEN
            SET v_contador = v_contador + 1;
            SET v_final = CONCAT(v_base, v_contador);
        ELSE
            SET v_done = 1;
        END IF;
    END WHILE;
    
    RETURN v_final;
END$$

CREATE FUNCTION `fn_nombre_completo` (`p_id_persona` INT) RETURNS VARCHAR(200) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_nombre VARCHAR(200);
    SELECT CONCAT(nombres, ' ', apellidos) INTO v_nombre FROM persona WHERE id_persona = p_id_persona;
    RETURN v_nombre;
END$$

CREATE FUNCTION `fn_tiene_prerrequisitos` (`p_id_estudiante` INT, `p_id_plan` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE v_total INT DEFAULT 0;
DECLARE v_aprobadas INT DEFAULT 0;
SELECT COUNT(*) INTO v_total FROM PREREQUISITO WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
IF v_total = 0 THEN
RETURN TRUE;
END IF;
SELECT COUNT(*) INTO v_aprobadas FROM PREREQUISITO pr INNER JOIN DETALLE_INSCRIPCION di ON pr.id_materia_req = di.id_materia INNER JOIN INSCRIPCION i ON di.id_inscripcion = i.id_inscripcion WHERE pr.id_plan = p_id_plan AND pr.id_materia = p_id_materia AND i.id_estudiante = p_id_estudiante AND di.nota_final >= 51;
RETURN v_total = v_aprobadas;
END$$

CREATE FUNCTION `fn_ya_inscrito` (`p_id_estudiante` INT, `p_id_gestion` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_existe 
    FROM inscripcion i 
    INNER JOIN detalle_inscripcion d ON i.id_inscripcion = d.id_inscripcion 
    WHERE i.id_estudiante = p_id_estudiante 
      AND i.id_gestion = p_id_gestion 
      AND d.id_materia = p_id_materia
      AND d.estado = 'Inscrito';
      
    RETURN (v_existe > 0);
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
(1, '101205', 1),
(2, '101206', 1),
(3, '101207', 1),
(4, '101208', 2),
(5, '101209', 2),
(6, '101210', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria`
--

CREATE TABLE `auditoria` (
  `id_auditoria` int(11) NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `tipo` varchar(10) NOT NULL DEFAULT 'INSERT',
  `accion` varchar(255) NOT NULL,
  `fecha` date NOT NULL,
  `hora` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `auditoria`
--

INSERT INTO `auditoria` (`id_auditoria`, `id_usuario`, `tipo`, `accion`, `fecha`, `hora`) VALUES
(733, NULL, 'DELETE', 'Eliminada persona ID=77 (Juan Carlos Mamani Quispe)', '2026-07-26', '06:59:08'),
(734, NULL, 'DELETE', 'Eliminada persona ID=78 (María Elena Flores Apaza)', '2026-07-26', '06:59:08'),
(735, NULL, 'DELETE', 'Eliminada persona ID=79 (Pedro Luis Condori Mamani)', '2026-07-26', '06:59:08'),
(736, NULL, 'DELETE', 'Eliminada persona ID=80 (Ana María Ticona Laura)', '2026-07-26', '06:59:08'),
(737, NULL, 'DELETE', 'Eliminada persona ID=81 (José Antonio Huanca Pari)', '2026-07-26', '06:59:08'),
(738, NULL, 'DELETE', 'Eliminada persona ID=82 (Rosa Elena Apaza Flores)', '2026-07-26', '06:59:08'),
(739, NULL, 'DELETE', 'Eliminada persona ID=83 (Carlos Alberto Mamani Condori)', '2026-07-26', '06:59:08'),
(740, NULL, 'DELETE', 'Eliminada persona ID=84 (Patricia Laura Quispe)', '2026-07-26', '06:59:08'),
(741, NULL, 'DELETE', 'Eliminada persona ID=85 (Miguel Ángel Flores Ticona)', '2026-07-26', '06:59:08'),
(742, NULL, 'DELETE', 'Eliminada persona ID=86 (Sonia Condori Huanca)', '2026-07-26', '06:59:08'),
(743, NULL, 'DELETE', 'Eliminada persona ID=87 (Roberto Quispe Mamani)', '2026-07-26', '06:59:08'),
(744, NULL, 'DELETE', 'Eliminada persona ID=88 (Carmen Ticona Apaza)', '2026-07-26', '06:59:08'),
(745, NULL, 'DELETE', 'Eliminada persona ID=89 (Fernando Mamani Flores)', '2026-07-26', '06:59:08'),
(746, NULL, 'DELETE', 'Eliminada persona ID=90 (Gloria Huanca Laura)', '2026-07-26', '06:59:08'),
(747, NULL, 'DELETE', 'Eliminada persona ID=91 (Ricardo Apaza Condori)', '2026-07-26', '06:59:08'),
(748, NULL, 'DELETE', 'Eliminada persona ID=92 (Nancy Laura Quispe)', '2026-07-26', '06:59:08'),
(749, NULL, 'DELETE', 'Eliminada persona ID=93 (Eduardo Flores Mamani)', '2026-07-26', '06:59:08'),
(750, NULL, 'DELETE', 'Eliminada persona ID=94 (Verónica Condori Apaza)', '2026-07-26', '06:59:08'),
(751, NULL, 'DELETE', 'Eliminada persona ID=95 (Mario Quispe Ticona)', '2026-07-26', '06:59:08'),
(752, NULL, 'DELETE', 'Eliminada persona ID=96 (Claudia Mamani Laura)', '2026-07-26', '06:59:08'),
(753, NULL, 'DELETE', 'Eliminada persona ID=97 (Héctor Ticona Flores)', '2026-07-26', '06:59:08'),
(754, NULL, 'DELETE', 'Eliminada persona ID=98 (Daniela Apaza Huanca)', '2026-07-26', '06:59:08'),
(755, NULL, 'DELETE', 'Eliminada persona ID=99 (Gustavo Laura Condori)', '2026-07-26', '06:59:08'),
(756, NULL, 'DELETE', 'Eliminada persona ID=100 (Mónica Flores Quispe)', '2026-07-26', '06:59:08'),
(757, NULL, 'DELETE', 'Eliminada persona ID=101 (Alejandro Condori Mamani)', '2026-07-26', '06:59:08'),
(758, NULL, 'DELETE', 'Eliminada persona ID=102 (Roxana Quispe Apaza)', '2026-07-26', '06:59:08'),
(759, NULL, 'DELETE', 'Eliminada persona ID=103 (Pablo Mamani Ticona)', '2026-07-26', '06:59:08'),
(760, NULL, 'DELETE', 'Eliminada persona ID=104 (Yolanda Huanca Flores)', '2026-07-26', '06:59:08'),
(761, NULL, 'DELETE', 'Eliminada persona ID=105 (Christian Ticona Laura)', '2026-07-26', '06:59:08'),
(762, NULL, 'DELETE', 'Eliminada persona ID=106 (Silvia Apaza Mamani)', '2026-07-26', '06:59:08'),
(763, NULL, 'DELETE', 'Eliminada persona ID=107 (Oscar Laura Condori)', '2026-07-26', '06:59:08'),
(764, NULL, 'DELETE', 'Eliminada persona ID=108 (Marcela Flores Quispe)', '2026-07-26', '06:59:08'),
(765, NULL, 'DELETE', 'Eliminada persona ID=109 (René Condori Huanca)', '2026-07-26', '06:59:08'),
(766, NULL, 'DELETE', 'Eliminada persona ID=110 (Juana Quispe Apaza)', '2026-07-26', '06:59:08'),
(767, NULL, 'DELETE', 'Eliminada persona ID=111 (Boris Mamani Flores)', '2026-07-26', '06:59:08'),
(768, NULL, 'DELETE', 'Eliminada persona ID=112 (Teresa Ticona Laura)', '2026-07-26', '06:59:08'),
(769, NULL, 'DELETE', 'Eliminada persona ID=113 (Antonio Huanca Mamani)', '2026-07-26', '06:59:08'),
(770, NULL, 'DELETE', 'Eliminada persona ID=114 (Susana Apaza Condori)', '2026-07-26', '06:59:08'),
(771, NULL, 'DELETE', 'Eliminada persona ID=115 (Ramiro Laura Quispe)', '2026-07-26', '06:59:08'),
(772, NULL, 'DELETE', 'Eliminada persona ID=116 (Elena Flores Apaza)', '2026-07-26', '06:59:08'),
(773, NULL, 'DELETE', 'Eliminada persona ID=157 (Víctor Hugo Mamani Quispe)', '2026-07-26', '06:59:08'),
(774, NULL, 'DELETE', 'Eliminada persona ID=158 (Beatriz Flores Apaza)', '2026-07-26', '06:59:08'),
(775, NULL, 'DELETE', 'Eliminada persona ID=159 (Francisco Condori Mamani)', '2026-07-26', '06:59:08'),
(776, NULL, 'DELETE', 'Eliminada persona ID=160 (Natalia Ticona Laura)', '2026-07-26', '06:59:08'),
(777, NULL, 'DELETE', 'Eliminada persona ID=161 (Ángel Huanca Pari)', '2026-07-26', '06:59:08'),
(778, NULL, 'DELETE', 'Eliminada persona ID=162 (Katherine Apaza Flores)', '2026-07-26', '06:59:08'),
(779, NULL, 'DELETE', 'Eliminada persona ID=163 (David Mamani Condori)', '2026-07-26', '06:59:08'),
(780, NULL, 'DELETE', 'Eliminada persona ID=164 (Fabiola Laura Quispe)', '2026-07-26', '06:59:08'),
(781, NULL, 'DELETE', 'Eliminada persona ID=165 (Ernesto Flores Ticona)', '2026-07-26', '06:59:08'),
(782, NULL, 'DELETE', 'Eliminada persona ID=166 (Cecilia Condori Huanca)', '2026-07-26', '06:59:08'),
(783, NULL, 'DELETE', 'Eliminada persona ID=167 (Marco Antonio Quispe Mamani)', '2026-07-26', '06:59:08'),
(784, NULL, 'DELETE', 'Eliminada persona ID=168 (Liliana Ticona Apaza)', '2026-07-26', '06:59:08'),
(785, NULL, 'DELETE', 'Eliminada persona ID=169 (Rolando Mamani Flores)', '2026-07-26', '06:59:08'),
(786, NULL, 'DELETE', 'Eliminada persona ID=170 (Paola Huanca Laura)', '2026-07-26', '06:59:08'),
(787, NULL, 'DELETE', 'Eliminada persona ID=171 (Sergio Apaza Condori)', '2026-07-26', '06:59:08'),
(788, NULL, 'DELETE', 'Eliminada persona ID=172 (Adriana Laura Quispe)', '2026-07-26', '06:59:08'),
(789, NULL, 'DELETE', 'Eliminada persona ID=173 (Enrique Flores Mamani)', '2026-07-26', '06:59:08'),
(790, NULL, 'DELETE', 'Eliminada persona ID=174 (Diana Condori Apaza)', '2026-07-26', '06:59:08'),
(791, NULL, 'DELETE', 'Eliminada persona ID=175 (Jaime Quispe Ticona)', '2026-07-26', '06:59:08'),
(792, NULL, 'DELETE', 'Eliminada persona ID=176 (Ximena Mamani Laura)', '2026-07-26', '06:59:08'),
(793, NULL, 'DELETE', 'Eliminada persona ID=177 (Guillermo Ticona Flores)', '2026-07-26', '06:59:08'),
(794, NULL, 'DELETE', 'Eliminada persona ID=178 (Lorena Apaza Huanca)', '2026-07-26', '06:59:08'),
(795, NULL, 'DELETE', 'Eliminada persona ID=179 (Rafael Laura Condori)', '2026-07-26', '06:59:08'),
(796, NULL, 'DELETE', 'Eliminada persona ID=180 (Soledad Flores Quispe)', '2026-07-26', '06:59:08'),
(797, NULL, 'DELETE', 'Eliminada persona ID=181 (Alfonso Condori Mamani)', '2026-07-26', '06:59:08'),
(798, NULL, 'DELETE', 'Eliminada persona ID=182 (Miriam Quispe Apaza)', '2026-07-26', '06:59:08'),
(799, NULL, 'DELETE', 'Eliminada persona ID=183 (Humberto Mamani Ticona)', '2026-07-26', '06:59:08'),
(800, NULL, 'DELETE', 'Eliminada persona ID=184 (Gladys Huanca Flores)', '2026-07-26', '06:59:08'),
(801, NULL, 'DELETE', 'Eliminada persona ID=185 (Mauricio Ticona Laura)', '2026-07-26', '06:59:08'),
(802, NULL, 'DELETE', 'Eliminada persona ID=186 (Sandra Apaza Mamani)', '2026-07-26', '06:59:08'),
(803, NULL, 'DELETE', 'Eliminada persona ID=187 (Leonardo Laura Condori)', '2026-07-26', '06:59:08'),
(804, NULL, 'DELETE', 'Eliminada persona ID=188 (Elizabeth Flores Quispe)', '2026-07-26', '06:59:08'),
(805, NULL, 'DELETE', 'Eliminada persona ID=189 (Rodrigo Condori Huanca)', '2026-07-26', '06:59:08'),
(806, NULL, 'DELETE', 'Eliminada persona ID=190 (Marisol Quispe Apaza)', '2026-07-26', '06:59:08'),
(807, NULL, 'DELETE', 'Eliminada persona ID=191 (Omar Mamani Flores)', '2026-07-26', '06:59:08'),
(808, NULL, 'DELETE', 'Eliminada persona ID=192 (Tania Ticona Laura)', '2026-07-26', '06:59:08'),
(809, NULL, 'DELETE', 'Eliminada persona ID=193 (Felipe Huanca Mamani)', '2026-07-26', '06:59:08'),
(810, NULL, 'DELETE', 'Eliminada persona ID=194 (Rocío Apaza Condori)', '2026-07-26', '06:59:08'),
(811, NULL, 'DELETE', 'Eliminada persona ID=195 (Esteban Laura Quispe)', '2026-07-26', '06:59:08'),
(812, NULL, 'DELETE', 'Eliminada persona ID=196 (Carla Flores Apaza)', '2026-07-26', '06:59:08'),
(813, NULL, 'DELETE', 'Eliminada persona ID=197 (Iván Condori Mamani)', '2026-07-26', '06:59:08'),
(814, NULL, 'DELETE', 'Eliminada persona ID=198 (Noemí Quispe Ticona)', '2026-07-26', '06:59:08'),
(815, NULL, 'DELETE', 'Eliminada persona ID=199 (Arturo Mamani Laura)', '2026-07-26', '06:59:08'),
(816, NULL, 'DELETE', 'Eliminada persona ID=200 (Jacqueline Ticona Flores)', '2026-07-26', '06:59:08'),
(817, NULL, 'DELETE', 'Eliminada persona ID=201 (Raúl Huanca Quispe)', '2026-07-26', '06:59:08'),
(818, NULL, 'DELETE', 'Eliminada persona ID=202 (Viviana Apaza Mamani)', '2026-07-26', '06:59:08'),
(819, NULL, 'DELETE', 'Eliminada persona ID=203 (Fabián Laura Flores)', '2026-07-26', '06:59:08'),
(820, NULL, 'DELETE', 'Eliminada persona ID=204 (Marlene Condori Apaza)', '2026-07-26', '06:59:08'),
(821, NULL, 'DELETE', 'Eliminada persona ID=205 (Cristian Mamani Huanca)', '2026-07-26', '06:59:08'),
(822, NULL, 'DELETE', 'Eliminada persona ID=206 (Pamela Quispe Laura)', '2026-07-26', '06:59:08'),
(823, NULL, 'DELETE', 'Eliminada persona ID=207 (Gonzalo Flores Condori)', '2026-07-26', '06:59:08'),
(824, NULL, 'DELETE', 'Eliminada persona ID=208 (Erika Ticona Mamani)', '2026-07-26', '06:59:08'),
(825, NULL, 'DELETE', 'Eliminada persona ID=209 (Martín Huanca Apaza)', '2026-07-26', '06:59:08'),
(826, NULL, 'DELETE', 'Eliminada persona ID=210 (Alejandra Apaza Laura)', '2026-07-26', '06:59:08'),
(827, NULL, 'DELETE', 'Eliminada persona ID=211 (Joaquín Mamani Quispe)', '2026-07-26', '06:59:08'),
(828, NULL, 'DELETE', 'Eliminada persona ID=212 (Rebeca Condori Flores)', '2026-07-26', '06:59:08'),
(829, NULL, 'DELETE', 'Eliminada persona ID=213 (Hernán Laura Ticona)', '2026-07-26', '06:59:08'),
(830, NULL, 'DELETE', 'Eliminada persona ID=214 (Mabel Quispe Mamani)', '2026-07-26', '06:59:08'),
(831, NULL, 'DELETE', 'Eliminada persona ID=215 (Rubén Flores Apaza)', '2026-07-26', '06:59:08'),
(832, NULL, 'DELETE', 'Eliminada persona ID=216 (Yésica Ticona Laura)', '2026-07-26', '06:59:08'),
(833, NULL, 'INSERT', 'Nueva persona: Juan Carlos Mamani Quispe (CI: 2000101LP)', '2026-07-26', '06:59:50'),
(834, NULL, 'INSERT', 'Nuevo estudiante RU=1006000 Plan=1 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(835, 77, 'INSERT', 'Creación de usuario: jmamaniq', '2026-07-26', '06:59:50'),
(836, NULL, 'INSERT', 'Nueva persona: María Elena Flores Apaza (CI: 2000102LP)', '2026-07-26', '06:59:50'),
(837, NULL, 'INSERT', 'Nuevo estudiante RU=1006001 Plan=2 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(838, 78, 'INSERT', 'Creación de usuario: mfloresa', '2026-07-26', '06:59:50'),
(839, NULL, 'INSERT', 'Nueva persona: Pedro Luis Condori Mamani (CI: 2000103LP)', '2026-07-26', '06:59:50'),
(840, NULL, 'INSERT', 'Nuevo estudiante RU=1006002 Plan=3 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(841, 79, 'INSERT', 'Creación de usuario: pcondorim', '2026-07-26', '06:59:50'),
(842, NULL, 'INSERT', 'Nueva persona: Ana María Ticona Laura (CI: 2000104LP)', '2026-07-26', '06:59:50'),
(843, NULL, 'INSERT', 'Nuevo estudiante RU=1006003 Plan=4 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(844, 80, 'INSERT', 'Creación de usuario: aticonal', '2026-07-26', '06:59:50'),
(845, NULL, 'INSERT', 'Nueva persona: José Antonio Huanca Pari (CI: 2000105LP)', '2026-07-26', '06:59:50'),
(846, NULL, 'INSERT', 'Nuevo estudiante RU=1006004 Plan=5 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(847, 81, 'INSERT', 'Creación de usuario: jhuancap', '2026-07-26', '06:59:50'),
(848, NULL, 'INSERT', 'Nueva persona: Rosa Elena Apaza Flores (CI: 2000106LP)', '2026-07-26', '06:59:50'),
(849, NULL, 'INSERT', 'Nuevo estudiante RU=1006005 Plan=6 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(850, 82, 'INSERT', 'Creación de usuario: rapazaf', '2026-07-26', '06:59:50'),
(851, NULL, 'INSERT', 'Nueva persona: Carlos Alberto Mamani Condori (CI: 2000107LP)', '2026-07-26', '06:59:50'),
(852, NULL, 'INSERT', 'Nuevo estudiante RU=1006006 Plan=7 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(853, 83, 'INSERT', 'Creación de usuario: cmamanic', '2026-07-26', '06:59:50'),
(854, NULL, 'INSERT', 'Nueva persona: Patricia Laura Quispe (CI: 2000108LP)', '2026-07-26', '06:59:50'),
(855, NULL, 'INSERT', 'Nuevo estudiante RU=1006007 Plan=8 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(856, 84, 'INSERT', 'Creación de usuario: plauraq', '2026-07-26', '06:59:50'),
(857, NULL, 'INSERT', 'Nueva persona: Miguel Ángel Flores Ticona (CI: 2000109LP)', '2026-07-26', '06:59:50'),
(858, NULL, 'INSERT', 'Nuevo estudiante RU=1006008 Plan=9 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(859, 85, 'INSERT', 'Creación de usuario: mflorest', '2026-07-26', '06:59:50'),
(860, NULL, 'INSERT', 'Nueva persona: Sonia Condori Huanca (CI: 2000110LP)', '2026-07-26', '06:59:50'),
(861, NULL, 'INSERT', 'Nuevo estudiante RU=1006009 Plan=10 Ingreso=I/1990', '2026-07-26', '06:59:50'),
(862, 86, 'INSERT', 'Creación de usuario: scondorih', '2026-07-26', '06:59:50'),
(863, NULL, 'INSERT', 'Nueva persona: Roberto Quispe Mamani (CI: 2000111LP)', '2026-07-26', '06:59:50'),
(864, NULL, 'INSERT', 'Nuevo estudiante RU=1006010 Plan=1 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(865, 87, 'INSERT', 'Creación de usuario: rquispem', '2026-07-26', '06:59:50'),
(866, NULL, 'INSERT', 'Nueva persona: Carmen Ticona Apaza (CI: 2000112LP)', '2026-07-26', '06:59:50'),
(867, NULL, 'INSERT', 'Nuevo estudiante RU=1006011 Plan=2 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(868, 88, 'INSERT', 'Creación de usuario: cticonaa', '2026-07-26', '06:59:50'),
(869, NULL, 'INSERT', 'Nueva persona: Fernando Mamani Flores (CI: 2000113LP)', '2026-07-26', '06:59:50'),
(870, NULL, 'INSERT', 'Nuevo estudiante RU=1006012 Plan=3 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(871, 89, 'INSERT', 'Creación de usuario: fmamanif', '2026-07-26', '06:59:50'),
(872, NULL, 'INSERT', 'Nueva persona: Gloria Huanca Laura (CI: 2000114LP)', '2026-07-26', '06:59:50'),
(873, NULL, 'INSERT', 'Nuevo estudiante RU=1006013 Plan=4 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(874, 90, 'INSERT', 'Creación de usuario: ghuancal', '2026-07-26', '06:59:50'),
(875, NULL, 'INSERT', 'Nueva persona: Ricardo Apaza Condori (CI: 2000115LP)', '2026-07-26', '06:59:50'),
(876, NULL, 'INSERT', 'Nuevo estudiante RU=1006014 Plan=5 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(877, 91, 'INSERT', 'Creación de usuario: rapazac', '2026-07-26', '06:59:50'),
(878, NULL, 'INSERT', 'Nueva persona: Nancy Laura Quispe (CI: 2000116LP)', '2026-07-26', '06:59:50'),
(879, NULL, 'INSERT', 'Nuevo estudiante RU=1006015 Plan=6 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(880, 92, 'INSERT', 'Creación de usuario: nlauraq', '2026-07-26', '06:59:50'),
(881, NULL, 'INSERT', 'Nueva persona: Eduardo Flores Mamani (CI: 2000117LP)', '2026-07-26', '06:59:50'),
(882, NULL, 'INSERT', 'Nuevo estudiante RU=1006016 Plan=7 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(883, 93, 'INSERT', 'Creación de usuario: efloresm', '2026-07-26', '06:59:50'),
(884, NULL, 'INSERT', 'Nueva persona: Verónica Condori Apaza (CI: 2000118LP)', '2026-07-26', '06:59:50'),
(885, NULL, 'INSERT', 'Nuevo estudiante RU=1006017 Plan=8 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(886, 94, 'INSERT', 'Creación de usuario: vcondoria', '2026-07-26', '06:59:50'),
(887, NULL, 'INSERT', 'Nueva persona: Mario Quispe Ticona (CI: 2000119LP)', '2026-07-26', '06:59:50'),
(888, NULL, 'INSERT', 'Nuevo estudiante RU=1006018 Plan=9 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(889, 95, 'INSERT', 'Creación de usuario: mquispet', '2026-07-26', '06:59:50'),
(890, NULL, 'INSERT', 'Nueva persona: Claudia Mamani Laura (CI: 2000120LP)', '2026-07-26', '06:59:50'),
(891, NULL, 'INSERT', 'Nuevo estudiante RU=1006019 Plan=10 Ingreso=II/1990', '2026-07-26', '06:59:50'),
(892, 96, 'INSERT', 'Creación de usuario: cmamanil', '2026-07-26', '06:59:50'),
(893, NULL, 'INSERT', 'Nueva persona: Héctor Ticona Flores (CI: 2000121LP)', '2026-07-26', '06:59:50'),
(894, NULL, 'INSERT', 'Nuevo estudiante RU=1006020 Plan=1 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(895, 97, 'INSERT', 'Creación de usuario: hticonaf', '2026-07-26', '06:59:50'),
(896, NULL, 'INSERT', 'Nueva persona: Daniela Apaza Huanca (CI: 2000122LP)', '2026-07-26', '06:59:50'),
(897, NULL, 'INSERT', 'Nuevo estudiante RU=1006021 Plan=2 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(898, 98, 'INSERT', 'Creación de usuario: dapazah', '2026-07-26', '06:59:50'),
(899, NULL, 'INSERT', 'Nueva persona: Gustavo Laura Condori (CI: 2000123LP)', '2026-07-26', '06:59:50'),
(900, NULL, 'INSERT', 'Nuevo estudiante RU=1006022 Plan=3 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(901, 99, 'INSERT', 'Creación de usuario: glaurac', '2026-07-26', '06:59:50'),
(902, NULL, 'INSERT', 'Nueva persona: Mónica Flores Quispe (CI: 2000124LP)', '2026-07-26', '06:59:50'),
(903, NULL, 'INSERT', 'Nuevo estudiante RU=1006023 Plan=4 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(904, 100, 'INSERT', 'Creación de usuario: mfloresq', '2026-07-26', '06:59:50'),
(905, NULL, 'INSERT', 'Nueva persona: Alejandro Condori Mamani (CI: 2000125LP)', '2026-07-26', '06:59:50'),
(906, NULL, 'INSERT', 'Nuevo estudiante RU=1006024 Plan=5 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(907, 101, 'INSERT', 'Creación de usuario: acondorim', '2026-07-26', '06:59:50'),
(908, NULL, 'INSERT', 'Nueva persona: Roxana Quispe Apaza (CI: 2000126LP)', '2026-07-26', '06:59:50'),
(909, NULL, 'INSERT', 'Nuevo estudiante RU=1006025 Plan=6 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(910, 102, 'INSERT', 'Creación de usuario: rquispea1', '2026-07-26', '06:59:50'),
(911, NULL, 'INSERT', 'Nueva persona: Pablo Mamani Ticona (CI: 2000127LP)', '2026-07-26', '06:59:50'),
(912, NULL, 'INSERT', 'Nuevo estudiante RU=1006026 Plan=7 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(913, 103, 'INSERT', 'Creación de usuario: pmamanit', '2026-07-26', '06:59:50'),
(914, NULL, 'INSERT', 'Nueva persona: Yolanda Huanca Flores (CI: 2000128LP)', '2026-07-26', '06:59:50'),
(915, NULL, 'INSERT', 'Nuevo estudiante RU=1006027 Plan=8 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(916, 104, 'INSERT', 'Creación de usuario: yhuancaf', '2026-07-26', '06:59:50'),
(917, NULL, 'INSERT', 'Nueva persona: Christian Ticona Laura (CI: 2000129LP)', '2026-07-26', '06:59:50'),
(918, NULL, 'INSERT', 'Nuevo estudiante RU=1006028 Plan=9 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(919, 105, 'INSERT', 'Creación de usuario: cticonal', '2026-07-26', '06:59:50'),
(920, NULL, 'INSERT', 'Nueva persona: Silvia Apaza Mamani (CI: 2000130LP)', '2026-07-26', '06:59:50'),
(921, NULL, 'INSERT', 'Nuevo estudiante RU=1006029 Plan=10 Ingreso=I/1991', '2026-07-26', '06:59:50'),
(922, 106, 'INSERT', 'Creación de usuario: sapazam', '2026-07-26', '06:59:50'),
(923, NULL, 'INSERT', 'Nueva persona: Oscar Laura Condori (CI: 2000131LP)', '2026-07-26', '06:59:50'),
(924, NULL, 'INSERT', 'Nuevo estudiante RU=1006030 Plan=1 Ingreso=II/1991', '2026-07-26', '06:59:50'),
(925, 107, 'INSERT', 'Creación de usuario: olaurac', '2026-07-26', '06:59:50'),
(926, NULL, 'INSERT', 'Nueva persona: Marcela Flores Quispe (CI: 2000132LP)', '2026-07-26', '06:59:50'),
(927, NULL, 'INSERT', 'Nuevo estudiante RU=1006031 Plan=2 Ingreso=II/1991', '2026-07-26', '06:59:50'),
(928, 108, 'INSERT', 'Creación de usuario: mfloresq1', '2026-07-26', '06:59:50'),
(929, NULL, 'INSERT', 'Nueva persona: René Condori Huanca (CI: 2000133LP)', '2026-07-26', '06:59:50'),
(930, NULL, 'INSERT', 'Nuevo estudiante RU=1006032 Plan=3 Ingreso=II/1991', '2026-07-26', '06:59:50'),
(931, 109, 'INSERT', 'Creación de usuario: rcondorih', '2026-07-26', '06:59:50'),
(932, NULL, 'INSERT', 'Nueva persona: Juana Quispe Apaza (CI: 2000134LP)', '2026-07-26', '06:59:50'),
(933, NULL, 'INSERT', 'Nuevo estudiante RU=1006033 Plan=4 Ingreso=II/1991', '2026-07-26', '06:59:50'),
(934, 110, 'INSERT', 'Creación de usuario: jquispea', '2026-07-26', '06:59:50'),
(935, NULL, 'INSERT', 'Nueva persona: Boris Mamani Flores (CI: 2000135LP)', '2026-07-26', '06:59:51'),
(936, NULL, 'INSERT', 'Nuevo estudiante RU=1006034 Plan=5 Ingreso=II/1991', '2026-07-26', '06:59:51'),
(937, 111, 'INSERT', 'Creación de usuario: bmamanif', '2026-07-26', '06:59:51'),
(938, NULL, 'INSERT', 'Nueva persona: Teresa Ticona Laura (CI: 2000136LP)', '2026-07-26', '06:59:51'),
(939, NULL, 'INSERT', 'Nuevo estudiante RU=1006035 Plan=6 Ingreso=II/1991', '2026-07-26', '06:59:51'),
(940, 112, 'INSERT', 'Creación de usuario: tticonal', '2026-07-26', '06:59:51'),
(941, NULL, 'INSERT', 'Nueva persona: Antonio Huanca Mamani (CI: 2000137LP)', '2026-07-26', '06:59:51'),
(942, NULL, 'INSERT', 'Nuevo estudiante RU=1006036 Plan=7 Ingreso=II/1991', '2026-07-26', '06:59:51'),
(943, 113, 'INSERT', 'Creación de usuario: ahuancam', '2026-07-26', '06:59:51'),
(944, NULL, 'INSERT', 'Nueva persona: Susana Apaza Condori (CI: 2000138LP)', '2026-07-26', '06:59:51'),
(945, NULL, 'INSERT', 'Nuevo estudiante RU=1006037 Plan=8 Ingreso=II/1991', '2026-07-26', '06:59:51'),
(946, 114, 'INSERT', 'Creación de usuario: sapazac', '2026-07-26', '06:59:51'),
(947, NULL, 'INSERT', 'Nueva persona: Ramiro Laura Quispe (CI: 2000139LP)', '2026-07-26', '06:59:51'),
(948, NULL, 'INSERT', 'Nuevo estudiante RU=1006038 Plan=9 Ingreso=II/1991', '2026-07-26', '06:59:51'),
(949, 115, 'INSERT', 'Creación de usuario: rlauraq', '2026-07-26', '06:59:51'),
(950, NULL, 'INSERT', 'Nueva persona: Elena Flores Apaza (CI: 2000140LP)', '2026-07-26', '06:59:51'),
(951, NULL, 'INSERT', 'Nuevo estudiante RU=1006039 Plan=10 Ingreso=II/1991', '2026-07-26', '06:59:51'),
(952, 116, 'INSERT', 'Creación de usuario: efloresa', '2026-07-26', '06:59:51'),
(953, NULL, 'INSERT', 'Nueva persona: Víctor Hugo Mamani Quispe (CI: 2000141LP)', '2026-07-26', '07:04:31'),
(954, NULL, 'INSERT', 'Nuevo estudiante RU=1006040 Plan=1 Ingreso=I/1992', '2026-07-26', '07:04:31'),
(955, 117, 'INSERT', 'Creación de usuario: vmamaniq', '2026-07-26', '07:04:31'),
(956, NULL, 'INSERT', 'Nueva persona: Andrea Mamani Quispe (CI: 2000201LP)', '2026-07-26', '07:05:24'),
(957, NULL, 'INSERT', 'Nuevo estudiante RU=1006041 Plan=1 Ingreso=I/1995', '2026-07-26', '07:05:24'),
(958, 118, 'INSERT', 'Creación de usuario: amamaniq', '2026-07-26', '07:05:24'),
(959, NULL, 'INSERT', 'Nueva persona: Francisco Condori Mamani (CI: 2000143LP)', '2026-07-26', '07:09:40'),
(960, NULL, 'INSERT', 'Nuevo estudiante RU=1006042 Plan=3 Ingreso=I/1992', '2026-07-26', '07:09:40'),
(961, 119, 'INSERT', 'Creación de usuario: fcondorim', '2026-07-26', '07:09:40'),
(962, NULL, 'INSERT', 'Nueva persona: Natalia Ticona Laura (CI: 2000144LP)', '2026-07-26', '07:09:40'),
(963, NULL, 'INSERT', 'Nuevo estudiante RU=1006043 Plan=4 Ingreso=I/1992', '2026-07-26', '07:09:40'),
(964, 120, 'INSERT', 'Creación de usuario: nticonal', '2026-07-26', '07:09:40'),
(965, NULL, 'INSERT', 'Nueva persona: Ángel Huanca Pari (CI: 2000145LP)', '2026-07-26', '07:09:40'),
(966, NULL, 'INSERT', 'Nuevo estudiante RU=1006044 Plan=5 Ingreso=I/1992', '2026-07-26', '07:09:40'),
(967, 121, 'INSERT', 'Creación de usuario: áhuancap', '2026-07-26', '07:09:40'),
(968, NULL, 'INSERT', 'Nueva persona: Katherine Apaza Flores (CI: 2000146LP)', '2026-07-26', '07:09:40'),
(969, NULL, 'INSERT', 'Nuevo estudiante RU=1006045 Plan=6 Ingreso=I/1992', '2026-07-26', '07:09:40'),
(970, 122, 'INSERT', 'Creación de usuario: kapazaf', '2026-07-26', '07:09:40'),
(971, NULL, 'INSERT', 'Nueva persona: David Mamani Condori (CI: 2000147LP)', '2026-07-26', '07:09:41'),
(972, NULL, 'INSERT', 'Nuevo estudiante RU=1006046 Plan=7 Ingreso=I/1992', '2026-07-26', '07:09:41'),
(973, 123, 'INSERT', 'Creación de usuario: dmamanic', '2026-07-26', '07:09:41'),
(974, NULL, 'INSERT', 'Nueva persona: Fabiola Laura Quispe (CI: 2000148LP)', '2026-07-26', '07:09:41'),
(975, NULL, 'INSERT', 'Nuevo estudiante RU=1006047 Plan=8 Ingreso=I/1992', '2026-07-26', '07:09:41'),
(976, 124, 'INSERT', 'Creación de usuario: flauraq', '2026-07-26', '07:09:41'),
(977, NULL, 'INSERT', 'Nueva persona: Ernesto Flores Ticona (CI: 2000149LP)', '2026-07-26', '07:09:41'),
(978, NULL, 'INSERT', 'Nuevo estudiante RU=1006048 Plan=9 Ingreso=I/1992', '2026-07-26', '07:09:41'),
(979, 125, 'INSERT', 'Creación de usuario: eflorest', '2026-07-26', '07:09:41'),
(980, NULL, 'INSERT', 'Nueva persona: Cecilia Condori Huanca (CI: 2000150LP)', '2026-07-26', '07:09:41'),
(981, NULL, 'INSERT', 'Nuevo estudiante RU=1006049 Plan=10 Ingreso=I/1992', '2026-07-26', '07:09:41'),
(982, 126, 'INSERT', 'Creación de usuario: ccondorih', '2026-07-26', '07:09:41'),
(983, NULL, 'INSERT', 'Nueva persona: Marco Antonio Quispe Mamani (CI: 2000151LP)', '2026-07-26', '07:11:03'),
(984, NULL, 'INSERT', 'Nuevo estudiante RU=1006050 Plan=1 Ingreso=II/1992', '2026-07-26', '07:11:03'),
(985, 127, 'INSERT', 'Creación de usuario: mquispem', '2026-07-26', '07:11:03'),
(986, NULL, 'INSERT', 'Nueva persona: Liliana Ticona Apaza (CI: 2000152LP)', '2026-07-26', '07:11:39'),
(987, NULL, 'INSERT', 'Nuevo estudiante RU=1006051 Plan=2 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(988, 128, 'INSERT', 'Creación de usuario: lticonaa', '2026-07-26', '07:11:39'),
(989, NULL, 'INSERT', 'Nueva persona: Rolando Mamani Flores (CI: 2000153LP)', '2026-07-26', '07:11:39'),
(990, NULL, 'INSERT', 'Nuevo estudiante RU=1006052 Plan=3 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(991, 129, 'INSERT', 'Creación de usuario: rmamanif', '2026-07-26', '07:11:39'),
(992, NULL, 'INSERT', 'Nueva persona: Paola Huanca Laura (CI: 2000154LP)', '2026-07-26', '07:11:39'),
(993, NULL, 'INSERT', 'Nuevo estudiante RU=1006053 Plan=4 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(994, 130, 'INSERT', 'Creación de usuario: phuancal', '2026-07-26', '07:11:39'),
(995, NULL, 'INSERT', 'Nueva persona: Sergio Apaza Condori (CI: 2000155LP)', '2026-07-26', '07:11:39'),
(996, NULL, 'INSERT', 'Nuevo estudiante RU=1006054 Plan=5 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(997, 131, 'INSERT', 'Creación de usuario: sapazac1', '2026-07-26', '07:11:39'),
(998, NULL, 'INSERT', 'Nueva persona: Adriana Laura Quispe (CI: 2000156LP)', '2026-07-26', '07:11:39'),
(999, NULL, 'INSERT', 'Nuevo estudiante RU=1006055 Plan=6 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(1000, 132, 'INSERT', 'Creación de usuario: alauraq', '2026-07-26', '07:11:39'),
(1001, NULL, 'INSERT', 'Nueva persona: Enrique Flores Mamani (CI: 2000157LP)', '2026-07-26', '07:11:39'),
(1002, NULL, 'INSERT', 'Nuevo estudiante RU=1006056 Plan=7 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(1003, 133, 'INSERT', 'Creación de usuario: efloresm1', '2026-07-26', '07:11:39'),
(1004, NULL, 'INSERT', 'Nueva persona: Diana Condori Apaza (CI: 2000158LP)', '2026-07-26', '07:11:39'),
(1005, NULL, 'INSERT', 'Nuevo estudiante RU=1006057 Plan=8 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(1006, 134, 'INSERT', 'Creación de usuario: dcondoria', '2026-07-26', '07:11:39'),
(1007, NULL, 'INSERT', 'Nueva persona: Jaime Quispe Ticona (CI: 2000159LP)', '2026-07-26', '07:11:39'),
(1008, NULL, 'INSERT', 'Nuevo estudiante RU=1006058 Plan=9 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(1009, 135, 'INSERT', 'Creación de usuario: jquispet', '2026-07-26', '07:11:39'),
(1010, NULL, 'INSERT', 'Nueva persona: Ximena Mamani Laura (CI: 2000160LP)', '2026-07-26', '07:11:39'),
(1011, NULL, 'INSERT', 'Nuevo estudiante RU=1006059 Plan=10 Ingreso=II/1992', '2026-07-26', '07:11:39'),
(1012, 136, 'INSERT', 'Creación de usuario: xmamanil', '2026-07-26', '07:11:39'),
(1013, NULL, 'INSERT', 'Nueva persona: Guillermo Ticona Flores (CI: 2000161LP)', '2026-07-26', '07:15:11'),
(1014, NULL, 'INSERT', 'Nuevo estudiante RU=1006060 Plan=1 Ingreso=I/1993', '2026-07-26', '07:15:11'),
(1015, 137, 'INSERT', 'Creación de usuario: gticonaf', '2026-07-26', '07:15:11'),
(1016, NULL, 'INSERT', 'Nueva persona: Lorena Apaza Huanca (CI: 2000162LP)', '2026-07-26', '07:15:11'),
(1017, NULL, 'INSERT', 'Nuevo estudiante RU=1006061 Plan=2 Ingreso=I/1993', '2026-07-26', '07:15:11'),
(1018, 138, 'INSERT', 'Creación de usuario: lapazah', '2026-07-26', '07:15:11'),
(1019, NULL, 'INSERT', 'Nueva persona: Rafael Laura Condori (CI: 2000163LP)', '2026-07-26', '07:15:11'),
(1020, NULL, 'INSERT', 'Nuevo estudiante RU=1006062 Plan=3 Ingreso=I/1993', '2026-07-26', '07:15:11'),
(1021, 139, 'INSERT', 'Creación de usuario: rlaurac', '2026-07-26', '07:15:11'),
(1022, NULL, 'INSERT', 'Nueva persona: Soledad Flores Quispe (CI: 2000164LP)', '2026-07-26', '07:15:11'),
(1023, NULL, 'INSERT', 'Nuevo estudiante RU=1006063 Plan=4 Ingreso=I/1993', '2026-07-26', '07:15:11'),
(1024, 140, 'INSERT', 'Creación de usuario: sfloresq', '2026-07-26', '07:15:11'),
(1025, NULL, 'INSERT', 'Nueva persona: Alfonso Condori Mamani (CI: 2000165LP)', '2026-07-26', '07:15:11'),
(1026, NULL, 'INSERT', 'Nuevo estudiante RU=1006064 Plan=5 Ingreso=I/1993', '2026-07-26', '07:15:11'),
(1027, 141, 'INSERT', 'Creación de usuario: acondorim1', '2026-07-26', '07:15:11'),
(1028, NULL, 'INSERT', 'Nueva persona: Miriam Quispe Apaza (CI: 2000166LP)', '2026-07-26', '07:15:20'),
(1029, NULL, 'INSERT', 'Nuevo estudiante RU=1006065 Plan=6 Ingreso=I/1993', '2026-07-26', '07:15:20'),
(1030, 142, 'INSERT', 'Creación de usuario: mquispea', '2026-07-26', '07:15:20'),
(1031, NULL, 'INSERT', 'Nueva persona: Humberto Mamani Ticona (CI: 2000167LP)', '2026-07-26', '07:15:20'),
(1032, NULL, 'INSERT', 'Nuevo estudiante RU=1006066 Plan=7 Ingreso=I/1993', '2026-07-26', '07:15:20'),
(1033, 143, 'INSERT', 'Creación de usuario: hmamanit', '2026-07-26', '07:15:20'),
(1034, NULL, 'INSERT', 'Nueva persona: Gladys Huanca Flores (CI: 2000168LP)', '2026-07-26', '07:15:20'),
(1035, NULL, 'INSERT', 'Nuevo estudiante RU=1006067 Plan=8 Ingreso=I/1993', '2026-07-26', '07:15:20'),
(1036, 144, 'INSERT', 'Creación de usuario: ghuancaf', '2026-07-26', '07:15:20'),
(1037, NULL, 'INSERT', 'Nueva persona: Mauricio Ticona Laura (CI: 2000169LP)', '2026-07-26', '07:15:20'),
(1038, NULL, 'INSERT', 'Nuevo estudiante RU=1006068 Plan=9 Ingreso=I/1993', '2026-07-26', '07:15:20'),
(1039, 145, 'INSERT', 'Creación de usuario: mticonal', '2026-07-26', '07:15:20'),
(1040, NULL, 'INSERT', 'Nueva persona: Sandra Apaza Mamani (CI: 2000170LP)', '2026-07-26', '07:15:20'),
(1041, NULL, 'INSERT', 'Nuevo estudiante RU=1006069 Plan=10 Ingreso=I/1993', '2026-07-26', '07:15:20'),
(1042, 146, 'INSERT', 'Creación de usuario: sapazam1', '2026-07-26', '07:15:20'),
(1043, NULL, 'INSERT', 'Nueva persona: Leonardo Laura Condori (CI: 2000171LP)', '2026-07-26', '07:15:20'),
(1044, NULL, 'INSERT', 'Nuevo estudiante RU=1006070 Plan=1 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1045, 147, 'INSERT', 'Creación de usuario: llaurac', '2026-07-26', '07:15:20'),
(1046, NULL, 'INSERT', 'Nueva persona: Elizabeth Flores Quispe (CI: 2000172LP)', '2026-07-26', '07:15:20'),
(1047, NULL, 'INSERT', 'Nuevo estudiante RU=1006071 Plan=2 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1048, 148, 'INSERT', 'Creación de usuario: efloresq', '2026-07-26', '07:15:20'),
(1049, NULL, 'INSERT', 'Nueva persona: Rodrigo Condori Huanca (CI: 2000173LP)', '2026-07-26', '07:15:20'),
(1050, NULL, 'INSERT', 'Nuevo estudiante RU=1006072 Plan=3 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1051, 149, 'INSERT', 'Creación de usuario: rcondorih1', '2026-07-26', '07:15:20'),
(1052, NULL, 'INSERT', 'Nueva persona: Marisol Quispe Apaza (CI: 2000174LP)', '2026-07-26', '07:15:20'),
(1053, NULL, 'INSERT', 'Nuevo estudiante RU=1006073 Plan=4 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1054, 150, 'INSERT', 'Creación de usuario: mquispea1', '2026-07-26', '07:15:20'),
(1055, NULL, 'INSERT', 'Nueva persona: Omar Mamani Flores (CI: 2000175LP)', '2026-07-26', '07:15:20'),
(1056, NULL, 'INSERT', 'Nuevo estudiante RU=1006074 Plan=5 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1057, 151, 'INSERT', 'Creación de usuario: omamanif1', '2026-07-26', '07:15:20'),
(1058, NULL, 'INSERT', 'Nueva persona: Tania Ticona Laura (CI: 2000176LP)', '2026-07-26', '07:15:20'),
(1059, NULL, 'INSERT', 'Nuevo estudiante RU=1006075 Plan=6 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1060, 152, 'INSERT', 'Creación de usuario: tticonal1', '2026-07-26', '07:15:20'),
(1061, NULL, 'INSERT', 'Nueva persona: Felipe Huanca Mamani (CI: 2000177LP)', '2026-07-26', '07:15:20'),
(1062, NULL, 'INSERT', 'Nuevo estudiante RU=1006076 Plan=7 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1063, 153, 'INSERT', 'Creación de usuario: fhuancam', '2026-07-26', '07:15:20'),
(1064, NULL, 'INSERT', 'Nueva persona: Rocío Apaza Condori (CI: 2000178LP)', '2026-07-26', '07:15:20'),
(1065, NULL, 'INSERT', 'Nuevo estudiante RU=1006077 Plan=8 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1066, 154, 'INSERT', 'Creación de usuario: rapazac1', '2026-07-26', '07:15:20'),
(1067, NULL, 'INSERT', 'Nueva persona: Esteban Laura Quispe (CI: 2000179LP)', '2026-07-26', '07:15:20'),
(1068, NULL, 'INSERT', 'Nuevo estudiante RU=1006078 Plan=9 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1069, 155, 'INSERT', 'Creación de usuario: elauraq', '2026-07-26', '07:15:20'),
(1070, NULL, 'INSERT', 'Nueva persona: Carla Flores Apaza (CI: 2000180LP)', '2026-07-26', '07:15:20'),
(1071, NULL, 'INSERT', 'Nuevo estudiante RU=1006079 Plan=10 Ingreso=II/1993', '2026-07-26', '07:15:20'),
(1072, 156, 'INSERT', 'Creación de usuario: cfloresa', '2026-07-26', '07:15:20'),
(1073, NULL, 'INSERT', 'Nueva persona: Iván Condori Mamani (CI: 2000181LP)', '2026-07-26', '07:15:20'),
(1074, NULL, 'INSERT', 'Nuevo estudiante RU=1006080 Plan=1 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1075, 157, 'INSERT', 'Creación de usuario: icondorim', '2026-07-26', '07:15:20'),
(1076, NULL, 'INSERT', 'Nueva persona: Noemí Quispe Ticona (CI: 2000182LP)', '2026-07-26', '07:15:20'),
(1077, NULL, 'INSERT', 'Nuevo estudiante RU=1006081 Plan=2 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1078, 158, 'INSERT', 'Creación de usuario: nquispet', '2026-07-26', '07:15:20'),
(1079, NULL, 'INSERT', 'Nueva persona: Arturo Mamani Laura (CI: 2000183LP)', '2026-07-26', '07:15:20'),
(1080, NULL, 'INSERT', 'Nuevo estudiante RU=1006082 Plan=3 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1081, 159, 'INSERT', 'Creación de usuario: amamanil', '2026-07-26', '07:15:20'),
(1082, NULL, 'INSERT', 'Nueva persona: Jacqueline Ticona Flores (CI: 2000184LP)', '2026-07-26', '07:15:20'),
(1083, NULL, 'INSERT', 'Nuevo estudiante RU=1006083 Plan=4 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1084, 160, 'INSERT', 'Creación de usuario: jticonaf', '2026-07-26', '07:15:20'),
(1085, NULL, 'INSERT', 'Nueva persona: Raúl Huanca Quispe (CI: 2000185LP)', '2026-07-26', '07:15:20'),
(1086, NULL, 'INSERT', 'Nuevo estudiante RU=1006084 Plan=5 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1087, 161, 'INSERT', 'Creación de usuario: rhuancaq1', '2026-07-26', '07:15:20'),
(1088, NULL, 'INSERT', 'Nueva persona: Viviana Apaza Mamani (CI: 2000186LP)', '2026-07-26', '07:15:20'),
(1089, NULL, 'INSERT', 'Nuevo estudiante RU=1006085 Plan=6 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1090, 162, 'INSERT', 'Creación de usuario: vapazam', '2026-07-26', '07:15:20'),
(1091, NULL, 'INSERT', 'Nueva persona: Fabián Laura Flores (CI: 2000187LP)', '2026-07-26', '07:15:20'),
(1092, NULL, 'INSERT', 'Nuevo estudiante RU=1006086 Plan=7 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1093, 163, 'INSERT', 'Creación de usuario: flauraf', '2026-07-26', '07:15:20'),
(1094, NULL, 'INSERT', 'Nueva persona: Marlene Condori Apaza (CI: 2000188LP)', '2026-07-26', '07:15:20'),
(1095, NULL, 'INSERT', 'Nuevo estudiante RU=1006087 Plan=8 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1096, 164, 'INSERT', 'Creación de usuario: mcondoria', '2026-07-26', '07:15:20'),
(1097, NULL, 'INSERT', 'Nueva persona: Cristian Mamani Huanca (CI: 2000189LP)', '2026-07-26', '07:15:20'),
(1098, NULL, 'INSERT', 'Nuevo estudiante RU=1006088 Plan=9 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1099, 165, 'INSERT', 'Creación de usuario: cmamanih', '2026-07-26', '07:15:20'),
(1100, NULL, 'INSERT', 'Nueva persona: Pamela Quispe Laura (CI: 2000190LP)', '2026-07-26', '07:15:20'),
(1101, NULL, 'INSERT', 'Nuevo estudiante RU=1006089 Plan=10 Ingreso=I/1994', '2026-07-26', '07:15:20'),
(1102, 166, 'INSERT', 'Creación de usuario: pquispel', '2026-07-26', '07:15:20'),
(1103, NULL, 'INSERT', 'Nueva persona: Gonzalo Flores Condori (CI: 2000191LP)', '2026-07-26', '07:15:20'),
(1104, NULL, 'INSERT', 'Nuevo estudiante RU=1006090 Plan=1 Ingreso=II/1994', '2026-07-26', '07:15:20'),
(1105, 167, 'INSERT', 'Creación de usuario: gfloresc', '2026-07-26', '07:15:20'),
(1106, NULL, 'INSERT', 'Nueva persona: Erika Ticona Mamani (CI: 2000192LP)', '2026-07-26', '07:15:20'),
(1107, NULL, 'INSERT', 'Nuevo estudiante RU=1006091 Plan=2 Ingreso=II/1994', '2026-07-26', '07:15:20'),
(1108, 168, 'INSERT', 'Creación de usuario: eticonam', '2026-07-26', '07:15:20'),
(1109, NULL, 'INSERT', 'Nueva persona: Martín Huanca Apaza (CI: 2000193LP)', '2026-07-26', '07:15:20'),
(1110, NULL, 'INSERT', 'Nuevo estudiante RU=1006092 Plan=3 Ingreso=II/1994', '2026-07-26', '07:15:20'),
(1111, 169, 'INSERT', 'Creación de usuario: mhuancaa', '2026-07-26', '07:15:20'),
(1112, NULL, 'INSERT', 'Nueva persona: Alejandra Apaza Laura (CI: 2000194LP)', '2026-07-26', '07:15:20'),
(1113, NULL, 'INSERT', 'Nuevo estudiante RU=1006093 Plan=4 Ingreso=II/1994', '2026-07-26', '07:15:20'),
(1114, 170, 'INSERT', 'Creación de usuario: aapazal', '2026-07-26', '07:15:20'),
(1115, NULL, 'INSERT', 'Nueva persona: Joaquín Mamani Quispe (CI: 2000195LP)', '2026-07-26', '07:15:20'),
(1116, NULL, 'INSERT', 'Nuevo estudiante RU=1006094 Plan=5 Ingreso=II/1994', '2026-07-26', '07:15:20'),
(1117, 171, 'INSERT', 'Creación de usuario: jmamaniq1', '2026-07-26', '07:15:20'),
(1118, NULL, 'INSERT', 'Nueva persona: Rebeca Condori Flores (CI: 2000196LP)', '2026-07-26', '07:15:51'),
(1119, NULL, 'INSERT', 'Nuevo estudiante RU=1006095 Plan=6 Ingreso=II/1994', '2026-07-26', '07:15:51'),
(1120, 172, 'INSERT', 'Creación de usuario: rcondorif', '2026-07-26', '07:15:51'),
(1121, NULL, 'INSERT', 'Nueva persona: Hernán Laura Ticona (CI: 2000197LP)', '2026-07-26', '07:15:51'),
(1122, NULL, 'INSERT', 'Nuevo estudiante RU=1006096 Plan=7 Ingreso=II/1994', '2026-07-26', '07:15:51'),
(1123, 173, 'INSERT', 'Creación de usuario: hlaurat', '2026-07-26', '07:15:51'),
(1124, NULL, 'INSERT', 'Nueva persona: Mabel Quispe Mamani (CI: 2000198LP)', '2026-07-26', '07:15:51'),
(1125, NULL, 'INSERT', 'Nuevo estudiante RU=1006097 Plan=8 Ingreso=II/1994', '2026-07-26', '07:15:51'),
(1126, 174, 'INSERT', 'Creación de usuario: mquispem1', '2026-07-26', '07:15:51'),
(1127, NULL, 'INSERT', 'Nueva persona: Rubén Flores Apaza (CI: 2000199LP)', '2026-07-26', '07:15:51'),
(1128, NULL, 'INSERT', 'Nuevo estudiante RU=1006098 Plan=9 Ingreso=II/1994', '2026-07-26', '07:15:51'),
(1129, 175, 'INSERT', 'Creación de usuario: rfloresa', '2026-07-26', '07:15:51'),
(1130, NULL, 'INSERT', 'Nueva persona: Yésica Ticona Laura (CI: 2000200LP)', '2026-07-26', '07:15:51'),
(1131, NULL, 'INSERT', 'Nuevo estudiante RU=1006099 Plan=10 Ingreso=II/1994', '2026-07-26', '07:15:51'),
(1132, 176, 'INSERT', 'Creación de usuario: yticonal', '2026-07-26', '07:15:51'),
(1133, NULL, 'INSERT', 'Nueva persona: Andrea Mamani Quispe (CI: 2000301LP)', '2026-07-26', '07:17:35'),
(1134, NULL, 'INSERT', 'Nuevo estudiante RU=1006100 Plan=1 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1135, 177, 'INSERT', 'Creación de usuario: amamaniq1', '2026-07-26', '07:17:35'),
(1136, NULL, 'INSERT', 'Nueva persona: Nelson Flores Apaza (CI: 2000302LP)', '2026-07-26', '07:17:35'),
(1137, NULL, 'INSERT', 'Nuevo estudiante RU=1006101 Plan=2 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1138, 178, 'INSERT', 'Creación de usuario: nfloresa', '2026-07-26', '07:17:35'),
(1139, NULL, 'INSERT', 'Nueva persona: Leticia Condori Mamani (CI: 2000303LP)', '2026-07-26', '07:17:35'),
(1140, NULL, 'INSERT', 'Nuevo estudiante RU=1006102 Plan=3 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1141, 179, 'INSERT', 'Creación de usuario: lcondorim', '2026-07-26', '07:17:35'),
(1142, NULL, 'INSERT', 'Nueva persona: Hernando Ticona Laura (CI: 2000304LP)', '2026-07-26', '07:17:35'),
(1143, NULL, 'INSERT', 'Nuevo estudiante RU=1006103 Plan=4 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1144, 180, 'INSERT', 'Creación de usuario: hticonal', '2026-07-26', '07:17:35'),
(1145, NULL, 'INSERT', 'Nueva persona: Martha Huanca Pari (CI: 2000305LP)', '2026-07-26', '07:17:35'),
(1146, NULL, 'INSERT', 'Nuevo estudiante RU=1006104 Plan=5 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1147, 181, 'INSERT', 'Creación de usuario: mhuancap', '2026-07-26', '07:17:35'),
(1148, NULL, 'INSERT', 'Nueva persona: Wilson Apaza Flores (CI: 2000306LP)', '2026-07-26', '07:17:35'),
(1149, NULL, 'INSERT', 'Nuevo estudiante RU=1006105 Plan=6 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1150, 182, 'INSERT', 'Creación de usuario: wapazaf', '2026-07-26', '07:17:35'),
(1151, NULL, 'INSERT', 'Nueva persona: Rosario Mamani Condori (CI: 2000307LP)', '2026-07-26', '07:17:35'),
(1152, NULL, 'INSERT', 'Nuevo estudiante RU=1006106 Plan=7 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1153, 183, 'INSERT', 'Creación de usuario: rmamanic1', '2026-07-26', '07:17:35'),
(1154, NULL, 'INSERT', 'Nueva persona: Edwin Laura Quispe (CI: 2000308LP)', '2026-07-26', '07:17:35'),
(1155, NULL, 'INSERT', 'Nuevo estudiante RU=1006107 Plan=8 Ingreso=I/1995', '2026-07-26', '07:17:35'),
(1156, 184, 'INSERT', 'Creación de usuario: elauraq1', '2026-07-26', '07:17:35'),
(1157, NULL, 'INSERT', 'Nueva persona: Magaly Flores Ticona (CI: 2000309LP)', '2026-07-26', '07:17:36'),
(1158, NULL, 'INSERT', 'Nuevo estudiante RU=1006108 Plan=9 Ingreso=I/1995', '2026-07-26', '07:17:36'),
(1159, 185, 'INSERT', 'Creación de usuario: mflorest1', '2026-07-26', '07:17:36'),
(1160, NULL, 'INSERT', 'Nueva persona: César Condori Huanca (CI: 2000310LP)', '2026-07-26', '07:17:36'),
(1161, NULL, 'INSERT', 'Nuevo estudiante RU=1006109 Plan=10 Ingreso=I/1995', '2026-07-26', '07:17:36'),
(1162, 186, 'INSERT', 'Creación de usuario: ccondorih1', '2026-07-26', '07:17:36'),
(1163, NULL, 'INSERT', 'Nueva persona: Delia Quispe Mamani (CI: 2000311LP)', '2026-07-26', '07:17:36'),
(1164, NULL, 'INSERT', 'Nuevo estudiante RU=1006110 Plan=1 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1165, 187, 'INSERT', 'Creación de usuario: dquispem', '2026-07-26', '07:17:36'),
(1166, NULL, 'INSERT', 'Nueva persona: Saúl Ticona Apaza (CI: 2000312LP)', '2026-07-26', '07:17:36'),
(1167, NULL, 'INSERT', 'Nuevo estudiante RU=1006111 Plan=2 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1168, 188, 'INSERT', 'Creación de usuario: sticonaa', '2026-07-26', '07:17:36'),
(1169, NULL, 'INSERT', 'Nueva persona: Vanesa Mamani Flores (CI: 2000313LP)', '2026-07-26', '07:17:36'),
(1170, NULL, 'INSERT', 'Nuevo estudiante RU=1006112 Plan=3 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1171, 189, 'INSERT', 'Creación de usuario: vmamanif', '2026-07-26', '07:17:36'),
(1172, NULL, 'INSERT', 'Nueva persona: Damián Huanca Laura (CI: 2000314LP)', '2026-07-26', '07:17:36'),
(1173, NULL, 'INSERT', 'Nuevo estudiante RU=1006113 Plan=4 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1174, 190, 'INSERT', 'Creación de usuario: dhuancal', '2026-07-26', '07:17:36'),
(1175, NULL, 'INSERT', 'Nueva persona: Flora Apaza Condori (CI: 2000315LP)', '2026-07-26', '07:17:36'),
(1176, NULL, 'INSERT', 'Nuevo estudiante RU=1006114 Plan=5 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1177, 191, 'INSERT', 'Creación de usuario: fapazac', '2026-07-26', '07:17:36'),
(1178, NULL, 'INSERT', 'Nueva persona: Ismael Laura Quispe (CI: 2000316LP)', '2026-07-26', '07:17:36'),
(1179, NULL, 'INSERT', 'Nuevo estudiante RU=1006115 Plan=6 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1180, 192, 'INSERT', 'Creación de usuario: ilauraq', '2026-07-26', '07:17:36'),
(1181, NULL, 'INSERT', 'Nueva persona: Nilda Flores Mamani (CI: 2000317LP)', '2026-07-26', '07:17:36'),
(1182, NULL, 'INSERT', 'Nuevo estudiante RU=1006116 Plan=7 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1183, 193, 'INSERT', 'Creación de usuario: nfloresm', '2026-07-26', '07:17:36'),
(1184, NULL, 'INSERT', 'Nueva persona: Abel Condori Apaza (CI: 2000318LP)', '2026-07-26', '07:17:36'),
(1185, NULL, 'INSERT', 'Nuevo estudiante RU=1006117 Plan=8 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1186, 194, 'INSERT', 'Creación de usuario: acondoria', '2026-07-26', '07:17:36'),
(1187, NULL, 'INSERT', 'Nueva persona: Yanet Quispe Ticona (CI: 2000319LP)', '2026-07-26', '07:17:36'),
(1188, NULL, 'INSERT', 'Nuevo estudiante RU=1006118 Plan=9 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1189, 195, 'INSERT', 'Creación de usuario: yquispet', '2026-07-26', '07:17:36'),
(1190, NULL, 'INSERT', 'Nueva persona: Vladimir Mamani Laura (CI: 2000320LP)', '2026-07-26', '07:17:36'),
(1191, NULL, 'INSERT', 'Nuevo estudiante RU=1006119 Plan=10 Ingreso=II/1995', '2026-07-26', '07:17:36'),
(1192, 196, 'INSERT', 'Creación de usuario: vmamanil', '2026-07-26', '07:17:36'),
(1193, NULL, 'INSERT', 'Nueva persona: Doris Ticona Flores (CI: 2000321LP)', '2026-07-26', '07:17:36'),
(1194, NULL, 'INSERT', 'Nuevo estudiante RU=1006120 Plan=1 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1195, 197, 'INSERT', 'Creación de usuario: dticonaf', '2026-07-26', '07:17:36'),
(1196, NULL, 'INSERT', 'Nueva persona: Elvis Apaza Huanca (CI: 2000322LP)', '2026-07-26', '07:17:36'),
(1197, NULL, 'INSERT', 'Nuevo estudiante RU=1006121 Plan=2 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1198, 198, 'INSERT', 'Creación de usuario: eapazah', '2026-07-26', '07:17:36'),
(1199, NULL, 'INSERT', 'Nueva persona: Mery Laura Condori (CI: 2000323LP)', '2026-07-26', '07:17:36'),
(1200, NULL, 'INSERT', 'Nuevo estudiante RU=1006122 Plan=3 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1201, 199, 'INSERT', 'Creación de usuario: mlaurac1', '2026-07-26', '07:17:36'),
(1202, NULL, 'INSERT', 'Nueva persona: Freddy Flores Quispe (CI: 2000324LP)', '2026-07-26', '07:17:36'),
(1203, NULL, 'INSERT', 'Nuevo estudiante RU=1006123 Plan=4 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1204, 200, 'INSERT', 'Creación de usuario: ffloresq', '2026-07-26', '07:17:36'),
(1205, NULL, 'INSERT', 'Nueva persona: Nelly Condori Mamani (CI: 2000325LP)', '2026-07-26', '07:17:36'),
(1206, NULL, 'INSERT', 'Nuevo estudiante RU=1006124 Plan=5 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1207, 201, 'INSERT', 'Creación de usuario: ncondorim', '2026-07-26', '07:17:36'),
(1208, NULL, 'INSERT', 'Nueva persona: Grover Quispe Apaza (CI: 2000326LP)', '2026-07-26', '07:17:36'),
(1209, NULL, 'INSERT', 'Nuevo estudiante RU=1006125 Plan=6 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1210, 202, 'INSERT', 'Creación de usuario: gquispea', '2026-07-26', '07:17:36'),
(1211, NULL, 'INSERT', 'Nueva persona: Lidia Mamani Ticona (CI: 2000327LP)', '2026-07-26', '07:17:36'),
(1212, NULL, 'INSERT', 'Nuevo estudiante RU=1006126 Plan=7 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1213, 203, 'INSERT', 'Creación de usuario: lmamanit', '2026-07-26', '07:17:36'),
(1214, NULL, 'INSERT', 'Nueva persona: Ronal Huanca Flores (CI: 2000328LP)', '2026-07-26', '07:17:36'),
(1215, NULL, 'INSERT', 'Nuevo estudiante RU=1006127 Plan=8 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1216, 204, 'INSERT', 'Creación de usuario: rhuancaf', '2026-07-26', '07:17:36'),
(1217, NULL, 'INSERT', 'Nueva persona: Betty Ticona Laura (CI: 2000329LP)', '2026-07-26', '07:17:36'),
(1218, NULL, 'INSERT', 'Nuevo estudiante RU=1006128 Plan=9 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1219, 205, 'INSERT', 'Creación de usuario: bticonal', '2026-07-26', '07:17:36'),
(1220, NULL, 'INSERT', 'Nueva persona: Edgar Apaza Mamani (CI: 2000330LP)', '2026-07-26', '07:17:36'),
(1221, NULL, 'INSERT', 'Nuevo estudiante RU=1006129 Plan=10 Ingreso=I/1996', '2026-07-26', '07:17:36'),
(1222, 206, 'INSERT', 'Creación de usuario: eapazam', '2026-07-26', '07:17:36'),
(1223, NULL, 'INSERT', 'Nueva persona: Elsa Laura Condori (CI: 2000331LP)', '2026-07-26', '07:18:06'),
(1224, NULL, 'INSERT', 'Nuevo estudiante RU=1006130 Plan=1 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1225, 207, 'INSERT', 'Creación de usuario: elaurac', '2026-07-26', '07:18:06'),
(1226, NULL, 'INSERT', 'Nueva persona: Wilmer Flores Quispe (CI: 2000332LP)', '2026-07-26', '07:18:06'),
(1227, NULL, 'INSERT', 'Nuevo estudiante RU=1006131 Plan=2 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1228, 208, 'INSERT', 'Creación de usuario: wfloresq', '2026-07-26', '07:18:06'),
(1229, NULL, 'INSERT', 'Nueva persona: Graciela Condori Huanca (CI: 2000333LP)', '2026-07-26', '07:18:06'),
(1230, NULL, 'INSERT', 'Nuevo estudiante RU=1006132 Plan=3 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1231, 209, 'INSERT', 'Creación de usuario: gcondorih', '2026-07-26', '07:18:06'),
(1232, NULL, 'INSERT', 'Nueva persona: Bismarck Quispe Apaza (CI: 2000334LP)', '2026-07-26', '07:18:06'),
(1233, NULL, 'INSERT', 'Nuevo estudiante RU=1006133 Plan=4 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1234, 210, 'INSERT', 'Creación de usuario: bquispea1', '2026-07-26', '07:18:06'),
(1235, NULL, 'INSERT', 'Nueva persona: Filomena Mamani Flores (CI: 2000335LP)', '2026-07-26', '07:18:06'),
(1236, NULL, 'INSERT', 'Nuevo estudiante RU=1006134 Plan=5 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1237, 211, 'INSERT', 'Creación de usuario: fmamanif1', '2026-07-26', '07:18:06'),
(1238, NULL, 'INSERT', 'Nueva persona: Adolfo Ticona Laura (CI: 2000336LP)', '2026-07-26', '07:18:06'),
(1239, NULL, 'INSERT', 'Nuevo estudiante RU=1006135 Plan=6 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1240, 212, 'INSERT', 'Creación de usuario: aticonal1', '2026-07-26', '07:18:06'),
(1241, NULL, 'INSERT', 'Nueva persona: Justina Huanca Mamani (CI: 2000337LP)', '2026-07-26', '07:18:06'),
(1242, NULL, 'INSERT', 'Nuevo estudiante RU=1006136 Plan=7 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1243, 213, 'INSERT', 'Creación de usuario: jhuancam', '2026-07-26', '07:18:06'),
(1244, NULL, 'INSERT', 'Nueva persona: Emilio Apaza Condori (CI: 2000338LP)', '2026-07-26', '07:18:06'),
(1245, NULL, 'INSERT', 'Nuevo estudiante RU=1006137 Plan=8 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1246, 214, 'INSERT', 'Creación de usuario: eapazac', '2026-07-26', '07:18:06'),
(1247, NULL, 'INSERT', 'Nueva persona: Sabina Laura Quispe (CI: 2000339LP)', '2026-07-26', '07:18:06'),
(1248, NULL, 'INSERT', 'Nuevo estudiante RU=1006138 Plan=9 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1249, 215, 'INSERT', 'Creación de usuario: slauraq', '2026-07-26', '07:18:06'),
(1250, NULL, 'INSERT', 'Nueva persona: Teófilo Flores Apaza (CI: 2000340LP)', '2026-07-26', '07:18:06'),
(1251, NULL, 'INSERT', 'Nuevo estudiante RU=1006139 Plan=10 Ingreso=II/1996', '2026-07-26', '07:18:06'),
(1252, 216, 'INSERT', 'Creación de usuario: tfloresa1', '2026-07-26', '07:18:06'),
(1253, NULL, 'INSERT', 'Nueva persona: Cintia Condori Mamani (CI: 2000341LP)', '2026-07-26', '07:18:06'),
(1254, NULL, 'INSERT', 'Nuevo estudiante RU=1006140 Plan=1 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1255, 217, 'INSERT', 'Creación de usuario: ccondorim', '2026-07-26', '07:18:06');
INSERT INTO `auditoria` (`id_auditoria`, `id_usuario`, `tipo`, `accion`, `fecha`, `hora`) VALUES
(1256, NULL, 'INSERT', 'Nueva persona: Limber Quispe Ticona (CI: 2000342LP)', '2026-07-26', '07:18:06'),
(1257, NULL, 'INSERT', 'Nuevo estudiante RU=1006141 Plan=2 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1258, 218, 'INSERT', 'Creación de usuario: lquispet', '2026-07-26', '07:18:06'),
(1259, NULL, 'INSERT', 'Nueva persona: Eloísa Mamani Laura (CI: 2000343LP)', '2026-07-26', '07:18:06'),
(1260, NULL, 'INSERT', 'Nuevo estudiante RU=1006142 Plan=3 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1261, 219, 'INSERT', 'Creación de usuario: emamanil', '2026-07-26', '07:18:06'),
(1262, NULL, 'INSERT', 'Nueva persona: Benigno Ticona Flores (CI: 2000344LP)', '2026-07-26', '07:18:06'),
(1263, NULL, 'INSERT', 'Nuevo estudiante RU=1006143 Plan=4 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1264, 220, 'INSERT', 'Creación de usuario: bticonaf', '2026-07-26', '07:18:06'),
(1265, NULL, 'INSERT', 'Nueva persona: Teodora Huanca Quispe (CI: 2000345LP)', '2026-07-26', '07:18:06'),
(1266, NULL, 'INSERT', 'Nuevo estudiante RU=1006144 Plan=5 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1267, 221, 'INSERT', 'Creación de usuario: thuancaq', '2026-07-26', '07:18:06'),
(1268, NULL, 'INSERT', 'Nueva persona: Germán Apaza Mamani (CI: 2000346LP)', '2026-07-26', '07:18:06'),
(1269, NULL, 'INSERT', 'Nuevo estudiante RU=1006145 Plan=6 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1270, 222, 'INSERT', 'Creación de usuario: gapazam', '2026-07-26', '07:18:06'),
(1271, NULL, 'INSERT', 'Nueva persona: Basilia Laura Flores (CI: 2000347LP)', '2026-07-26', '07:18:06'),
(1272, NULL, 'INSERT', 'Nuevo estudiante RU=1006146 Plan=7 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1273, 223, 'INSERT', 'Creación de usuario: blauraf', '2026-07-26', '07:18:06'),
(1274, NULL, 'INSERT', 'Nueva persona: Silverio Condori Apaza (CI: 2000348LP)', '2026-07-26', '07:18:06'),
(1275, NULL, 'INSERT', 'Nuevo estudiante RU=1006147 Plan=8 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1276, 224, 'INSERT', 'Creación de usuario: scondoria', '2026-07-26', '07:18:06'),
(1277, NULL, 'INSERT', 'Nueva persona: Melania Mamani Huanca (CI: 2000349LP)', '2026-07-26', '07:18:06'),
(1278, NULL, 'INSERT', 'Nuevo estudiante RU=1006148 Plan=9 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1279, 225, 'INSERT', 'Creación de usuario: mmamanih', '2026-07-26', '07:18:06'),
(1280, NULL, 'INSERT', 'Nueva persona: Demetrio Quispe Laura (CI: 2000350LP)', '2026-07-26', '07:18:06'),
(1281, NULL, 'INSERT', 'Nuevo estudiante RU=1006149 Plan=10 Ingreso=I/1997', '2026-07-26', '07:18:06'),
(1282, 226, 'INSERT', 'Creación de usuario: dquispel', '2026-07-26', '07:18:06'),
(1283, NULL, 'INSERT', 'Nueva persona: Eulogia Flores Condori (CI: 2000351LP)', '2026-07-26', '07:18:06'),
(1284, NULL, 'INSERT', 'Nuevo estudiante RU=1006150 Plan=1 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1285, 227, 'INSERT', 'Creación de usuario: efloresc', '2026-07-26', '07:18:06'),
(1286, NULL, 'INSERT', 'Nueva persona: Saturnino Ticona Mamani (CI: 2000352LP)', '2026-07-26', '07:18:06'),
(1287, NULL, 'INSERT', 'Nuevo estudiante RU=1006151 Plan=2 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1288, 228, 'INSERT', 'Creación de usuario: sticonam', '2026-07-26', '07:18:06'),
(1289, NULL, 'INSERT', 'Nueva persona: Gregoria Huanca Apaza (CI: 2000353LP)', '2026-07-26', '07:18:06'),
(1290, NULL, 'INSERT', 'Nuevo estudiante RU=1006152 Plan=3 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1291, 229, 'INSERT', 'Creación de usuario: ghuancaa', '2026-07-26', '07:18:06'),
(1292, NULL, 'INSERT', 'Nueva persona: Celestino Apaza Laura (CI: 2000354LP)', '2026-07-26', '07:18:06'),
(1293, NULL, 'INSERT', 'Nuevo estudiante RU=1006153 Plan=4 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1294, 230, 'INSERT', 'Creación de usuario: capazal', '2026-07-26', '07:18:06'),
(1295, NULL, 'INSERT', 'Nueva persona: Modesta Mamani Quispe (CI: 2000355LP)', '2026-07-26', '07:18:06'),
(1296, NULL, 'INSERT', 'Nuevo estudiante RU=1006154 Plan=5 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1297, 231, 'INSERT', 'Creación de usuario: mmamaniq', '2026-07-26', '07:18:06'),
(1298, NULL, 'INSERT', 'Nueva persona: Valentín Condori Flores (CI: 2000356LP)', '2026-07-26', '07:18:06'),
(1299, NULL, 'INSERT', 'Nuevo estudiante RU=1006155 Plan=6 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1300, 232, 'INSERT', 'Creación de usuario: vcondorif', '2026-07-26', '07:18:06'),
(1301, NULL, 'INSERT', 'Nueva persona: Petrona Laura Ticona (CI: 2000357LP)', '2026-07-26', '07:18:06'),
(1302, NULL, 'INSERT', 'Nuevo estudiante RU=1006156 Plan=7 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1303, 233, 'INSERT', 'Creación de usuario: plaurat', '2026-07-26', '07:18:06'),
(1304, NULL, 'INSERT', 'Nueva persona: Agapito Quispe Mamani (CI: 2000358LP)', '2026-07-26', '07:18:06'),
(1305, NULL, 'INSERT', 'Nuevo estudiante RU=1006157 Plan=8 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1306, 234, 'INSERT', 'Creación de usuario: aquispem', '2026-07-26', '07:18:06'),
(1307, NULL, 'INSERT', 'Nueva persona: Isabel Flores Apaza (CI: 2000359LP)', '2026-07-26', '07:18:06'),
(1308, NULL, 'INSERT', 'Nuevo estudiante RU=1006158 Plan=9 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1309, 235, 'INSERT', 'Creación de usuario: ifloresa', '2026-07-26', '07:18:06'),
(1310, NULL, 'INSERT', 'Nueva persona: Nicanor Ticona Laura (CI: 2000360LP)', '2026-07-26', '07:18:06'),
(1311, NULL, 'INSERT', 'Nuevo estudiante RU=1006159 Plan=10 Ingreso=II/1997', '2026-07-26', '07:18:06'),
(1312, 236, 'INSERT', 'Creación de usuario: nticonal1', '2026-07-26', '07:18:06'),
(1313, NULL, 'INSERT', 'Nueva persona: Lucila Huanca Mamani (CI: 2000361LP)', '2026-07-26', '07:18:23'),
(1314, NULL, 'INSERT', 'Nuevo estudiante RU=1006160 Plan=1 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1315, 237, 'INSERT', 'Creación de usuario: lhuancam', '2026-07-26', '07:18:23'),
(1316, NULL, 'INSERT', 'Nueva persona: Cirilo Apaza Condori (CI: 2000362LP)', '2026-07-26', '07:18:23'),
(1317, NULL, 'INSERT', 'Nuevo estudiante RU=1006161 Plan=2 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1318, 238, 'INSERT', 'Creación de usuario: capazac', '2026-07-26', '07:18:23'),
(1319, NULL, 'INSERT', 'Nueva persona: Eusebia Laura Quispe (CI: 2000363LP)', '2026-07-26', '07:18:23'),
(1320, NULL, 'INSERT', 'Nuevo estudiante RU=1006162 Plan=3 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1321, 239, 'INSERT', 'Creación de usuario: elauraq2', '2026-07-26', '07:18:23'),
(1322, NULL, 'INSERT', 'Nueva persona: Pascual Flores Apaza (CI: 2000364LP)', '2026-07-26', '07:18:23'),
(1323, NULL, 'INSERT', 'Nuevo estudiante RU=1006163 Plan=4 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1324, 240, 'INSERT', 'Creación de usuario: pfloresa', '2026-07-26', '07:18:23'),
(1325, NULL, 'INSERT', 'Nueva persona: Ignacia Condori Mamani (CI: 2000365LP)', '2026-07-26', '07:18:23'),
(1326, NULL, 'INSERT', 'Nuevo estudiante RU=1006164 Plan=5 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1327, 241, 'INSERT', 'Creación de usuario: icondorim1', '2026-07-26', '07:18:23'),
(1328, NULL, 'INSERT', 'Nueva persona: Rufino Quispe Ticona (CI: 2000366LP)', '2026-07-26', '07:18:23'),
(1329, NULL, 'INSERT', 'Nuevo estudiante RU=1006165 Plan=6 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1330, 242, 'INSERT', 'Creación de usuario: rquispet', '2026-07-26', '07:18:23'),
(1331, NULL, 'INSERT', 'Nueva persona: Visitación Mamani Laura (CI: 2000367LP)', '2026-07-26', '07:18:23'),
(1332, NULL, 'INSERT', 'Nuevo estudiante RU=1006166 Plan=7 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1333, 243, 'INSERT', 'Creación de usuario: vmamanil1', '2026-07-26', '07:18:23'),
(1334, NULL, 'INSERT', 'Nueva persona: Cipriano Ticona Flores (CI: 2000368LP)', '2026-07-26', '07:18:23'),
(1335, NULL, 'INSERT', 'Nuevo estudiante RU=1006167 Plan=8 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1336, 244, 'INSERT', 'Creación de usuario: cticonaf', '2026-07-26', '07:18:23'),
(1337, NULL, 'INSERT', 'Nueva persona: Magdalena Huanca Quispe (CI: 2000369LP)', '2026-07-26', '07:18:23'),
(1338, NULL, 'INSERT', 'Nuevo estudiante RU=1006168 Plan=9 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1339, 245, 'INSERT', 'Creación de usuario: mhuancaq', '2026-07-26', '07:18:23'),
(1340, NULL, 'INSERT', 'Nueva persona: Fortunato Apaza Mamani (CI: 2000370LP)', '2026-07-26', '07:18:23'),
(1341, NULL, 'INSERT', 'Nuevo estudiante RU=1006169 Plan=10 Ingreso=II/1997', '2026-07-26', '07:18:23'),
(1342, 246, 'INSERT', 'Creación de usuario: fapazam', '2026-07-26', '07:18:23'),
(1343, NULL, 'INSERT', 'Nueva persona: Amalia Mamani Quispe (CI: 2000371LP)', '2026-07-26', '07:18:23'),
(1344, NULL, 'INSERT', 'Nuevo estudiante RU=1006170 Plan=1 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1345, 247, 'INSERT', 'Creación de usuario: amamaniq2', '2026-07-26', '07:18:23'),
(1346, NULL, 'INSERT', 'Nueva persona: Dionisio Flores Apaza (CI: 2000372LP)', '2026-07-26', '07:18:23'),
(1347, NULL, 'INSERT', 'Nuevo estudiante RU=1006171 Plan=2 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1348, 248, 'INSERT', 'Creación de usuario: dfloresa', '2026-07-26', '07:18:23'),
(1349, NULL, 'INSERT', 'Nueva persona: Rita Condori Mamani (CI: 2000373LP)', '2026-07-26', '07:18:23'),
(1350, NULL, 'INSERT', 'Nuevo estudiante RU=1006172 Plan=3 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1351, 249, 'INSERT', 'Creación de usuario: rcondorim', '2026-07-26', '07:18:23'),
(1352, NULL, 'INSERT', 'Nueva persona: Norberto Ticona Laura (CI: 2000374LP)', '2026-07-26', '07:18:23'),
(1353, NULL, 'INSERT', 'Nuevo estudiante RU=1006173 Plan=4 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1354, 250, 'INSERT', 'Creación de usuario: nticonal2', '2026-07-26', '07:18:23'),
(1355, NULL, 'INSERT', 'Nueva persona: Celestina Huanca Pari (CI: 2000375LP)', '2026-07-26', '07:18:23'),
(1356, NULL, 'INSERT', 'Nuevo estudiante RU=1006174 Plan=5 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1357, 251, 'INSERT', 'Creación de usuario: chuancap', '2026-07-26', '07:18:23'),
(1358, NULL, 'INSERT', 'Nueva persona: Gumersindo Apaza Flores (CI: 2000376LP)', '2026-07-26', '07:18:23'),
(1359, NULL, 'INSERT', 'Nuevo estudiante RU=1006175 Plan=6 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1360, 252, 'INSERT', 'Creación de usuario: gapazaf', '2026-07-26', '07:18:23'),
(1361, NULL, 'INSERT', 'Nueva persona: Herminia Mamani Condori (CI: 2000377LP)', '2026-07-26', '07:18:23'),
(1362, NULL, 'INSERT', 'Nuevo estudiante RU=1006176 Plan=7 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1363, 253, 'INSERT', 'Creación de usuario: hmamanic', '2026-07-26', '07:18:23'),
(1364, NULL, 'INSERT', 'Nueva persona: Zacarías Laura Quispe (CI: 2000378LP)', '2026-07-26', '07:18:23'),
(1365, NULL, 'INSERT', 'Nuevo estudiante RU=1006177 Plan=8 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1366, 254, 'INSERT', 'Creación de usuario: zlauraq', '2026-07-26', '07:18:23'),
(1367, NULL, 'INSERT', 'Nueva persona: Pascuala Flores Ticona (CI: 2000379LP)', '2026-07-26', '07:18:23'),
(1368, NULL, 'INSERT', 'Nuevo estudiante RU=1006178 Plan=9 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1369, 255, 'INSERT', 'Creación de usuario: pflorest', '2026-07-26', '07:18:23'),
(1370, NULL, 'INSERT', 'Nueva persona: Anselmo Condori Huanca (CI: 2000380LP)', '2026-07-26', '07:18:23'),
(1371, NULL, 'INSERT', 'Nuevo estudiante RU=1006179 Plan=10 Ingreso=I/1998', '2026-07-26', '07:18:23'),
(1372, 256, 'INSERT', 'Creación de usuario: acondorih', '2026-07-26', '07:18:23'),
(1373, NULL, 'INSERT', 'Nueva persona: Melchora Quispe Mamani (CI: 2000381LP)', '2026-07-26', '07:18:23'),
(1374, NULL, 'INSERT', 'Nuevo estudiante RU=1006180 Plan=1 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1375, 257, 'INSERT', 'Creación de usuario: mquispem2', '2026-07-26', '07:18:23'),
(1376, NULL, 'INSERT', 'Nueva persona: Casimiro Ticona Apaza (CI: 2000382LP)', '2026-07-26', '07:18:23'),
(1377, NULL, 'INSERT', 'Nuevo estudiante RU=1006181 Plan=2 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1378, 258, 'INSERT', 'Creación de usuario: cticonaa1', '2026-07-26', '07:18:23'),
(1379, NULL, 'INSERT', 'Nueva persona: Nicomedes Mamani Flores (CI: 2000383LP)', '2026-07-26', '07:18:23'),
(1380, NULL, 'INSERT', 'Nuevo estudiante RU=1006182 Plan=3 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1381, 259, 'INSERT', 'Creación de usuario: nmamanif1', '2026-07-26', '07:18:23'),
(1382, NULL, 'INSERT', 'Nueva persona: Dorotea Huanca Laura (CI: 2000384LP)', '2026-07-26', '07:18:23'),
(1383, NULL, 'INSERT', 'Nuevo estudiante RU=1006183 Plan=4 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1384, 260, 'INSERT', 'Creación de usuario: dhuancal1', '2026-07-26', '07:18:23'),
(1385, NULL, 'INSERT', 'Nueva persona: Epifanio Apaza Condori (CI: 2000385LP)', '2026-07-26', '07:18:23'),
(1386, NULL, 'INSERT', 'Nuevo estudiante RU=1006184 Plan=5 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1387, 261, 'INSERT', 'Creación de usuario: eapazac1', '2026-07-26', '07:18:23'),
(1388, NULL, 'INSERT', 'Nueva persona: Maura Laura Quispe (CI: 2000386LP)', '2026-07-26', '07:18:23'),
(1389, NULL, 'INSERT', 'Nuevo estudiante RU=1006185 Plan=6 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1390, 262, 'INSERT', 'Creación de usuario: mlauraq', '2026-07-26', '07:18:23'),
(1391, NULL, 'INSERT', 'Nueva persona: Leoncio Flores Mamani (CI: 2000387LP)', '2026-07-26', '07:18:23'),
(1392, NULL, 'INSERT', 'Nuevo estudiante RU=1006186 Plan=7 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1393, 263, 'INSERT', 'Creación de usuario: lfloresm', '2026-07-26', '07:18:23'),
(1394, NULL, 'INSERT', 'Nueva persona: Segundina Condori Apaza (CI: 2000388LP)', '2026-07-26', '07:18:23'),
(1395, NULL, 'INSERT', 'Nuevo estudiante RU=1006187 Plan=8 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1396, 264, 'INSERT', 'Creación de usuario: scondoria1', '2026-07-26', '07:18:23'),
(1397, NULL, 'INSERT', 'Nueva persona: Eustaquio Quispe Ticona (CI: 2000389LP)', '2026-07-26', '07:18:23'),
(1398, NULL, 'INSERT', 'Nuevo estudiante RU=1006188 Plan=9 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1399, 265, 'INSERT', 'Creación de usuario: equispet', '2026-07-26', '07:18:23'),
(1400, NULL, 'INSERT', 'Nueva persona: Brigida Mamani Laura (CI: 2000390LP)', '2026-07-26', '07:18:23'),
(1401, NULL, 'INSERT', 'Nuevo estudiante RU=1006189 Plan=10 Ingreso=II/1998', '2026-07-26', '07:18:23'),
(1402, 266, 'INSERT', 'Creación de usuario: bmamanil', '2026-07-26', '07:18:23'),
(1403, NULL, 'INSERT', 'Nueva persona: Tiburcio Ticona Flores (CI: 2000391LP)', '2026-07-26', '07:18:39'),
(1404, NULL, 'INSERT', 'Nuevo estudiante RU=1006190 Plan=1 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1405, 267, 'INSERT', 'Creación de usuario: tticonaf', '2026-07-26', '07:18:39'),
(1406, NULL, 'INSERT', 'Nueva persona: Gertrudis Apaza Huanca (CI: 2000392LP)', '2026-07-26', '07:18:39'),
(1407, NULL, 'INSERT', 'Nuevo estudiante RU=1006191 Plan=2 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1408, 268, 'INSERT', 'Creación de usuario: gapazah', '2026-07-26', '07:18:39'),
(1409, NULL, 'INSERT', 'Nueva persona: Toribio Laura Condori (CI: 2000393LP)', '2026-07-26', '07:18:39'),
(1410, NULL, 'INSERT', 'Nuevo estudiante RU=1006192 Plan=3 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1411, 269, 'INSERT', 'Creación de usuario: tlaurac', '2026-07-26', '07:18:39'),
(1412, NULL, 'INSERT', 'Nueva persona: Maximiliana Flores Quispe (CI: 2000394LP)', '2026-07-26', '07:18:39'),
(1413, NULL, 'INSERT', 'Nuevo estudiante RU=1006193 Plan=4 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1414, 270, 'INSERT', 'Creación de usuario: mfloresq2', '2026-07-26', '07:18:39'),
(1415, NULL, 'INSERT', 'Nueva persona: Clemente Condori Mamani (CI: 2000395LP)', '2026-07-26', '07:18:39'),
(1416, NULL, 'INSERT', 'Nuevo estudiante RU=1006194 Plan=5 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1417, 271, 'INSERT', 'Creación de usuario: ccondorim1', '2026-07-26', '07:18:39'),
(1418, NULL, 'INSERT', 'Nueva persona: Raymunda Quispe Apaza (CI: 2000396LP)', '2026-07-26', '07:18:39'),
(1419, NULL, 'INSERT', 'Nuevo estudiante RU=1006195 Plan=6 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1420, 272, 'INSERT', 'Creación de usuario: rquispea2', '2026-07-26', '07:18:39'),
(1421, NULL, 'INSERT', 'Nueva persona: Pantaleón Mamani Ticona (CI: 2000397LP)', '2026-07-26', '07:18:39'),
(1422, NULL, 'INSERT', 'Nuevo estudiante RU=1006196 Plan=7 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1423, 273, 'INSERT', 'Creación de usuario: pmamanit1', '2026-07-26', '07:18:39'),
(1424, NULL, 'INSERT', 'Nueva persona: Dominga Huanca Flores (CI: 2000398LP)', '2026-07-26', '07:18:39'),
(1425, NULL, 'INSERT', 'Nuevo estudiante RU=1006197 Plan=8 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1426, 274, 'INSERT', 'Creación de usuario: dhuancaf', '2026-07-26', '07:18:39'),
(1427, NULL, 'INSERT', 'Nueva persona: Ambrosio Ticona Laura (CI: 2000399LP)', '2026-07-26', '07:18:39'),
(1428, NULL, 'INSERT', 'Nuevo estudiante RU=1006198 Plan=9 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1429, 275, 'INSERT', 'Creación de usuario: aticonal2', '2026-07-26', '07:18:39'),
(1430, NULL, 'INSERT', 'Nueva persona: Felicitas Apaza Mamani (CI: 2000400LP)', '2026-07-26', '07:18:39'),
(1431, NULL, 'INSERT', 'Nuevo estudiante RU=1006199 Plan=10 Ingreso=I/1999', '2026-07-26', '07:18:39'),
(1432, 276, 'INSERT', 'Creación de usuario: fapazam1', '2026-07-26', '07:18:39'),
(1433, NULL, 'INSERT', 'Nueva persona: Inocencio Laura Condori (CI: 2000401LP)', '2026-07-26', '07:18:39'),
(1434, NULL, 'INSERT', 'Nuevo estudiante RU=1006200 Plan=1 Ingreso=II/1999', '2026-07-26', '07:18:39'),
(1435, 277, 'INSERT', 'Creación de usuario: ilaurac', '2026-07-26', '07:18:39'),
(1436, NULL, 'INSERT', 'Nueva persona: Primitiva Flores Quispe (CI: 2000402LP)', '2026-07-26', '07:18:39'),
(1437, NULL, 'INSERT', 'Nuevo estudiante RU=1006201 Plan=2 Ingreso=II/1999', '2026-07-26', '07:18:39'),
(1438, 278, 'INSERT', 'Creación de usuario: pfloresq', '2026-07-26', '07:18:39'),
(1439, NULL, 'INSERT', 'Nueva persona: Dámaso Condori Huanca (CI: 2000403LP)', '2026-07-26', '07:18:39'),
(1440, NULL, 'INSERT', 'Nuevo estudiante RU=1006202 Plan=3 Ingreso=II/1999', '2026-07-26', '07:18:39'),
(1441, 279, 'INSERT', 'Creación de usuario: dcondorih', '2026-07-26', '07:18:39'),
(1442, NULL, 'INSERT', 'Nueva persona: Eulalia Quispe Apaza (CI: 2000404LP)', '2026-07-26', '07:18:39'),
(1443, NULL, 'INSERT', 'Nuevo estudiante RU=1006203 Plan=4 Ingreso=II/1999', '2026-07-26', '07:18:39'),
(1444, 280, 'INSERT', 'Creación de usuario: equispea', '2026-07-26', '07:18:39'),
(1445, NULL, 'INSERT', 'Nueva persona: Alipio Mamani Flores (CI: 2000405LP)', '2026-07-26', '07:18:39'),
(1446, NULL, 'INSERT', 'Nuevo estudiante RU=1006204 Plan=5 Ingreso=II/1999', '2026-07-26', '07:18:39'),
(1447, 281, 'INSERT', 'Creación de usuario: amamanif', '2026-07-26', '07:18:39'),
(1448, NULL, 'INSERT', 'Nueva persona: Bartolina Ticona Laura (CI: 2000406LP)', '2026-07-26', '07:18:39'),
(1449, NULL, 'INSERT', 'Nuevo estudiante RU=1006205 Plan=6 Ingreso=II/1999', '2026-07-26', '07:18:39'),
(1450, 282, 'INSERT', 'Creación de usuario: bticonal1', '2026-07-26', '07:18:39'),
(1451, NULL, 'INSERT', 'Nueva persona: Remigio Huanca Mamani (CI: 2000407LP)', '2026-07-26', '07:18:40'),
(1452, NULL, 'INSERT', 'Nuevo estudiante RU=1006206 Plan=7 Ingreso=II/1999', '2026-07-26', '07:18:40'),
(1453, 283, 'INSERT', 'Creación de usuario: rhuancam', '2026-07-26', '07:18:40'),
(1454, NULL, 'INSERT', 'Nueva persona: Anastasia Apaza Condori (CI: 2000408LP)', '2026-07-26', '07:18:40'),
(1455, NULL, 'INSERT', 'Nuevo estudiante RU=1006207 Plan=8 Ingreso=II/1999', '2026-07-26', '07:18:40'),
(1456, 284, 'INSERT', 'Creación de usuario: aapazac', '2026-07-26', '07:18:40'),
(1457, NULL, 'INSERT', 'Nueva persona: Sinforoso Laura Quispe (CI: 2000409LP)', '2026-07-26', '07:18:40'),
(1458, NULL, 'INSERT', 'Nuevo estudiante RU=1006208 Plan=9 Ingreso=II/1999', '2026-07-26', '07:18:40'),
(1459, 285, 'INSERT', 'Creación de usuario: slauraq1', '2026-07-26', '07:18:40'),
(1460, NULL, 'INSERT', 'Nueva persona: Silveria Flores Apaza (CI: 2000410LP)', '2026-07-26', '07:18:40'),
(1461, NULL, 'INSERT', 'Nuevo estudiante RU=1006209 Plan=10 Ingreso=II/1999', '2026-07-26', '07:18:40'),
(1462, 286, 'INSERT', 'Creación de usuario: sfloresa', '2026-07-26', '07:18:40'),
(1463, NULL, 'INSERT', 'Nueva persona: Zenobio Condori Mamani (CI: 2000411LP)', '2026-07-26', '07:18:40'),
(1464, NULL, 'INSERT', 'Nuevo estudiante RU=1006210 Plan=1 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1465, 287, 'INSERT', 'Creación de usuario: zcondorim', '2026-07-26', '07:18:40'),
(1466, NULL, 'INSERT', 'Nueva persona: Herculana Quispe Ticona (CI: 2000412LP)', '2026-07-26', '07:18:40'),
(1467, NULL, 'INSERT', 'Nuevo estudiante RU=1006211 Plan=2 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1468, 288, 'INSERT', 'Creación de usuario: hquispet', '2026-07-26', '07:18:40'),
(1469, NULL, 'INSERT', 'Nueva persona: Victoriano Mamani Laura (CI: 2000413LP)', '2026-07-26', '07:18:40'),
(1470, NULL, 'INSERT', 'Nuevo estudiante RU=1006212 Plan=3 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1471, 289, 'INSERT', 'Creación de usuario: vmamanil2', '2026-07-26', '07:18:40'),
(1472, NULL, 'INSERT', 'Nueva persona: Facunda Ticona Flores (CI: 2000414LP)', '2026-07-26', '07:18:40'),
(1473, NULL, 'INSERT', 'Nuevo estudiante RU=1006213 Plan=4 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1474, 290, 'INSERT', 'Creación de usuario: fticonaf', '2026-07-26', '07:18:40'),
(1475, NULL, 'INSERT', 'Nueva persona: Leocadio Huanca Quispe (CI: 2000415LP)', '2026-07-26', '07:18:40'),
(1476, NULL, 'INSERT', 'Nuevo estudiante RU=1006214 Plan=5 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1477, 291, 'INSERT', 'Creación de usuario: lhuancaq', '2026-07-26', '07:18:40'),
(1478, NULL, 'INSERT', 'Nueva persona: Perfecta Apaza Mamani (CI: 2000416LP)', '2026-07-26', '07:18:40'),
(1479, NULL, 'INSERT', 'Nuevo estudiante RU=1006215 Plan=6 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1480, 292, 'INSERT', 'Creación de usuario: papazam', '2026-07-26', '07:18:40'),
(1481, NULL, 'INSERT', 'Nueva persona: Aniceto Laura Flores (CI: 2000417LP)', '2026-07-26', '07:18:40'),
(1482, NULL, 'INSERT', 'Nuevo estudiante RU=1006216 Plan=7 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1483, 293, 'INSERT', 'Creación de usuario: alauraf', '2026-07-26', '07:18:40'),
(1484, NULL, 'INSERT', 'Nueva persona: Escolástica Condori Apaza (CI: 2000418LP)', '2026-07-26', '07:18:40'),
(1485, NULL, 'INSERT', 'Nuevo estudiante RU=1006217 Plan=8 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1486, 294, 'INSERT', 'Creación de usuario: econdoria', '2026-07-26', '07:18:40'),
(1487, NULL, 'INSERT', 'Nueva persona: Bonifacio Mamani Huanca (CI: 2000419LP)', '2026-07-26', '07:18:40'),
(1488, NULL, 'INSERT', 'Nuevo estudiante RU=1006218 Plan=9 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1489, 295, 'INSERT', 'Creación de usuario: bmamanih', '2026-07-26', '07:18:40'),
(1490, NULL, 'INSERT', 'Nueva persona: Tiburcia Quispe Laura (CI: 2000420LP)', '2026-07-26', '07:18:40'),
(1491, NULL, 'INSERT', 'Nuevo estudiante RU=1006219 Plan=10 Ingreso=I/2000', '2026-07-26', '07:18:40'),
(1492, 296, 'INSERT', 'Creación de usuario: tquispel', '2026-07-26', '07:18:40'),
(1493, NULL, 'INSERT', 'Nueva persona: Fabiana Flores Condori (CI: 2000421LP)', '2026-07-26', '07:18:58'),
(1494, NULL, 'INSERT', 'Nuevo estudiante RU=1006220 Plan=1 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1495, 297, 'INSERT', 'Creación de usuario: ffloresc', '2026-07-26', '07:18:58'),
(1496, NULL, 'INSERT', 'Nueva persona: Evaristo Ticona Mamani (CI: 2000422LP)', '2026-07-26', '07:18:58'),
(1497, NULL, 'INSERT', 'Nuevo estudiante RU=1006221 Plan=2 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1498, 298, 'INSERT', 'Creación de usuario: eticonam1', '2026-07-26', '07:18:58'),
(1499, NULL, 'INSERT', 'Nueva persona: Sulpicia Huanca Apaza (CI: 2000423LP)', '2026-07-26', '07:18:58'),
(1500, NULL, 'INSERT', 'Nuevo estudiante RU=1006222 Plan=3 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1501, 299, 'INSERT', 'Creación de usuario: shuancaa', '2026-07-26', '07:18:58'),
(1502, NULL, 'INSERT', 'Nueva persona: Gervasio Apaza Laura (CI: 2000424LP)', '2026-07-26', '07:18:58'),
(1503, NULL, 'INSERT', 'Nuevo estudiante RU=1006223 Plan=4 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1504, 300, 'INSERT', 'Creación de usuario: gapazal', '2026-07-26', '07:18:58'),
(1505, NULL, 'INSERT', 'Nueva persona: Demetria Mamani Quispe (CI: 2000425LP)', '2026-07-26', '07:18:58'),
(1506, NULL, 'INSERT', 'Nuevo estudiante RU=1006224 Plan=5 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1507, 301, 'INSERT', 'Creación de usuario: dmamaniq', '2026-07-26', '07:18:58'),
(1508, NULL, 'INSERT', 'Nueva persona: Plácido Condori Flores (CI: 2000426LP)', '2026-07-26', '07:18:58'),
(1509, NULL, 'INSERT', 'Nuevo estudiante RU=1006225 Plan=6 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1510, 302, 'INSERT', 'Creación de usuario: pcondorif', '2026-07-26', '07:18:58'),
(1511, NULL, 'INSERT', 'Nueva persona: Narcisa Laura Ticona (CI: 2000427LP)', '2026-07-26', '07:18:58'),
(1512, NULL, 'INSERT', 'Nuevo estudiante RU=1006226 Plan=7 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1513, 303, 'INSERT', 'Creación de usuario: nlaurat', '2026-07-26', '07:18:58'),
(1514, NULL, 'INSERT', 'Nueva persona: Amancio Quispe Mamani (CI: 2000428LP)', '2026-07-26', '07:18:58'),
(1515, NULL, 'INSERT', 'Nuevo estudiante RU=1006227 Plan=8 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1516, 304, 'INSERT', 'Creación de usuario: aquispem1', '2026-07-26', '07:18:58'),
(1517, NULL, 'INSERT', 'Nueva persona: Clotilde Flores Apaza (CI: 2000429LP)', '2026-07-26', '07:18:58'),
(1518, NULL, 'INSERT', 'Nuevo estudiante RU=1006228 Plan=9 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1519, 305, 'INSERT', 'Creación de usuario: cfloresa1', '2026-07-26', '07:18:58'),
(1520, NULL, 'INSERT', 'Nueva persona: Telesforo Ticona Laura (CI: 2000430LP)', '2026-07-26', '07:18:58'),
(1521, NULL, 'INSERT', 'Nuevo estudiante RU=1006229 Plan=10 Ingreso=II/2000', '2026-07-26', '07:18:58'),
(1522, 306, 'INSERT', 'Creación de usuario: tticonal2', '2026-07-26', '07:18:58'),
(1523, NULL, 'INSERT', 'Nueva persona: Alina Huanca Mamani (CI: 2000431LP)', '2026-07-26', '07:18:58'),
(1524, NULL, 'INSERT', 'Nuevo estudiante RU=1006230 Plan=1 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1525, 307, 'INSERT', 'Creación de usuario: ahuancam1', '2026-07-26', '07:18:58'),
(1526, NULL, 'INSERT', 'Nueva persona: Gaspar Apaza Condori (CI: 2000432LP)', '2026-07-26', '07:18:58'),
(1527, NULL, 'INSERT', 'Nuevo estudiante RU=1006231 Plan=2 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1528, 308, 'INSERT', 'Creación de usuario: gapazac', '2026-07-26', '07:18:58'),
(1529, NULL, 'INSERT', 'Nueva persona: Blandina Laura Quispe (CI: 2000433LP)', '2026-07-26', '07:18:58'),
(1530, NULL, 'INSERT', 'Nuevo estudiante RU=1006232 Plan=3 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1531, 309, 'INSERT', 'Creación de usuario: blauraq', '2026-07-26', '07:18:58'),
(1532, NULL, 'INSERT', 'Nueva persona: Melchor Flores Apaza (CI: 2000434LP)', '2026-07-26', '07:18:58'),
(1533, NULL, 'INSERT', 'Nuevo estudiante RU=1006233 Plan=4 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1534, 310, 'INSERT', 'Creación de usuario: mfloresa1', '2026-07-26', '07:18:58'),
(1535, NULL, 'INSERT', 'Nueva persona: Hermelinda Condori Mamani (CI: 2000435LP)', '2026-07-26', '07:18:58'),
(1536, NULL, 'INSERT', 'Nuevo estudiante RU=1006234 Plan=5 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1537, 311, 'INSERT', 'Creación de usuario: hcondorim', '2026-07-26', '07:18:58'),
(1538, NULL, 'INSERT', 'Nueva persona: Baltazar Quispe Ticona (CI: 2000436LP)', '2026-07-26', '07:18:58'),
(1539, NULL, 'INSERT', 'Nuevo estudiante RU=1006235 Plan=6 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1540, 312, 'INSERT', 'Creación de usuario: bquispet', '2026-07-26', '07:18:58'),
(1541, NULL, 'INSERT', 'Nueva persona: Aurelia Mamani Laura (CI: 2000437LP)', '2026-07-26', '07:18:58'),
(1542, NULL, 'INSERT', 'Nuevo estudiante RU=1006236 Plan=7 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1543, 313, 'INSERT', 'Creación de usuario: amamanil1', '2026-07-26', '07:18:58'),
(1544, NULL, 'INSERT', 'Nueva persona: Calixto Ticona Flores (CI: 2000438LP)', '2026-07-26', '07:18:58'),
(1545, NULL, 'INSERT', 'Nuevo estudiante RU=1006237 Plan=8 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1546, 314, 'INSERT', 'Creación de usuario: cticonaf1', '2026-07-26', '07:18:58'),
(1547, NULL, 'INSERT', 'Nueva persona: Florencia Huanca Quispe (CI: 2000439LP)', '2026-07-26', '07:18:58'),
(1548, NULL, 'INSERT', 'Nuevo estudiante RU=1006238 Plan=9 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1549, 315, 'INSERT', 'Creación de usuario: fhuancaq', '2026-07-26', '07:18:58'),
(1550, NULL, 'INSERT', 'Nueva persona: Eugenio Apaza Mamani (CI: 2000440LP)', '2026-07-26', '07:18:58'),
(1551, NULL, 'INSERT', 'Nuevo estudiante RU=1006239 Plan=10 Ingreso=I/2001', '2026-07-26', '07:18:58'),
(1552, 316, 'INSERT', 'Creación de usuario: eapazam1', '2026-07-26', '07:18:58'),
(1553, NULL, 'INSERT', 'Nueva persona: Ricarda Laura Flores (CI: 2000441LP)', '2026-07-26', '07:18:58'),
(1554, NULL, 'INSERT', 'Nuevo estudiante RU=1006240 Plan=1 Ingreso=II/2001', '2026-07-26', '07:18:58'),
(1555, 317, 'INSERT', 'Creación de usuario: rlauraf', '2026-07-26', '07:18:58'),
(1556, NULL, 'INSERT', 'Nueva persona: Cesáreo Condori Apaza (CI: 2000442LP)', '2026-07-26', '07:18:58'),
(1557, NULL, 'INSERT', 'Nuevo estudiante RU=1006241 Plan=2 Ingreso=II/2001', '2026-07-26', '07:18:58'),
(1558, 318, 'INSERT', 'Creación de usuario: ccondoria', '2026-07-26', '07:18:59'),
(1559, NULL, 'INSERT', 'Nueva persona: Odilia Mamani Huanca (CI: 2000443LP)', '2026-07-26', '07:18:59'),
(1560, NULL, 'INSERT', 'Nuevo estudiante RU=1006242 Plan=3 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1561, 319, 'INSERT', 'Creación de usuario: omamanih', '2026-07-26', '07:18:59'),
(1562, NULL, 'INSERT', 'Nueva persona: Candelario Quispe Laura (CI: 2000444LP)', '2026-07-26', '07:18:59'),
(1563, NULL, 'INSERT', 'Nuevo estudiante RU=1006243 Plan=4 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1564, 320, 'INSERT', 'Creación de usuario: cquispel', '2026-07-26', '07:18:59'),
(1565, NULL, 'INSERT', 'Nueva persona: Marcelina Flores Condori (CI: 2000445LP)', '2026-07-26', '07:18:59'),
(1566, NULL, 'INSERT', 'Nuevo estudiante RU=1006244 Plan=5 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1567, 321, 'INSERT', 'Creación de usuario: mfloresc', '2026-07-26', '07:18:59'),
(1568, NULL, 'INSERT', 'Nueva persona: Ruperto Ticona Mamani (CI: 2000446LP)', '2026-07-26', '07:18:59'),
(1569, NULL, 'INSERT', 'Nuevo estudiante RU=1006245 Plan=6 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1570, 322, 'INSERT', 'Creación de usuario: rticonam', '2026-07-26', '07:18:59'),
(1571, NULL, 'INSERT', 'Nueva persona: Luciana Huanca Apaza (CI: 2000447LP)', '2026-07-26', '07:18:59'),
(1572, NULL, 'INSERT', 'Nuevo estudiante RU=1006246 Plan=7 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1573, 323, 'INSERT', 'Creación de usuario: lhuancaa', '2026-07-26', '07:18:59'),
(1574, NULL, 'INSERT', 'Nueva persona: Atanasio Apaza Laura (CI: 2000448LP)', '2026-07-26', '07:18:59'),
(1575, NULL, 'INSERT', 'Nuevo estudiante RU=1006247 Plan=8 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1576, 324, 'INSERT', 'Creación de usuario: aapazal1', '2026-07-26', '07:18:59'),
(1577, NULL, 'INSERT', 'Nueva persona: Eusebio Mamani Quispe (CI: 2000449LP)', '2026-07-26', '07:18:59'),
(1578, NULL, 'INSERT', 'Nuevo estudiante RU=1006248 Plan=9 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1579, 325, 'INSERT', 'Creación de usuario: emamaniq', '2026-07-26', '07:18:59'),
(1580, NULL, 'INSERT', 'Nueva persona: Damiana Condori Flores (CI: 2000450LP)', '2026-07-26', '07:18:59'),
(1581, NULL, 'INSERT', 'Nuevo estudiante RU=1006249 Plan=10 Ingreso=II/2001', '2026-07-26', '07:18:59'),
(1582, 326, 'INSERT', 'Creación de usuario: dcondorif', '2026-07-26', '07:18:59'),
(1583, NULL, 'INSERT', 'Nueva persona: Kevin Mamani Quispe (CI: 2000451LP)', '2026-07-26', '07:19:51'),
(1584, NULL, 'INSERT', 'Nuevo estudiante RU=1006250 Plan=1 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1585, 327, 'INSERT', 'Creación de usuario: kmamaniq', '2026-07-26', '07:19:51'),
(1586, NULL, 'INSERT', 'Nueva persona: Brenda Flores Apaza (CI: 2000452LP)', '2026-07-26', '07:19:51'),
(1587, NULL, 'INSERT', 'Nuevo estudiante RU=1006251 Plan=2 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1588, 328, 'INSERT', 'Creación de usuario: bfloresa', '2026-07-26', '07:19:51'),
(1589, NULL, 'INSERT', 'Nueva persona: Jhonny Condori Mamani (CI: 2000453LP)', '2026-07-26', '07:19:51'),
(1590, NULL, 'INSERT', 'Nuevo estudiante RU=1006252 Plan=3 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1591, 329, 'INSERT', 'Creación de usuario: jcondorim', '2026-07-26', '07:19:51'),
(1592, NULL, 'INSERT', 'Nueva persona: Dayana Ticona Laura (CI: 2000454LP)', '2026-07-26', '07:19:51'),
(1593, NULL, 'INSERT', 'Nuevo estudiante RU=1006253 Plan=4 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1594, 330, 'INSERT', 'Creación de usuario: dticonal', '2026-07-26', '07:19:51'),
(1595, NULL, 'INSERT', 'Nueva persona: Brayan Huanca Pari (CI: 2000455LP)', '2026-07-26', '07:19:51'),
(1596, NULL, 'INSERT', 'Nuevo estudiante RU=1006254 Plan=5 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1597, 331, 'INSERT', 'Creación de usuario: bhuancap', '2026-07-26', '07:19:51'),
(1598, NULL, 'INSERT', 'Nueva persona: Yenifer Apaza Flores (CI: 2000456LP)', '2026-07-26', '07:19:51'),
(1599, NULL, 'INSERT', 'Nuevo estudiante RU=1006255 Plan=6 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1600, 332, 'INSERT', 'Creación de usuario: yapazaf', '2026-07-26', '07:19:51'),
(1601, NULL, 'INSERT', 'Nueva persona: Cristofer Mamani Condori (CI: 2000457LP)', '2026-07-26', '07:19:51'),
(1602, NULL, 'INSERT', 'Nuevo estudiante RU=1006256 Plan=7 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1603, 333, 'INSERT', 'Creación de usuario: cmamanic1', '2026-07-26', '07:19:51'),
(1604, NULL, 'INSERT', 'Nueva persona: Kimberly Laura Quispe (CI: 2000458LP)', '2026-07-26', '07:19:51'),
(1605, NULL, 'INSERT', 'Nuevo estudiante RU=1006257 Plan=8 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1606, 334, 'INSERT', 'Creación de usuario: klauraq', '2026-07-26', '07:19:51'),
(1607, NULL, 'INSERT', 'Nueva persona: Maicol Flores Ticona (CI: 2000459LP)', '2026-07-26', '07:19:51'),
(1608, NULL, 'INSERT', 'Nuevo estudiante RU=1006258 Plan=9 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1609, 335, 'INSERT', 'Creación de usuario: mflorest2', '2026-07-26', '07:19:51'),
(1610, NULL, 'INSERT', 'Nueva persona: Yessica Condori Huanca (CI: 2000460LP)', '2026-07-26', '07:19:51'),
(1611, NULL, 'INSERT', 'Nuevo estudiante RU=1006259 Plan=10 Ingreso=I/2024', '2026-07-26', '07:19:51'),
(1612, 336, 'INSERT', 'Creación de usuario: ycondorih', '2026-07-26', '07:19:51'),
(1613, NULL, 'INSERT', 'Nueva persona: Alex Quispe Mamani (CI: 2000461LP)', '2026-07-26', '07:19:51'),
(1614, NULL, 'INSERT', 'Nuevo estudiante RU=1006260 Plan=1 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1615, 337, 'INSERT', 'Creación de usuario: aquispem2', '2026-07-26', '07:19:51'),
(1616, NULL, 'INSERT', 'Nueva persona: Shirley Ticona Apaza (CI: 2000462LP)', '2026-07-26', '07:19:51'),
(1617, NULL, 'INSERT', 'Nuevo estudiante RU=1006261 Plan=2 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1618, 338, 'INSERT', 'Creación de usuario: sticonaa1', '2026-07-26', '07:19:51'),
(1619, NULL, 'INSERT', 'Nueva persona: Joel Mamani Flores (CI: 2000463LP)', '2026-07-26', '07:19:51'),
(1620, NULL, 'INSERT', 'Nuevo estudiante RU=1006262 Plan=3 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1621, 339, 'INSERT', 'Creación de usuario: jmamanif', '2026-07-26', '07:19:51'),
(1622, NULL, 'INSERT', 'Nueva persona: Abigail Huanca Laura (CI: 2000464LP)', '2026-07-26', '07:19:51'),
(1623, NULL, 'INSERT', 'Nuevo estudiante RU=1006263 Plan=4 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1624, 340, 'INSERT', 'Creación de usuario: ahuancal', '2026-07-26', '07:19:51'),
(1625, NULL, 'INSERT', 'Nueva persona: Erick Apaza Condori (CI: 2000465LP)', '2026-07-26', '07:19:51'),
(1626, NULL, 'INSERT', 'Nuevo estudiante RU=1006264 Plan=5 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1627, 341, 'INSERT', 'Creación de usuario: eapazac2', '2026-07-26', '07:19:51'),
(1628, NULL, 'INSERT', 'Nueva persona: Estefany Laura Quispe (CI: 2000466LP)', '2026-07-26', '07:19:51'),
(1629, NULL, 'INSERT', 'Nuevo estudiante RU=1006265 Plan=6 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1630, 342, 'INSERT', 'Creación de usuario: elauraq3', '2026-07-26', '07:19:51'),
(1631, NULL, 'INSERT', 'Nueva persona: Jhamil Flores Mamani (CI: 2000467LP)', '2026-07-26', '07:19:51'),
(1632, NULL, 'INSERT', 'Nuevo estudiante RU=1006266 Plan=7 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1633, 343, 'INSERT', 'Creación de usuario: jfloresm1', '2026-07-26', '07:19:51'),
(1634, NULL, 'INSERT', 'Nueva persona: Nayeli Condori Apaza (CI: 2000468LP)', '2026-07-26', '07:19:51'),
(1635, NULL, 'INSERT', 'Nuevo estudiante RU=1006267 Plan=8 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1636, 344, 'INSERT', 'Creación de usuario: ncondoria', '2026-07-26', '07:19:51'),
(1637, NULL, 'INSERT', 'Nueva persona: Yerko Quispe Ticona (CI: 2000469LP)', '2026-07-26', '07:19:51'),
(1638, NULL, 'INSERT', 'Nuevo estudiante RU=1006268 Plan=9 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1639, 345, 'INSERT', 'Creación de usuario: yquispet1', '2026-07-26', '07:19:51'),
(1640, NULL, 'INSERT', 'Nueva persona: Mia Mamani Laura (CI: 2000470LP)', '2026-07-26', '07:19:51'),
(1641, NULL, 'INSERT', 'Nuevo estudiante RU=1006269 Plan=10 Ingreso=II/2024', '2026-07-26', '07:19:51'),
(1642, 346, 'INSERT', 'Creación de usuario: mmamanil1', '2026-07-26', '07:19:51'),
(1643, NULL, 'INSERT', 'Nueva persona: Jhael Ticona Flores (CI: 2000471LP)', '2026-07-26', '07:19:51'),
(1644, NULL, 'INSERT', 'Nuevo estudiante RU=1006270 Plan=1 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1645, 347, 'INSERT', 'Creación de usuario: jticonaf1', '2026-07-26', '07:19:51'),
(1646, NULL, 'INSERT', 'Nueva persona: Ashley Apaza Huanca (CI: 2000472LP)', '2026-07-26', '07:19:51'),
(1647, NULL, 'INSERT', 'Nuevo estudiante RU=1006271 Plan=2 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1648, 348, 'INSERT', 'Creación de usuario: aapazah', '2026-07-26', '07:19:51'),
(1649, NULL, 'INSERT', 'Nueva persona: Dilan Laura Condori (CI: 2000473LP)', '2026-07-26', '07:19:51'),
(1650, NULL, 'INSERT', 'Nuevo estudiante RU=1006272 Plan=3 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1651, 349, 'INSERT', 'Creación de usuario: dlaurac1', '2026-07-26', '07:19:51'),
(1652, NULL, 'INSERT', 'Nueva persona: Zoe Flores Quispe (CI: 2000474LP)', '2026-07-26', '07:19:51'),
(1653, NULL, 'INSERT', 'Nuevo estudiante RU=1006273 Plan=4 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1654, 350, 'INSERT', 'Creación de usuario: zfloresq', '2026-07-26', '07:19:51'),
(1655, NULL, 'INSERT', 'Nueva persona: Andy Condori Mamani (CI: 2000475LP)', '2026-07-26', '07:19:51'),
(1656, NULL, 'INSERT', 'Nuevo estudiante RU=1006274 Plan=5 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1657, 351, 'INSERT', 'Creación de usuario: acondorim2', '2026-07-26', '07:19:51'),
(1658, NULL, 'INSERT', 'Nueva persona: Briana Quispe Apaza (CI: 2000476LP)', '2026-07-26', '07:19:51'),
(1659, NULL, 'INSERT', 'Nuevo estudiante RU=1006275 Plan=6 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1660, 352, 'INSERT', 'Creación de usuario: bquispea2', '2026-07-26', '07:19:51'),
(1661, NULL, 'INSERT', 'Nueva persona: Liam Mamani Ticona (CI: 2000477LP)', '2026-07-26', '07:19:51'),
(1662, NULL, 'INSERT', 'Nuevo estudiante RU=1006276 Plan=7 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1663, 353, 'INSERT', 'Creación de usuario: lmamanit1', '2026-07-26', '07:19:51'),
(1664, NULL, 'INSERT', 'Nueva persona: Ariana Huanca Flores (CI: 2000478LP)', '2026-07-26', '07:19:51'),
(1665, NULL, 'INSERT', 'Nuevo estudiante RU=1006277 Plan=8 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1666, 354, 'INSERT', 'Creación de usuario: ahuancaf', '2026-07-26', '07:19:51'),
(1667, NULL, 'INSERT', 'Nueva persona: Thiago Ticona Laura (CI: 2000479LP)', '2026-07-26', '07:19:51'),
(1668, NULL, 'INSERT', 'Nuevo estudiante RU=1006278 Plan=9 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1669, 355, 'INSERT', 'Creación de usuario: tticonal3', '2026-07-26', '07:19:51'),
(1670, NULL, 'INSERT', 'Nueva persona: Sophia Apaza Mamani (CI: 2000480LP)', '2026-07-26', '07:19:51'),
(1671, NULL, 'INSERT', 'Nuevo estudiante RU=1006279 Plan=10 Ingreso=I/2025', '2026-07-26', '07:19:51'),
(1672, 356, 'INSERT', 'Creación de usuario: sapazam2', '2026-07-26', '07:19:51'),
(1673, NULL, 'INSERT', 'Nueva persona: Matías Laura Condori (CI: 2000481LP)', '2026-07-26', '07:20:21'),
(1674, NULL, 'INSERT', 'Nuevo estudiante RU=1006280 Plan=1 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1675, 357, 'INSERT', 'Creación de usuario: mlaurac2', '2026-07-26', '07:20:21'),
(1676, NULL, 'INSERT', 'Nueva persona: Camila Flores Quispe (CI: 2000482LP)', '2026-07-26', '07:20:21'),
(1677, NULL, 'INSERT', 'Nuevo estudiante RU=1006281 Plan=2 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1678, 358, 'INSERT', 'Creación de usuario: cfloresq', '2026-07-26', '07:20:21'),
(1679, NULL, 'INSERT', 'Nueva persona: Santiago Condori Huanca (CI: 2000483LP)', '2026-07-26', '07:20:21'),
(1680, NULL, 'INSERT', 'Nuevo estudiante RU=1006282 Plan=3 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1681, 359, 'INSERT', 'Creación de usuario: scondorih1', '2026-07-26', '07:20:21'),
(1682, NULL, 'INSERT', 'Nueva persona: Valentina Quispe Apaza (CI: 2000484LP)', '2026-07-26', '07:20:21'),
(1683, NULL, 'INSERT', 'Nuevo estudiante RU=1006283 Plan=4 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1684, 360, 'INSERT', 'Creación de usuario: vquispea', '2026-07-26', '07:20:21'),
(1685, NULL, 'INSERT', 'Nueva persona: Sebastián Mamani Flores (CI: 2000485LP)', '2026-07-26', '07:20:21'),
(1686, NULL, 'INSERT', 'Nuevo estudiante RU=1006284 Plan=5 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1687, 361, 'INSERT', 'Creación de usuario: smamanif', '2026-07-26', '07:20:21'),
(1688, NULL, 'INSERT', 'Nueva persona: Isabella Ticona Laura (CI: 2000486LP)', '2026-07-26', '07:20:21'),
(1689, NULL, 'INSERT', 'Nuevo estudiante RU=1006285 Plan=6 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1690, 362, 'INSERT', 'Creación de usuario: iticonal', '2026-07-26', '07:20:21'),
(1691, NULL, 'INSERT', 'Nueva persona: Nicolás Huanca Mamani (CI: 2000487LP)', '2026-07-26', '07:20:21'),
(1692, NULL, 'INSERT', 'Nuevo estudiante RU=1006286 Plan=7 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1693, 363, 'INSERT', 'Creación de usuario: nhuancam', '2026-07-26', '07:20:21'),
(1694, NULL, 'INSERT', 'Nueva persona: Mariana Apaza Condori (CI: 2000488LP)', '2026-07-26', '07:20:21'),
(1695, NULL, 'INSERT', 'Nuevo estudiante RU=1006287 Plan=8 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1696, 364, 'INSERT', 'Creación de usuario: mapazac', '2026-07-26', '07:20:21'),
(1697, NULL, 'INSERT', 'Nueva persona: Emmanuel Laura Quispe (CI: 2000489LP)', '2026-07-26', '07:20:21'),
(1698, NULL, 'INSERT', 'Nuevo estudiante RU=1006288 Plan=9 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1699, 365, 'INSERT', 'Creación de usuario: elauraq4', '2026-07-26', '07:20:21'),
(1700, NULL, 'INSERT', 'Nueva persona: Regina Flores Apaza (CI: 2000490LP)', '2026-07-26', '07:20:21'),
(1701, NULL, 'INSERT', 'Nuevo estudiante RU=1006289 Plan=10 Ingreso=II/2025', '2026-07-26', '07:20:21'),
(1702, 366, 'INSERT', 'Creación de usuario: rfloresa1', '2026-07-26', '07:20:21'),
(1703, NULL, 'INSERT', 'Nueva persona: Gabriel Condori Mamani (CI: 2000491LP)', '2026-07-26', '07:20:21'),
(1704, NULL, 'INSERT', 'Nuevo estudiante RU=1006290 Plan=1 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1705, 367, 'INSERT', 'Creación de usuario: gcondorim', '2026-07-26', '07:20:21'),
(1706, NULL, 'INSERT', 'Nueva persona: Renata Quispe Ticona (CI: 2000492LP)', '2026-07-26', '07:20:21'),
(1707, NULL, 'INSERT', 'Nuevo estudiante RU=1006291 Plan=2 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1708, 368, 'INSERT', 'Creación de usuario: rquispet1', '2026-07-26', '07:20:21'),
(1709, NULL, 'INSERT', 'Nueva persona: Adrián Mamani Laura (CI: 2000493LP)', '2026-07-26', '07:20:21'),
(1710, NULL, 'INSERT', 'Nuevo estudiante RU=1006292 Plan=3 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1711, 369, 'INSERT', 'Creación de usuario: amamanil2', '2026-07-26', '07:20:21'),
(1712, NULL, 'INSERT', 'Nueva persona: Lucía Ticona Flores (CI: 2000494LP)', '2026-07-26', '07:20:21'),
(1713, NULL, 'INSERT', 'Nuevo estudiante RU=1006293 Plan=4 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1714, 370, 'INSERT', 'Creación de usuario: lticonaf1', '2026-07-26', '07:20:21'),
(1715, NULL, 'INSERT', 'Nueva persona: Mateo Huanca Quispe (CI: 2000495LP)', '2026-07-26', '07:20:21'),
(1716, NULL, 'INSERT', 'Nuevo estudiante RU=1006294 Plan=5 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1717, 371, 'INSERT', 'Creación de usuario: mhuancaq1', '2026-07-26', '07:20:21'),
(1718, NULL, 'INSERT', 'Nueva persona: Ximena Apaza Mamani (CI: 2000496LP)', '2026-07-26', '07:20:21'),
(1719, NULL, 'INSERT', 'Nuevo estudiante RU=1006295 Plan=6 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1720, 372, 'INSERT', 'Creación de usuario: xapazam', '2026-07-26', '07:20:21'),
(1721, NULL, 'INSERT', 'Nueva persona: Diego Laura Flores (CI: 2000497LP)', '2026-07-26', '07:20:21'),
(1722, NULL, 'INSERT', 'Nuevo estudiante RU=1006296 Plan=7 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1723, 373, 'INSERT', 'Creación de usuario: dlauraf', '2026-07-26', '07:20:21'),
(1724, NULL, 'INSERT', 'Nueva persona: Sofía Condori Apaza (CI: 2000498LP)', '2026-07-26', '07:20:21'),
(1725, NULL, 'INSERT', 'Nuevo estudiante RU=1006297 Plan=8 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1726, 374, 'INSERT', 'Creación de usuario: scondoria2', '2026-07-26', '07:20:21'),
(1727, NULL, 'INSERT', 'Nueva persona: Joaquín Mamani Huanca (CI: 2000499LP)', '2026-07-26', '07:20:21'),
(1728, NULL, 'INSERT', 'Nuevo estudiante RU=1006298 Plan=9 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1729, 375, 'INSERT', 'Creación de usuario: jmamanih', '2026-07-26', '07:20:21'),
(1730, NULL, 'INSERT', 'Nueva persona: Fernanda Quispe Laura (CI: 2000500LP)', '2026-07-26', '07:20:21'),
(1731, NULL, 'INSERT', 'Nuevo estudiante RU=1006299 Plan=10 Ingreso=I/2026', '2026-07-26', '07:20:21'),
(1732, 376, 'INSERT', 'Creación de usuario: fquispel', '2026-07-26', '07:20:21'),
(1733, NULL, 'INSERT', 'Nueva persona: Alejandro Flores Condori (CI: 2000501LP)', '2026-07-26', '07:20:21'),
(1734, NULL, 'INSERT', 'Nuevo estudiante RU=1006300 Plan=1 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1735, 377, 'INSERT', 'Creación de usuario: afloresc', '2026-07-26', '07:20:21'),
(1736, NULL, 'INSERT', 'Nueva persona: Victoria Ticona Mamani (CI: 2000502LP)', '2026-07-26', '07:20:21'),
(1737, NULL, 'INSERT', 'Nuevo estudiante RU=1006301 Plan=2 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1738, 378, 'INSERT', 'Creación de usuario: vticonam', '2026-07-26', '07:20:21'),
(1739, NULL, 'INSERT', 'Nueva persona: Leonardo Huanca Apaza (CI: 2000503LP)', '2026-07-26', '07:20:21'),
(1740, NULL, 'INSERT', 'Nuevo estudiante RU=1006302 Plan=3 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1741, 379, 'INSERT', 'Creación de usuario: lhuancaa1', '2026-07-26', '07:20:21'),
(1742, NULL, 'INSERT', 'Nueva persona: Julieta Apaza Laura (CI: 2000504LP)', '2026-07-26', '07:20:21'),
(1743, NULL, 'INSERT', 'Nuevo estudiante RU=1006303 Plan=4 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1744, 380, 'INSERT', 'Creación de usuario: japazal', '2026-07-26', '07:20:21'),
(1745, NULL, 'INSERT', 'Nueva persona: Daniel Mamani Quispe (CI: 2000505LP)', '2026-07-26', '07:20:21'),
(1746, NULL, 'INSERT', 'Nuevo estudiante RU=1006304 Plan=5 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1747, 381, 'INSERT', 'Creación de usuario: dmamaniq1', '2026-07-26', '07:20:21'),
(1748, NULL, 'INSERT', 'Nueva persona: Emma Condori Flores (CI: 2000506LP)', '2026-07-26', '07:20:21'),
(1749, NULL, 'INSERT', 'Nuevo estudiante RU=1006305 Plan=6 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1750, 382, 'INSERT', 'Creación de usuario: econdorif', '2026-07-26', '07:20:21'),
(1751, NULL, 'INSERT', 'Nueva persona: Jesús Laura Ticona (CI: 2000507LP)', '2026-07-26', '07:20:21'),
(1752, NULL, 'INSERT', 'Nuevo estudiante RU=1006306 Plan=7 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1753, 383, 'INSERT', 'Creación de usuario: jlaurat', '2026-07-26', '07:20:21'),
(1754, NULL, 'INSERT', 'Nueva persona: Emily Quispe Mamani (CI: 2000508LP)', '2026-07-26', '07:20:21'),
(1755, NULL, 'INSERT', 'Nuevo estudiante RU=1006307 Plan=8 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1756, 384, 'INSERT', 'Creación de usuario: equispem', '2026-07-26', '07:20:21'),
(1757, NULL, 'INSERT', 'Nueva persona: David Flores Apaza (CI: 2000509LP)', '2026-07-26', '07:20:21'),
(1758, NULL, 'INSERT', 'Nuevo estudiante RU=1006308 Plan=9 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1759, 385, 'INSERT', 'Creación de usuario: dfloresa1', '2026-07-26', '07:20:21'),
(1760, NULL, 'INSERT', 'Nueva persona: María José Ticona Laura (CI: 2000510LP)', '2026-07-26', '07:20:21'),
(1761, NULL, 'INSERT', 'Nuevo estudiante RU=1006309 Plan=10 Ingreso=II/2026', '2026-07-26', '07:20:21'),
(1762, 386, 'INSERT', 'Creación de usuario: mticonal1', '2026-07-26', '07:20:21'),
(1763, NULL, 'INSERT', 'Nueva persona: Ethan Huanca Mamani (CI: 2000511LP)', '2026-07-26', '07:21:43'),
(1764, NULL, 'INSERT', 'Nuevo estudiante RU=1006310 Plan=1 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1765, 387, 'INSERT', 'Creación de usuario: ehuancam', '2026-07-26', '07:21:43'),
(1766, NULL, 'INSERT', 'Nueva persona: Aitana Apaza Condori (CI: 2000512LP)', '2026-07-26', '07:21:43'),
(1767, NULL, 'INSERT', 'Nuevo estudiante RU=1006311 Plan=2 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1768, 388, 'INSERT', 'Creación de usuario: aapazac1', '2026-07-26', '07:21:43'),
(1769, NULL, 'INSERT', 'Nueva persona: Ian Laura Quispe (CI: 2000513LP)', '2026-07-26', '07:21:43'),
(1770, NULL, 'INSERT', 'Nuevo estudiante RU=1006312 Plan=3 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1771, 389, 'INSERT', 'Creación de usuario: ilauraq1', '2026-07-26', '07:21:43'),
(1772, NULL, 'INSERT', 'Nueva persona: Alma Flores Apaza (CI: 2000514LP)', '2026-07-26', '07:21:43'),
(1773, NULL, 'INSERT', 'Nuevo estudiante RU=1006313 Plan=4 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1774, 390, 'INSERT', 'Creación de usuario: afloresa', '2026-07-26', '07:21:43'),
(1775, NULL, 'INSERT', 'Nueva persona: Bruno Condori Mamani (CI: 2000515LP)', '2026-07-26', '07:21:43'),
(1776, NULL, 'INSERT', 'Nuevo estudiante RU=1006314 Plan=5 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1777, 391, 'INSERT', 'Creación de usuario: bcondorim1', '2026-07-26', '07:21:43'),
(1778, NULL, 'INSERT', 'Nueva persona: Lía Quispe Ticona (CI: 2000516LP)', '2026-07-26', '07:21:43'),
(1779, NULL, 'INSERT', 'Nuevo estudiante RU=1006315 Plan=6 Ingreso=I/2026', '2026-07-26', '07:21:43');
INSERT INTO `auditoria` (`id_auditoria`, `id_usuario`, `tipo`, `accion`, `fecha`, `hora`) VALUES
(1780, 392, 'INSERT', 'Creación de usuario: lquispet1', '2026-07-26', '07:21:43'),
(1781, NULL, 'INSERT', 'Nueva persona: Dylan Mamani Laura (CI: 2000517LP)', '2026-07-26', '07:21:43'),
(1782, NULL, 'INSERT', 'Nuevo estudiante RU=1006316 Plan=7 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1783, 393, 'INSERT', 'Creación de usuario: dmamanil', '2026-07-26', '07:21:43'),
(1784, NULL, 'INSERT', 'Nueva persona: Amanda Ticona Flores (CI: 2000518LP)', '2026-07-26', '07:21:43'),
(1785, NULL, 'INSERT', 'Nuevo estudiante RU=1006317 Plan=8 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1786, 394, 'INSERT', 'Creación de usuario: aticonaf', '2026-07-26', '07:21:43'),
(1787, NULL, 'INSERT', 'Nueva persona: Axel Huanca Quispe (CI: 2000519LP)', '2026-07-26', '07:21:43'),
(1788, NULL, 'INSERT', 'Nuevo estudiante RU=1006318 Plan=9 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1789, 395, 'INSERT', 'Creación de usuario: ahuancaq', '2026-07-26', '07:21:43'),
(1790, NULL, 'INSERT', 'Nueva persona: Martina Apaza Mamani (CI: 2000520LP)', '2026-07-26', '07:21:43'),
(1791, NULL, 'INSERT', 'Nuevo estudiante RU=1006319 Plan=10 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1792, 396, 'INSERT', 'Creación de usuario: mapazam', '2026-07-26', '07:21:43'),
(1793, NULL, 'INSERT', 'Nueva persona: Lucas Laura Flores (CI: 2000521LP)', '2026-07-26', '07:21:43'),
(1794, NULL, 'INSERT', 'Nuevo estudiante RU=1006320 Plan=1 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1795, 397, 'INSERT', 'Creación de usuario: llauraf', '2026-07-26', '07:21:43'),
(1796, NULL, 'INSERT', 'Nueva persona: Antonella Condori Apaza (CI: 2000522LP)', '2026-07-26', '07:21:43'),
(1797, NULL, 'INSERT', 'Nuevo estudiante RU=1006321 Plan=2 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1798, 398, 'INSERT', 'Creación de usuario: acondoria1', '2026-07-26', '07:21:43'),
(1799, NULL, 'INSERT', 'Nueva persona: Benjamín Mamani Huanca (CI: 2000523LP)', '2026-07-26', '07:21:43'),
(1800, NULL, 'INSERT', 'Nuevo estudiante RU=1006322 Plan=3 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1801, 399, 'INSERT', 'Creación de usuario: bmamanih1', '2026-07-26', '07:21:43'),
(1802, NULL, 'INSERT', 'Nueva persona: Juliana Quispe Laura (CI: 2000524LP)', '2026-07-26', '07:21:43'),
(1803, NULL, 'INSERT', 'Nuevo estudiante RU=1006323 Plan=4 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1804, 400, 'INSERT', 'Creación de usuario: jquispel', '2026-07-26', '07:21:43'),
(1805, NULL, 'INSERT', 'Nueva persona: Ignacio Flores Condori (CI: 2000525LP)', '2026-07-26', '07:21:43'),
(1806, NULL, 'INSERT', 'Nuevo estudiante RU=1006324 Plan=5 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1807, 401, 'INSERT', 'Creación de usuario: ifloresc', '2026-07-26', '07:21:43'),
(1808, NULL, 'INSERT', 'Nueva persona: Elena Ticona Mamani (CI: 2000526LP)', '2026-07-26', '07:21:43'),
(1809, NULL, 'INSERT', 'Nuevo estudiante RU=1006325 Plan=6 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1810, 402, 'INSERT', 'Creación de usuario: eticonam2', '2026-07-26', '07:21:43'),
(1811, NULL, 'INSERT', 'Nueva persona: Tomás Huanca Apaza (CI: 2000527LP)', '2026-07-26', '07:21:43'),
(1812, NULL, 'INSERT', 'Nuevo estudiante RU=1006326 Plan=7 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1813, 403, 'INSERT', 'Creación de usuario: thuancaa', '2026-07-26', '07:21:43'),
(1814, NULL, 'INSERT', 'Nueva persona: Clara Apaza Laura (CI: 2000528LP)', '2026-07-26', '07:21:43'),
(1815, NULL, 'INSERT', 'Nuevo estudiante RU=1006327 Plan=8 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1816, 404, 'INSERT', 'Creación de usuario: capazal1', '2026-07-26', '07:21:43'),
(1817, NULL, 'INSERT', 'Nueva persona: Pablo Mamani Quispe (CI: 2000529LP)', '2026-07-26', '07:21:43'),
(1818, NULL, 'INSERT', 'Nuevo estudiante RU=1006328 Plan=9 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1819, 405, 'INSERT', 'Creación de usuario: pmamaniq', '2026-07-26', '07:21:43'),
(1820, NULL, 'INSERT', 'Nueva persona: Olivia Condori Flores (CI: 2000530LP)', '2026-07-26', '07:21:43'),
(1821, NULL, 'INSERT', 'Nuevo estudiante RU=1006329 Plan=10 Ingreso=I/2026', '2026-07-26', '07:21:43'),
(1822, 406, 'INSERT', 'Creación de usuario: ocondorif', '2026-07-26', '07:21:43'),
(1823, NULL, 'INSERT', 'Nueva persona: Thiago Laura Ticona (CI: 2000531LP)', '2026-07-26', '07:21:43'),
(1824, NULL, 'INSERT', 'Nuevo estudiante RU=1006330 Plan=1 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1825, 407, 'INSERT', 'Creación de usuario: tlaurat', '2026-07-26', '07:21:43'),
(1826, NULL, 'INSERT', 'Nueva persona: Julia Quispe Mamani (CI: 2000532LP)', '2026-07-26', '07:21:43'),
(1827, NULL, 'INSERT', 'Nuevo estudiante RU=1006331 Plan=2 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1828, 408, 'INSERT', 'Creación de usuario: jquispem', '2026-07-26', '07:21:43'),
(1829, NULL, 'INSERT', 'Nueva persona: Adrián Flores Apaza (CI: 2000533LP)', '2026-07-26', '07:21:43'),
(1830, NULL, 'INSERT', 'Nuevo estudiante RU=1006332 Plan=3 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1831, 409, 'INSERT', 'Creación de usuario: afloresa1', '2026-07-26', '07:21:43'),
(1832, NULL, 'INSERT', 'Nueva persona: Paula Ticona Laura (CI: 2000534LP)', '2026-07-26', '07:21:43'),
(1833, NULL, 'INSERT', 'Nuevo estudiante RU=1006333 Plan=4 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1834, 410, 'INSERT', 'Creación de usuario: pticonal', '2026-07-26', '07:21:43'),
(1835, NULL, 'INSERT', 'Nueva persona: Maximiliano Huanca Mamani (CI: 2000535LP)', '2026-07-26', '07:21:43'),
(1836, NULL, 'INSERT', 'Nuevo estudiante RU=1006334 Plan=5 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1837, 411, 'INSERT', 'Creación de usuario: mhuancam', '2026-07-26', '07:21:43'),
(1838, NULL, 'INSERT', 'Nueva persona: Rafaela Apaza Condori (CI: 2000536LP)', '2026-07-26', '07:21:43'),
(1839, NULL, 'INSERT', 'Nuevo estudiante RU=1006335 Plan=6 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1840, 412, 'INSERT', 'Creación de usuario: rapazac2', '2026-07-26', '07:21:43'),
(1841, NULL, 'INSERT', 'Nueva persona: Samuel Laura Quispe (CI: 2000537LP)', '2026-07-26', '07:21:43'),
(1842, NULL, 'INSERT', 'Nuevo estudiante RU=1006336 Plan=7 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1843, 413, 'INSERT', 'Creación de usuario: slauraq2', '2026-07-26', '07:21:43'),
(1844, NULL, 'INSERT', 'Nueva persona: Valeria Flores Apaza (CI: 2000538LP)', '2026-07-26', '07:21:43'),
(1845, NULL, 'INSERT', 'Nuevo estudiante RU=1006337 Plan=8 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1846, 414, 'INSERT', 'Creación de usuario: vfloresa', '2026-07-26', '07:21:43'),
(1847, NULL, 'INSERT', 'Nueva persona: Facundo Condori Mamani (CI: 2000539LP)', '2026-07-26', '07:21:43'),
(1848, NULL, 'INSERT', 'Nuevo estudiante RU=1006338 Plan=9 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1849, 415, 'INSERT', 'Creación de usuario: fcondorim1', '2026-07-26', '07:21:43'),
(1850, NULL, 'INSERT', 'Nueva persona: Carla Quispe Ticona (CI: 2000540LP)', '2026-07-26', '07:21:43'),
(1851, NULL, 'INSERT', 'Nuevo estudiante RU=1006339 Plan=10 Ingreso=I/2025', '2026-07-26', '07:21:43'),
(1852, 416, 'INSERT', 'Creación de usuario: cquispet', '2026-07-26', '07:21:43'),
(1853, NULL, 'INSERT', 'Nueva persona: Emilio Mamani Laura (CI: 2000541LP)', '2026-07-26', '07:22:06'),
(1854, NULL, 'INSERT', 'Nuevo estudiante RU=1006340 Plan=1 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1855, 417, 'INSERT', 'Creación de usuario: emamanil1', '2026-07-26', '07:22:06'),
(1856, NULL, 'INSERT', 'Nueva persona: Celia Ticona Flores (CI: 2000542LP)', '2026-07-26', '07:22:06'),
(1857, NULL, 'INSERT', 'Nuevo estudiante RU=1006341 Plan=2 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1858, 418, 'INSERT', 'Creación de usuario: cticonaf2', '2026-07-26', '07:22:06'),
(1859, NULL, 'INSERT', 'Nueva persona: Felipe Huanca Quispe (CI: 2000543LP)', '2026-07-26', '07:22:06'),
(1860, NULL, 'INSERT', 'Nuevo estudiante RU=1006342 Plan=3 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1861, 419, 'INSERT', 'Creación de usuario: fhuancaq1', '2026-07-26', '07:22:06'),
(1862, NULL, 'INSERT', 'Nueva persona: Vera Apaza Mamani (CI: 2000544LP)', '2026-07-26', '07:22:06'),
(1863, NULL, 'INSERT', 'Nuevo estudiante RU=1006343 Plan=4 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1864, 420, 'INSERT', 'Creación de usuario: vapazam1', '2026-07-26', '07:22:06'),
(1865, NULL, 'INSERT', 'Nueva persona: Hugo Laura Flores (CI: 2000545LP)', '2026-07-26', '07:22:06'),
(1866, NULL, 'INSERT', 'Nuevo estudiante RU=1006344 Plan=5 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1867, 421, 'INSERT', 'Creación de usuario: hlauraf', '2026-07-26', '07:22:06'),
(1868, NULL, 'INSERT', 'Nueva persona: Diana Condori Apaza (CI: 2000546LP)', '2026-07-26', '07:22:06'),
(1869, NULL, 'INSERT', 'Nuevo estudiante RU=1006345 Plan=6 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1870, 422, 'INSERT', 'Creación de usuario: dcondoria1', '2026-07-26', '07:22:06'),
(1871, NULL, 'INSERT', 'Nueva persona: Martín Mamani Huanca (CI: 2000547LP)', '2026-07-26', '07:22:06'),
(1872, NULL, 'INSERT', 'Nuevo estudiante RU=1006346 Plan=7 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1873, 423, 'INSERT', 'Creación de usuario: mmamanih1', '2026-07-26', '07:22:06'),
(1874, NULL, 'INSERT', 'Nueva persona: Eva Quispe Laura (CI: 2000548LP)', '2026-07-26', '07:22:06'),
(1875, NULL, 'INSERT', 'Nuevo estudiante RU=1006347 Plan=8 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1876, 424, 'INSERT', 'Creación de usuario: equispel', '2026-07-26', '07:22:06'),
(1877, NULL, 'INSERT', 'Nueva persona: Pedro Flores Condori (CI: 2000549LP)', '2026-07-26', '07:22:06'),
(1878, NULL, 'INSERT', 'Nuevo estudiante RU=1006348 Plan=9 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1879, 425, 'INSERT', 'Creación de usuario: pfloresc1', '2026-07-26', '07:22:06'),
(1880, NULL, 'INSERT', 'Nueva persona: Lola Ticona Mamani (CI: 2000550LP)', '2026-07-26', '07:22:06'),
(1881, NULL, 'INSERT', 'Nuevo estudiante RU=1006349 Plan=10 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1882, 426, 'INSERT', 'Creación de usuario: lticonam', '2026-07-26', '07:22:06'),
(1883, NULL, 'INSERT', 'Nueva persona: Álvaro Huanca Apaza (CI: 2000551LP)', '2026-07-26', '07:22:06'),
(1884, NULL, 'INSERT', 'Nuevo estudiante RU=1006350 Plan=1 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1885, 427, 'INSERT', 'Creación de usuario: áhuancaa', '2026-07-26', '07:22:06'),
(1886, NULL, 'INSERT', 'Nueva persona: Inés Apaza Laura (CI: 2000552LP)', '2026-07-26', '07:22:06'),
(1887, NULL, 'INSERT', 'Nuevo estudiante RU=1006351 Plan=2 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1888, 428, 'INSERT', 'Creación de usuario: iapazal', '2026-07-26', '07:22:06'),
(1889, NULL, 'INSERT', 'Nueva persona: Rafael Mamani Quispe (CI: 2000553LP)', '2026-07-26', '07:22:06'),
(1890, NULL, 'INSERT', 'Nuevo estudiante RU=1006352 Plan=3 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1891, 429, 'INSERT', 'Creación de usuario: rmamaniq', '2026-07-26', '07:22:06'),
(1892, NULL, 'INSERT', 'Nueva persona: Sara Condori Flores (CI: 2000554LP)', '2026-07-26', '07:22:06'),
(1893, NULL, 'INSERT', 'Nuevo estudiante RU=1006353 Plan=4 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1894, 430, 'INSERT', 'Creación de usuario: scondorif', '2026-07-26', '07:22:06'),
(1895, NULL, 'INSERT', 'Nueva persona: Marcos Laura Ticona (CI: 2000555LP)', '2026-07-26', '07:22:06'),
(1896, NULL, 'INSERT', 'Nuevo estudiante RU=1006354 Plan=5 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1897, 431, 'INSERT', 'Creación de usuario: mlaurat', '2026-07-26', '07:22:06'),
(1898, NULL, 'INSERT', 'Nueva persona: Abril Quispe Mamani (CI: 2000556LP)', '2026-07-26', '07:22:06'),
(1899, NULL, 'INSERT', 'Nuevo estudiante RU=1006355 Plan=6 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1900, 432, 'INSERT', 'Creación de usuario: aquispem3', '2026-07-26', '07:22:06'),
(1901, NULL, 'INSERT', 'Nueva persona: Vicente Flores Apaza (CI: 2000557LP)', '2026-07-26', '07:22:06'),
(1902, NULL, 'INSERT', 'Nuevo estudiante RU=1006356 Plan=7 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1903, 433, 'INSERT', 'Creación de usuario: vfloresa1', '2026-07-26', '07:22:06'),
(1904, NULL, 'INSERT', 'Nueva persona: Noa Ticona Laura (CI: 2000558LP)', '2026-07-26', '07:22:06'),
(1905, NULL, 'INSERT', 'Nuevo estudiante RU=1006357 Plan=8 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1906, 434, 'INSERT', 'Creación de usuario: nticonal3', '2026-07-26', '07:22:06'),
(1907, NULL, 'INSERT', 'Nueva persona: Gael Huanca Mamani (CI: 2000559LP)', '2026-07-26', '07:22:06'),
(1908, NULL, 'INSERT', 'Nuevo estudiante RU=1006358 Plan=9 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1909, 435, 'INSERT', 'Creación de usuario: ghuancam', '2026-07-26', '07:22:06'),
(1910, NULL, 'INSERT', 'Nueva persona: Alba Apaza Condori (CI: 2000560LP)', '2026-07-26', '07:22:06'),
(1911, NULL, 'INSERT', 'Nuevo estudiante RU=1006359 Plan=10 Ingreso=I/2026', '2026-07-26', '07:22:06'),
(1912, 436, 'INSERT', 'Creación de usuario: aapazac2', '2026-07-26', '07:22:06'),
(1913, NULL, 'INSERT', 'Nueva persona: Eric Laura Quispe (CI: 2000561LP)', '2026-07-26', '07:22:06'),
(1914, NULL, 'INSERT', 'Nuevo estudiante RU=1006360 Plan=1 Ingreso=I/2025', '2026-07-26', '07:22:06'),
(1915, 437, 'INSERT', 'Creación de usuario: elauraq5', '2026-07-26', '07:22:06'),
(1916, NULL, 'INSERT', 'Nueva persona: Chloe Flores Apaza (CI: 2000562LP)', '2026-07-26', '07:22:06'),
(1917, NULL, 'INSERT', 'Nuevo estudiante RU=1006361 Plan=2 Ingreso=I/2025', '2026-07-26', '07:22:06'),
(1918, 438, 'INSERT', 'Creación de usuario: cfloresa2', '2026-07-26', '07:22:06'),
(1919, NULL, 'INSERT', 'Nueva persona: Héctor Condori Mamani (CI: 2000563LP)', '2026-07-26', '07:22:06'),
(1920, NULL, 'INSERT', 'Nuevo estudiante RU=1006362 Plan=3 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1921, 439, 'INSERT', 'Creación de usuario: hcondorim1', '2026-07-26', '07:22:07'),
(1922, NULL, 'INSERT', 'Nueva persona: Nora Quispe Ticona (CI: 2000564LP)', '2026-07-26', '07:22:07'),
(1923, NULL, 'INSERT', 'Nuevo estudiante RU=1006363 Plan=4 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1924, 440, 'INSERT', 'Creación de usuario: nquispet1', '2026-07-26', '07:22:07'),
(1925, NULL, 'INSERT', 'Nueva persona: Iker Mamani Laura (CI: 2000565LP)', '2026-07-26', '07:22:07'),
(1926, NULL, 'INSERT', 'Nuevo estudiante RU=1006364 Plan=5 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1927, 441, 'INSERT', 'Creación de usuario: imamanil', '2026-07-26', '07:22:07'),
(1928, NULL, 'INSERT', 'Nueva persona: Alicia Ticona Flores (CI: 2000566LP)', '2026-07-26', '07:22:07'),
(1929, NULL, 'INSERT', 'Nuevo estudiante RU=1006365 Plan=6 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1930, 442, 'INSERT', 'Creación de usuario: aticonaf1', '2026-07-26', '07:22:07'),
(1931, NULL, 'INSERT', 'Nueva persona: Asier Huanca Quispe (CI: 2000567LP)', '2026-07-26', '07:22:07'),
(1932, NULL, 'INSERT', 'Nuevo estudiante RU=1006366 Plan=7 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1933, 443, 'INSERT', 'Creación de usuario: ahuancaq1', '2026-07-26', '07:22:07'),
(1934, NULL, 'INSERT', 'Nueva persona: Carmen Apaza Mamani (CI: 2000568LP)', '2026-07-26', '07:22:07'),
(1935, NULL, 'INSERT', 'Nuevo estudiante RU=1006367 Plan=8 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1936, 444, 'INSERT', 'Creación de usuario: capazam1', '2026-07-26', '07:22:07'),
(1937, NULL, 'INSERT', 'Nueva persona: Jon Laura Flores (CI: 2000569LP)', '2026-07-26', '07:22:07'),
(1938, NULL, 'INSERT', 'Nuevo estudiante RU=1006368 Plan=9 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1939, 445, 'INSERT', 'Creación de usuario: jlauraf', '2026-07-26', '07:22:07'),
(1940, NULL, 'INSERT', 'Nueva persona: Triana Condori Apaza (CI: 2000570LP)', '2026-07-26', '07:22:07'),
(1941, NULL, 'INSERT', 'Nuevo estudiante RU=1006369 Plan=10 Ingreso=I/2025', '2026-07-26', '07:22:07'),
(1942, 446, 'INSERT', 'Creación de usuario: tcondoria', '2026-07-26', '07:22:07'),
(1943, NULL, 'INSERT', 'Nueva persona: Unai Mamani Huanca (CI: 2000571LP)', '2026-07-26', '07:22:21'),
(1944, NULL, 'INSERT', 'Nuevo estudiante RU=1006370 Plan=1 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1945, 447, 'INSERT', 'Creación de usuario: umamanih', '2026-07-26', '07:22:21'),
(1946, NULL, 'INSERT', 'Nueva persona: Laia Quispe Laura (CI: 2000572LP)', '2026-07-26', '07:22:21'),
(1947, NULL, 'INSERT', 'Nuevo estudiante RU=1006371 Plan=2 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1948, 448, 'INSERT', 'Creación de usuario: lquispel', '2026-07-26', '07:22:21'),
(1949, NULL, 'INSERT', 'Nueva persona: Biel Flores Condori (CI: 2000573LP)', '2026-07-26', '07:22:21'),
(1950, NULL, 'INSERT', 'Nuevo estudiante RU=1006372 Plan=3 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1951, 449, 'INSERT', 'Creación de usuario: bfloresc', '2026-07-26', '07:22:21'),
(1952, NULL, 'INSERT', 'Nueva persona: Ona Ticona Mamani (CI: 2000574LP)', '2026-07-26', '07:22:21'),
(1953, NULL, 'INSERT', 'Nuevo estudiante RU=1006373 Plan=4 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1954, 450, 'INSERT', 'Creación de usuario: oticonam', '2026-07-26', '07:22:21'),
(1955, NULL, 'INSERT', 'Nueva persona: Arnau Huanca Apaza (CI: 2000575LP)', '2026-07-26', '07:22:21'),
(1956, NULL, 'INSERT', 'Nuevo estudiante RU=1006374 Plan=5 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1957, 451, 'INSERT', 'Creación de usuario: ahuancaa1', '2026-07-26', '07:22:21'),
(1958, NULL, 'INSERT', 'Nueva persona: Marina Apaza Laura (CI: 2000576LP)', '2026-07-26', '07:22:21'),
(1959, NULL, 'INSERT', 'Nuevo estudiante RU=1006375 Plan=6 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1960, 452, 'INSERT', 'Creación de usuario: mapazal', '2026-07-26', '07:22:21'),
(1961, NULL, 'INSERT', 'Nueva persona: Pol Mamani Quispe (CI: 2000577LP)', '2026-07-26', '07:22:21'),
(1962, NULL, 'INSERT', 'Nuevo estudiante RU=1006376 Plan=7 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1963, 453, 'INSERT', 'Creación de usuario: pmamaniq1', '2026-07-26', '07:22:21'),
(1964, NULL, 'INSERT', 'Nueva persona: Elsa Condori Flores (CI: 2000578LP)', '2026-07-26', '07:22:21'),
(1965, NULL, 'INSERT', 'Nuevo estudiante RU=1006377 Plan=8 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1966, 454, 'INSERT', 'Creación de usuario: econdorif1', '2026-07-26', '07:22:21'),
(1967, NULL, 'INSERT', 'Nueva persona: Jan Laura Ticona (CI: 2000579LP)', '2026-07-26', '07:22:21'),
(1968, NULL, 'INSERT', 'Nuevo estudiante RU=1006378 Plan=9 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1969, 455, 'INSERT', 'Creación de usuario: jlaurat1', '2026-07-26', '07:22:21'),
(1970, NULL, 'INSERT', 'Nueva persona: Blanca Quispe Mamani (CI: 2000580LP)', '2026-07-26', '07:22:21'),
(1971, NULL, 'INSERT', 'Nuevo estudiante RU=1006379 Plan=10 Ingreso=I/2026', '2026-07-26', '07:22:21'),
(1972, 456, 'INSERT', 'Creación de usuario: bquispem', '2026-07-26', '07:22:21'),
(1973, NULL, 'INSERT', 'Nueva persona: Oriol Flores Apaza (CI: 2000581LP)', '2026-07-26', '07:22:53'),
(1974, NULL, 'INSERT', 'Nuevo estudiante RU=1006380 Plan=1 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1975, 457, 'INSERT', 'Creación de usuario: ofloresa', '2026-07-26', '07:22:53'),
(1976, NULL, 'INSERT', 'Nueva persona: Neus Ticona Laura (CI: 2000582LP)', '2026-07-26', '07:22:53'),
(1977, NULL, 'INSERT', 'Nuevo estudiante RU=1006381 Plan=2 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1978, 458, 'INSERT', 'Creación de usuario: nticonal4', '2026-07-26', '07:22:53'),
(1979, NULL, 'INSERT', 'Nueva persona: Gerard Huanca Mamani (CI: 2000583LP)', '2026-07-26', '07:22:53'),
(1980, NULL, 'INSERT', 'Nuevo estudiante RU=1006382 Plan=3 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1981, 459, 'INSERT', 'Creación de usuario: ghuancam1', '2026-07-26', '07:22:53'),
(1982, NULL, 'INSERT', 'Nueva persona: Ivet Apaza Condori (CI: 2000584LP)', '2026-07-26', '07:22:53'),
(1983, NULL, 'INSERT', 'Nuevo estudiante RU=1006383 Plan=4 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1984, 460, 'INSERT', 'Creación de usuario: iapazac', '2026-07-26', '07:22:53'),
(1985, NULL, 'INSERT', 'Nueva persona: Quim Laura Quispe (CI: 2000585LP)', '2026-07-26', '07:22:53'),
(1986, NULL, 'INSERT', 'Nuevo estudiante RU=1006384 Plan=5 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1987, 461, 'INSERT', 'Creación de usuario: qlauraq', '2026-07-26', '07:22:53'),
(1988, NULL, 'INSERT', 'Nueva persona: Txell Flores Apaza (CI: 2000586LP)', '2026-07-26', '07:22:53'),
(1989, NULL, 'INSERT', 'Nuevo estudiante RU=1006385 Plan=6 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1990, 462, 'INSERT', 'Creación de usuario: tfloresa2', '2026-07-26', '07:22:53'),
(1991, NULL, 'INSERT', 'Nueva persona: Nil Condori Mamani (CI: 2000587LP)', '2026-07-26', '07:22:53'),
(1992, NULL, 'INSERT', 'Nuevo estudiante RU=1006386 Plan=7 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1993, 463, 'INSERT', 'Creación de usuario: ncondorim1', '2026-07-26', '07:22:53'),
(1994, NULL, 'INSERT', 'Nueva persona: Bruna Quispe Ticona (CI: 2000588LP)', '2026-07-26', '07:22:53'),
(1995, NULL, 'INSERT', 'Nuevo estudiante RU=1006387 Plan=8 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1996, 464, 'INSERT', 'Creación de usuario: bquispet1', '2026-07-26', '07:22:53'),
(1997, NULL, 'INSERT', 'Nueva persona: Roc Mamani Laura (CI: 2000589LP)', '2026-07-26', '07:22:53'),
(1998, NULL, 'INSERT', 'Nuevo estudiante RU=1006388 Plan=9 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(1999, 465, 'INSERT', 'Creación de usuario: rmamanil', '2026-07-26', '07:22:53'),
(2000, NULL, 'INSERT', 'Nueva persona: Jana Ticona Flores (CI: 2000590LP)', '2026-07-26', '07:22:53'),
(2001, NULL, 'INSERT', 'Nuevo estudiante RU=1006389 Plan=10 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2002, 466, 'INSERT', 'Creación de usuario: jticonaf2', '2026-07-26', '07:22:53'),
(2003, NULL, 'INSERT', 'Nueva persona: Pau Huanca Quispe (CI: 2000591LP)', '2026-07-26', '07:22:53'),
(2004, NULL, 'INSERT', 'Nuevo estudiante RU=1006390 Plan=1 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2005, 467, 'INSERT', 'Creación de usuario: phuancaq', '2026-07-26', '07:22:53'),
(2006, NULL, 'INSERT', 'Nueva persona: Lluc Apaza Mamani (CI: 2000592LP)', '2026-07-26', '07:22:53'),
(2007, NULL, 'INSERT', 'Nuevo estudiante RU=1006391 Plan=2 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2008, 468, 'INSERT', 'Creación de usuario: lapazam', '2026-07-26', '07:22:53'),
(2009, NULL, 'INSERT', 'Nueva persona: Max Laura Flores (CI: 2000593LP)', '2026-07-26', '07:22:53'),
(2010, NULL, 'INSERT', 'Nuevo estudiante RU=1006392 Plan=3 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2011, 469, 'INSERT', 'Creación de usuario: mlauraf', '2026-07-26', '07:22:53'),
(2012, NULL, 'INSERT', 'Nueva persona: Iris Condori Apaza (CI: 2000594LP)', '2026-07-26', '07:22:53'),
(2013, NULL, 'INSERT', 'Nuevo estudiante RU=1006393 Plan=4 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2014, 470, 'INSERT', 'Creación de usuario: icondoria', '2026-07-26', '07:22:53'),
(2015, NULL, 'INSERT', 'Nueva persona: Teo Mamani Huanca (CI: 2000595LP)', '2026-07-26', '07:22:53'),
(2016, NULL, 'INSERT', 'Nuevo estudiante RU=1006394 Plan=5 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2017, 471, 'INSERT', 'Creación de usuario: tmamanih', '2026-07-26', '07:22:53'),
(2018, NULL, 'INSERT', 'Nueva persona: Lara Quispe Laura (CI: 2000596LP)', '2026-07-26', '07:22:53'),
(2019, NULL, 'INSERT', 'Nuevo estudiante RU=1006395 Plan=6 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2020, 472, 'INSERT', 'Creación de usuario: lquispel1', '2026-07-26', '07:22:53'),
(2021, NULL, 'INSERT', 'Nueva persona: Enzo Flores Condori (CI: 2000597LP)', '2026-07-26', '07:22:53'),
(2022, NULL, 'INSERT', 'Nuevo estudiante RU=1006396 Plan=7 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2023, 473, 'INSERT', 'Creación de usuario: efloresc1', '2026-07-26', '07:22:53'),
(2024, NULL, 'INSERT', 'Nueva persona: Claudia Ticona Mamani (CI: 2000598LP)', '2026-07-26', '07:22:53'),
(2025, NULL, 'INSERT', 'Nuevo estudiante RU=1006397 Plan=8 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2026, 474, 'INSERT', 'Creación de usuario: cticonam', '2026-07-26', '07:22:53'),
(2027, NULL, 'INSERT', 'Nueva persona: Leo Huanca Apaza (CI: 2000599LP)', '2026-07-26', '07:22:53'),
(2028, NULL, 'INSERT', 'Nuevo estudiante RU=1006398 Plan=9 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2029, 475, 'INSERT', 'Creación de usuario: lhuancaa2', '2026-07-26', '07:22:53'),
(2030, NULL, 'INSERT', 'Nueva persona: Ana Apaza Laura (CI: 2000600LP)', '2026-07-26', '07:22:53'),
(2031, NULL, 'INSERT', 'Nuevo estudiante RU=1006399 Plan=10 Ingreso=I/2026', '2026-07-26', '07:22:53'),
(2032, 476, 'INSERT', 'Creación de usuario: aapazal2', '2026-07-26', '07:22:53'),
(2033, NULL, 'INSERT', 'Nueva persona: Luis Alejandro Zeballos Quiroz (CI: 2000601LP)', '2026-07-26', '07:26:21'),
(2034, NULL, 'INSERT', 'Nuevo estudiante RU=1006400 Plan=1 Ingreso=I/2025', '2026-07-26', '07:26:21'),
(2035, 477, 'INSERT', 'Creación de usuario: lzeballosq', '2026-07-26', '07:26:21'),
(2036, NULL, 'UPDATE', 'Actualización persona ID=478 de Luis Alejandro a Luis Alejandro', '2026-07-26', '07:26:21'),
(2037, NULL, 'UPDATE', 'Actualización persona ID=478 de Luis Alejandro a Luis Alejandro', '2026-07-26', '07:26:21'),
(2038, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '07:27:20'),
(2039, 1, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '07:28:56'),
(2040, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '07:33:07'),
(2041, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '07:35:15'),
(2042, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '07:35:37'),
(2043, 1, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '12:45:31'),
(2044, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '12:46:25'),
(2045, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '14:02:53'),
(2046, 7, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '14:03:00'),
(2047, 7, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '14:04:47'),
(2048, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '14:04:53'),
(2049, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '14:17:10'),
(2050, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '14:19:54'),
(2051, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '15:42:45'),
(2052, 7, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '15:42:58'),
(2053, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '16:44:21'),
(2054, NULL, 'UPDATE', 'Actualización persona ID=2 de María Elena a Manuel Ramiro', '2026-07-26', '17:02:21'),
(2055, NULL, 'UPDATE', 'Actualización persona ID=3 de Jorge Luis a Francisco', '2026-07-26', '17:02:21'),
(2056, NULL, 'UPDATE', 'Actualización persona ID=4 de Gabriela a Luis Alejandro', '2026-07-26', '17:02:21'),
(2057, NULL, 'INSERT', 'Nuevo docente Reg=DOC-2002 Grado=M.Sc.', '2026-07-26', '17:02:21'),
(2058, NULL, 'INSERT', 'Nuevo docente Reg=DOC-2003 Grado=Lic.', '2026-07-26', '17:02:21'),
(2059, NULL, 'INSERT', 'Nuevo estudiante RU=RU-1004 Plan=1 Ingreso=2022', '2026-07-26', '17:02:21'),
(2060, NULL, 'UPDATE', 'Actualización persona ID=1 de Carlos Andrés a Carlos', '2026-07-26', '17:02:55'),
(2061, NULL, 'INSERT', 'Nuevo estudiante RU=RU-1001 Plan=1 Ingreso=2021', '2026-07-26', '17:02:55'),
(2062, NULL, 'INSERT', 'Nueva nota ID=1001 puntaje=85 criterio=10', '2026-07-26', '17:06:37'),
(2063, NULL, 'INSERT', 'Nueva nota ID=1002 puntaje=78 criterio=11', '2026-07-26', '17:06:37'),
(2064, NULL, 'INSERT', 'Nueva nota ID=1003 puntaje=90 criterio=12', '2026-07-26', '17:06:37'),
(2065, NULL, 'INSERT', 'Nueva nota ID=1004 puntaje=100 criterio=13', '2026-07-26', '17:06:37'),
(2066, NULL, 'INSERT', 'Nueva nota ID=1005 puntaje=45 criterio=10', '2026-07-26', '17:06:37'),
(2067, NULL, 'INSERT', 'Nueva nota ID=1006 puntaje=50 criterio=11', '2026-07-26', '17:06:37'),
(2068, NULL, 'INSERT', 'Nueva nota ID=1007 puntaje=92 criterio=14', '2026-07-26', '17:06:37'),
(2069, NULL, 'INSERT', 'Nueva nota ID=1008 puntaje=88 criterio=15', '2026-07-26', '17:06:37'),
(2070, 2, 'INSERT', 'Apertura de Gestión Académica Invierno/2026', '2026-07-01', '08:00:00'),
(2071, 2, 'INSERT', 'Asignación de Materia: INF-111 Paralelo A', '2026-07-02', '09:30:15'),
(2072, 2, 'INSERT', 'Asignación de Materia: INF-112 Paralelo A', '2026-07-02', '09:32:00'),
(2073, 3, 'INSERT', 'Asignación de Materia: INF-113 Paralelo A', '2026-07-03', '10:14:22'),
(2074, 4, 'INSERT', 'Inscripción de Estudiante en INF-111 e INF-112 (Invierno/2026)', '2026-07-20', '09:15:00'),
(2075, 2, 'INSERT', 'Configuración de Criterios de Evaluación para INF-111 (100%)', '2026-07-21', '14:20:00'),
(2076, 2, 'INSERT', 'Ingreso de Calificaciones Parciales para Estudiante 4 en INF-111', '2026-07-25', '16:45:10'),
(2077, 1, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '17:07:22'),
(2078, 1, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '17:22:43'),
(2079, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '17:22:52'),
(2080, 7, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '17:25:00'),
(2081, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '17:34:34'),
(2082, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '17:37:11'),
(2083, NULL, 'UPDATE', 'Nota ID=1001 actualizada de 85 a 29.5', '2026-07-26', '18:14:24'),
(2084, NULL, 'UPDATE', 'Nota ID=1002 actualizada de 78 a 24.18', '2026-07-26', '18:15:44'),
(2085, NULL, 'UPDATE', 'Nota ID=1003 actualizada de 90 a 27', '2026-07-26', '18:15:44'),
(2086, NULL, 'UPDATE', 'Nota ID=1005 actualizada de 45 a 13.5', '2026-07-26', '18:15:44'),
(2087, NULL, 'UPDATE', 'Nota ID=1006 actualizada de 50 a 15.5', '2026-07-26', '18:15:44'),
(2088, NULL, 'UPDATE', 'Nota ID=1007 actualizada de 92 a 36.8', '2026-07-26', '18:15:44'),
(2089, NULL, 'UPDATE', 'Nota ID=1008 actualizada de 88 a 52.8', '2026-07-26', '18:15:44'),
(2090, NULL, 'UPDATE', 'Nota ID=1001 actualizada de 29.5 a 30', '2026-07-26', '18:18:49'),
(2091, NULL, 'UPDATE', 'Nota ID=1002 actualizada de 24.18 a 31', '2026-07-26', '18:18:58'),
(2092, NULL, 'UPDATE', 'Nota ID=1002 actualizada de 31 a 31', '2026-07-26', '18:19:13'),
(2093, NULL, 'UPDATE', 'Nota ID=1002 actualizada de 31 a 31', '2026-07-26', '18:19:15'),
(2094, NULL, 'UPDATE', 'Nota ID=1002 actualizada de 31 a 31', '2026-07-26', '18:19:17'),
(2095, NULL, 'UPDATE', 'Nota ID=1006 actualizada de 15.5 a 15.5', '2026-07-26', '18:19:19'),
(2096, NULL, 'UPDATE', 'Nota ID=1006 actualizada de 15.5 a 16', '2026-07-26', '18:19:36'),
(2097, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:22:57'),
(2098, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:33:37'),
(2099, NULL, 'INSERT', 'Nueva nota ID=1009 puntaje=1.5 criterio=12', '2026-07-26', '18:39:57'),
(2100, NULL, 'INSERT', 'Nueva nota ID=1010 puntaje=2.5 criterio=11', '2026-07-26', '18:40:01'),
(2101, 3, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:43:44'),
(2102, 12, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:44:04'),
(2103, 455, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:44:27'),
(2104, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:44:36'),
(2105, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:46:41'),
(2106, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:46:53'),
(2107, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '18:47:03'),
(2108, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '20:52:18'),
(2109, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '20:57:55'),
(2110, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '20:58:34'),
(2111, 477, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '20:58:52'),
(2112, 29, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '20:59:10'),
(2113, NULL, 'INSERT', 'Nueva nota ID=1011 puntaje=15 criterio=10', '2026-07-26', '21:00:14'),
(2114, NULL, 'INSERT', 'Nueva nota ID=1012 puntaje=31 criterio=11', '2026-07-26', '21:00:25'),
(2115, NULL, 'INSERT', 'Nueva nota ID=1013 puntaje=30 criterio=12', '2026-07-26', '21:00:39'),
(2116, 1, 'INSERT', 'Inicio de sesión exitoso desde IP ::1', '2026-07-26', '21:00:58');

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
(1, 'PAB-A', 'PB', 'Pabellones', 250),
(2, 'PAB-B', 'PB', 'Pabellones', 250),
(3, 'PAB-C', 'PB', 'Pabellones', 250),
(4, 'PAB-D', 'PB', 'Pabellones', 250),
(5, 'PAB-E', 'PB', 'Pabellones', 250),
(6, 'PAB-F', 'PB', 'Pabellones', 250),
(7, 'PAB-G', 'PB', 'Pabellones', 250),
(8, 'SS-A1', 'Subsuelo', 'Edificio Informática', 100),
(9, 'SS-A2', 'Subsuelo', 'Edificio Informática', 100),
(10, 'SS-A3', 'Subsuelo', 'Edificio Informática', 100),
(11, 'SS-A4', 'Subsuelo', 'Edificio Informática', 100),
(12, 'P1-A1', 'Piso 1', 'Edificio Informática', 100),
(13, 'P1-A2', 'Piso 1', 'Edificio Informática', 100),
(14, 'P1-A3', 'Piso 1', 'Edificio Informática', 100),
(15, 'P1-A4', 'Piso 1', 'Edificio Informática', 100),
(16, 'P1-A5', 'Piso 1', 'Edificio Informática', 100),
(17, 'P1-A6', 'Piso 1', 'Edificio Informática', 100),
(18, 'P2-A1', 'Piso 2', 'Edificio Informática', 100),
(19, 'P2-A2', 'Piso 2', 'Edificio Informática', 100),
(20, 'P2-A3', 'Piso 2', 'Edificio Informática', 100),
(21, 'P2-A4', 'Piso 2', 'Edificio Informática', 100),
(22, 'P2-A5', 'Piso 2', 'Edificio Informática', 100),
(23, 'P2-A6', 'Piso 2', 'Edificio Informática', 100),
(24, 'P3-LAB1', 'Piso 3', 'Edificio Informática', 150),
(25, 'P3-LAB2', 'Piso 3', 'Edificio Informática', 150),
(26, 'P3-LAB3', 'Piso 3', 'Edificio Informática', 150),
(27, 'P3-LAB4', 'Piso 3', 'Edificio Informática', 150),
(28, 'P3-LAB5', 'Piso 3', 'Edificio Informática', 150),
(29, 'P4-LAB1', 'Piso 4', 'Edificio Informática', 150),
(30, 'P4-LAB2', 'Piso 4', 'Edificio Informática', 150),
(31, 'P4-LAB3', 'Piso 4', 'Edificio Informática', 150),
(32, 'P4-A1', 'Piso 4', 'Edificio Informática', 100),
(33, 'P4-A2', 'Piso 4', 'Edificio Informática', 100),
(34, 'P4-A3', 'Piso 4', 'Edificio Informática', 100),
(35, 'P5-A1', 'Piso 5', 'Edificio Informática', 100),
(36, 'P5-A2', 'Piso 5', 'Edificio Informática', 100),
(37, 'P5-A3', 'Piso 5', 'Edificio Informática', 100),
(38, 'P5-A4', 'Piso 5', 'Edificio Informática', 100),
(39, 'P5-A5', 'Piso 5', 'Edificio Informática', 100),
(40, 'P5-A6', 'Piso 5', 'Edificio Informática', 100),
(41, 'PB-A1', 'Planta Baja', 'Edificio Informática', 80),
(42, 'PB-A2', 'Planta Baja', 'Edificio Informática', 80),
(43, 'PB-A3', 'Planta Baja', 'Edificio Informática', 80),
(44, 'AULA 04-01-01', 'Piso 1', 'Edificio Antiguo', 150),
(45, 'AULA 04-01-02', 'Piso 1', 'Edificio Antiguo', 150),
(46, 'AULA 04-01-03', 'Piso 1', 'Edificio Antiguo', 150),
(47, 'AULA 04-01-04', 'Piso 1', 'Edificio Antiguo', 150),
(48, 'AULA 04-01-05', 'Piso 1', 'Edificio Antiguo', 150),
(49, 'AULA 04-01-06', 'Piso 1', 'Edificio Antiguo', 150),
(50, 'AULA 04-01-07', 'Piso 1', 'Edificio Antiguo', 150),
(51, 'AULA 04-01-08', 'Piso 1', 'Edificio Antiguo', 150),
(52, 'AULA 04-01-09', 'Piso 1', 'Edificio Antiguo', 150),
(53, 'AULA 04-02-01', 'Piso 2', 'Edificio Antiguo', 150),
(54, 'AULA 04-02-02', 'Piso 2', 'Edificio Antiguo', 150),
(55, 'AULA 04-02-03', 'Piso 2', 'Edificio Antiguo', 150),
(56, 'AULA 04-02-04', 'Piso 2', 'Edificio Antiguo', 150),
(57, 'AULA 04-02-05', 'Piso 2', 'Edificio Antiguo', 150),
(58, 'AULA 04-02-06', 'Piso 2', 'Edificio Antiguo', 150),
(59, 'AULA 04-02-07', 'Piso 2', 'Edificio Antiguo', 150),
(60, 'AULA 04-02-08', 'Piso 2', 'Edificio Antiguo', 150),
(61, 'AULA 04-02-09', 'Piso 2', 'Edificio Antiguo', 150),
(62, 'LASIN 1', 'Planta Baja', 'LASINs', 100),
(63, 'LASIN 2', 'Planta Baja', 'LASINs', 100);

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
-- Volcado de datos para la tabla `criterio_evaluacion`
--

INSERT INTO `criterio_evaluacion` (`id_criterio`, `id_materia`, `id_paralelo`, `nombre`, `ponderacion`) VALUES
(10, 1, 1, 'Primer Examen Parcial', 15),
(11, 1, 1, 'Segundo Examen Parcial', 31),
(12, 1, 1, 'Examen Final Consolidado', 30),
(14, 2, 1, 'Evaluación Continua', 40),
(15, 2, 1, 'Proyecto de Hardware/Lógica', 60),
(16, 1, 1, 'proy', 9);

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
-- Volcado de datos para la tabla `detalle_inscripcion`
--

INSERT INTO `detalle_inscripcion` (`id_detalle`, `id_inscripcion`, `id_materia`, `id_paralelo`, `estado`, `nota_final`) VALUES
(501, 100, 1, 1, 'Inscrito', 0),
(502, 100, 2, 1, 'Inscrito', 0),
(504, 101, 1, 1, 'Inscrito', 0),
(505, 101, 7, 1, 'Inscrito', 0),
(507, 102, 2, 1, 'Abandono', 0),
(511, 103, 1, 1, 'Reprobado', 20.86),
(512, 102, 1, 1, 'Reprobado', 0),
(515, 102, 2, 1, 'Reprobado', 0);

--
-- Disparadores `detalle_inscripcion`
--
DELIMITER $$
CREATE TRIGGER `trg_decrementar_cupo_actual` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW BEGIN
    UPDATE paralelo
    SET cupo_actual = GREATEST(cupo_actual - 1, 0)
    WHERE id_materia = OLD.id_materia AND id_paralelo = OLD.id_paralelo;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_incrementar_cupo_actual` AFTER INSERT ON `detalle_inscripcion` FOR EACH ROW BEGIN
    DECLARE v_id_gestion INT DEFAULT 1;
    SELECT id_gestion INTO v_id_gestion FROM inscripcion WHERE id_inscripcion = NEW.id_inscripcion LIMIT 1;
    
    UPDATE paralelo
    SET cupo_actual = cupo_actual + 1
    WHERE id_materia = NEW.id_materia 
      AND id_paralelo = NEW.id_paralelo
      AND id_gestion = v_id_gestion;
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
DELIMITER $$
CREATE TRIGGER `trg_validar_inscripcion_paralelo_cupo` BEFORE INSERT ON `detalle_inscripcion` FOR EACH ROW BEGIN
    DECLARE v_id_gestion INT;
    DECLARE v_cupo_maximo INT DEFAULT 35;
    DECLARE v_cupo_actual INT DEFAULT 0;
    
    -- Obtener la gestión de la cabecera de inscripción
    SELECT id_gestion INTO v_id_gestion
    FROM inscripcion
    WHERE id_inscripcion = NEW.id_inscripcion
    LIMIT 1;
    
    -- Verificar cupo disponible para esa gestión específica
    SELECT cupo_maximo, cupo_actual 
    INTO v_cupo_maximo, v_cupo_actual
    FROM paralelo
    WHERE id_materia = NEW.id_materia 
      AND id_paralelo = NEW.id_paralelo
      AND id_gestion = v_id_gestion
    LIMIT 1;
    
    IF v_cupo_actual >= v_cupo_maximo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No hay cupos disponibles en este paralelo.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_validar_limite_inscripcion` BEFORE INSERT ON `detalle_inscripcion` FOR EACH ROW BEGIN
    DECLARE v_periodo VARCHAR(20);
    DECLARE v_cantidad INT;
    DECLARE v_limite INT;
    
    SELECT g.periodo INTO v_periodo
    FROM inscripcion i
    JOIN gestion g ON i.id_gestion = g.id_gestion
    WHERE i.id_inscripcion = NEW.id_inscripcion;
    
    IF v_periodo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se encontró la gestión para esta inscripción.';
    END IF;
    
    SELECT COUNT(*) INTO v_cantidad
    FROM detalle_inscripcion
    WHERE id_inscripcion = NEW.id_inscripcion
      AND estado != 'Abandono';
    
    IF v_periodo LIKE 'Verano%' OR v_periodo LIKE 'Invierno%' THEN
        SET v_limite = 2;
    ELSE
        SET v_limite = 6;
    END IF;
    
    IF (v_cantidad + 1) > v_limite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Límite de inscripción excedido. Máximo materias permitidas.';
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
(2),
(8),
(13),
(17),
(29),
(30),
(32),
(36),
(40),
(57),
(58),
(60),
(61),
(62),
(63),
(64),
(65),
(66),
(67),
(68),
(69),
(70),
(71),
(72),
(73);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `director_carrera_asignacion`
--

CREATE TABLE `director_carrera_asignacion` (
  `id_persona` int(11) NOT NULL,
  `id_carrera` int(11) NOT NULL,
  `gestion` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `director_carrera_asignacion`
--

INSERT INTO `director_carrera_asignacion` (`id_persona`, `id_carrera`, `gestion`) VALUES
(2, 1, '2026-2028'),
(8, 1, '2016-2018'),
(8, 1, '2020-2022'),
(13, 1, '2018-2020'),
(13, 1, '2022-2024'),
(17, 1, '2024-2026'),
(29, 1, '2026-2028'),
(30, 2, '2016-2018'),
(30, 2, '2020-2022'),
(32, 2, '2018-2020'),
(32, 2, '2022-2024'),
(36, 2, '2024-2026'),
(40, 2, '2026-2028'),
(57, 1, '1990-1992'),
(57, 1, '2006-2008'),
(58, 2, '1990-1992'),
(58, 2, '2006-2008'),
(60, 1, '1992-1994'),
(60, 1, '2008-2010'),
(61, 2, '1992-1994'),
(61, 2, '2008-2010'),
(62, 1, '1994-1996'),
(62, 1, '2010-2012'),
(63, 2, '1994-1996'),
(63, 2, '2010-2012'),
(64, 1, '1996-1998'),
(64, 1, '2012-2014'),
(65, 2, '1996-1998'),
(65, 2, '2012-2014'),
(66, 1, '1998-2000'),
(66, 1, '2014-2016'),
(67, 2, '1998-2000'),
(67, 2, '2014-2016'),
(68, 1, '2000-2002'),
(69, 2, '2000-2002'),
(70, 1, '2002-2004'),
(71, 2, '2002-2004'),
(72, 1, '2004-2006'),
(73, 2, '2004-2006');

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
(2, 'DOC-2002', 'M.Sc.'),
(3, 'DOC-2003', 'Lic.'),
(7, '1015648', 'Msc.'),
(8, '1015649', 'Dr.'),
(9, '1015650', 'Lic.'),
(10, '1015651', 'Msc.'),
(11, '1015652', 'Lic.'),
(12, '1015653', 'Msc.'),
(13, '1015654', 'Dr.'),
(14, '1015655', 'Lic.'),
(15, '1015656', 'Msc.'),
(16, '1015657', 'Lic.'),
(17, '1015658', 'Msc.'),
(18, '1015659', 'Dr.'),
(19, '1015660', 'Lic.'),
(20, '1015661', 'Msc.'),
(21, '1015662', 'Lic.'),
(22, '1015663', 'Msc.'),
(23, '1015664', 'Dr.'),
(24, '1015665', 'Lic.'),
(25, '1015666', 'Msc.'),
(26, '1015667', 'Lic.'),
(27, '1015668', 'Msc.'),
(28, '1015669', 'Dr.'),
(29, '1015670', 'Msc.'),
(30, '1015671', 'Lic.'),
(31, '1015672', 'Msc.'),
(32, '1015673', 'Dr.'),
(33, '1015674', 'Lic.'),
(34, '1015675', 'Msc.'),
(35, '1015676', 'Lic.'),
(36, '1015677', 'Msc.'),
(37, '1015678', 'Dr.'),
(38, '1015679', 'Lic.'),
(39, '1015680', 'Msc.'),
(40, '1015681', 'Lic.'),
(41, '1015682', 'Msc.'),
(42, '1015683', 'Dr.'),
(43, '1015684', 'Lic.'),
(44, '1015685', 'Msc.'),
(45, '1015686', 'Lic.'),
(46, '1015687', 'Msc.'),
(47, '1015688', 'Dr.'),
(48, '1015689', 'Lic.'),
(49, '1015690', 'Msc.'),
(50, '1015691', 'Lic.'),
(51, '1015692', 'Msc.'),
(52, '1015693', 'Dr.'),
(53, '1015694', 'Lic.'),
(54, '1015695', 'Msc.'),
(55, '1015696', 'Lic.'),
(56, '1015697', 'Msc.'),
(57, '1015698', 'Dr.'),
(58, '1015699', 'Msc.'),
(59, '1015700', 'Lic.'),
(60, '1015701', 'Dr.'),
(61, '1015702', 'Msc.'),
(62, '1015703', 'Lic.'),
(63, '1015704', 'Msc.'),
(64, '1015705', 'Dr.'),
(65, '1015706', 'Lic.'),
(66, '1015707', 'Msc.'),
(67, '1015708', 'Dr.'),
(68, '1015709', 'Lic.'),
(69, '1015710', 'Msc.'),
(70, '1015711', 'Dr.'),
(71, '1015712', 'Lic.'),
(72, '1015713', 'Msc.'),
(73, '1015714', 'Dr.'),
(74, '1015715', 'Lic.'),
(75, '1015716', 'Msc.'),
(76, '1015717', 'Dr.');

--
-- Disparadores `docente`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_docente_insert` AFTER INSERT ON `docente` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nuevo docente Reg=', NEW.registro_docente, ' Grado=', NEW.grado_academico), CURDATE(), CURTIME());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_auto_registro_docente` BEFORE INSERT ON `docente` FOR EACH ROW BEGIN
    DECLARE v_max_reg INT;
    
    IF NEW.registro_docente IS NULL OR NEW.registro_docente = '' THEN
        SELECT COALESCE(MAX(CAST(registro_docente AS UNSIGNED)), 1015647) INTO v_max_reg FROM docente;
        SET NEW.registro_docente = v_max_reg + 1;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estudiante`
--

CREATE TABLE `estudiante` (
  `id_persona` int(11) NOT NULL,
  `ru` varchar(20) NOT NULL,
  `id_plan` int(11) NOT NULL,
  `anio_ingreso` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `estudiante`
--

INSERT INTO `estudiante` (`id_persona`, `ru`, `id_plan`, `anio_ingreso`) VALUES
(1, '1005100', 1, 'I/1990'),
(4, '1005000', 1, 'I/1990'),
(77, '1006000', 1, 'I/1990'),
(78, '1006001', 2, 'I/1990'),
(79, '1006002', 3, 'I/1990'),
(80, '1006003', 4, 'I/1990'),
(81, '1006004', 5, 'I/1990'),
(82, '1006005', 6, 'I/1990'),
(83, '1006006', 7, 'I/1990'),
(84, '1006007', 8, 'I/1990'),
(85, '1006008', 9, 'I/1990'),
(86, '1006009', 10, 'I/1990'),
(87, '1006010', 1, 'II/1990'),
(88, '1006011', 2, 'II/1990'),
(89, '1006012', 3, 'II/1990'),
(90, '1006013', 4, 'II/1990'),
(91, '1006014', 5, 'II/1990'),
(92, '1006015', 6, 'II/1990'),
(93, '1006016', 7, 'II/1990'),
(94, '1006017', 8, 'II/1990'),
(95, '1006018', 9, 'II/1990'),
(96, '1006019', 10, 'II/1990'),
(97, '1006020', 1, 'I/1991'),
(98, '1006021', 2, 'I/1991'),
(99, '1006022', 3, 'I/1991'),
(100, '1006023', 4, 'I/1991'),
(101, '1006024', 5, 'I/1991'),
(102, '1006025', 6, 'I/1991'),
(103, '1006026', 7, 'I/1991'),
(104, '1006027', 8, 'I/1991'),
(105, '1006028', 9, 'I/1991'),
(106, '1006029', 10, 'I/1991'),
(107, '1006030', 1, 'II/1991'),
(108, '1006031', 2, 'II/1991'),
(109, '1006032', 3, 'II/1991'),
(110, '1006033', 4, 'II/1991'),
(111, '1006034', 5, 'II/1991'),
(112, '1006035', 6, 'II/1991'),
(113, '1006036', 7, 'II/1991'),
(114, '1006037', 8, 'II/1991'),
(115, '1006038', 9, 'II/1991'),
(116, '1006039', 10, 'II/1991'),
(117, '1006040', 1, 'I/1992'),
(118, '1006041', 1, 'I/1995'),
(119, '1006042', 3, 'I/1992'),
(120, '1006043', 4, 'I/1992'),
(121, '1006044', 5, 'I/1992'),
(122, '1006045', 6, 'I/1992'),
(123, '1006046', 7, 'I/1992'),
(124, '1006047', 8, 'I/1992'),
(125, '1006048', 9, 'I/1992'),
(126, '1006049', 10, 'I/1992'),
(127, '1006050', 1, 'II/1992'),
(128, '1006051', 2, 'II/1992'),
(129, '1006052', 3, 'II/1992'),
(130, '1006053', 4, 'II/1992'),
(131, '1006054', 5, 'II/1992'),
(132, '1006055', 6, 'II/1992'),
(133, '1006056', 7, 'II/1992'),
(134, '1006057', 8, 'II/1992'),
(135, '1006058', 9, 'II/1992'),
(136, '1006059', 10, 'II/1992'),
(137, '1006060', 1, 'I/1993'),
(138, '1006061', 2, 'I/1993'),
(139, '1006062', 3, 'I/1993'),
(140, '1006063', 4, 'I/1993'),
(141, '1006064', 5, 'I/1993'),
(142, '1006065', 6, 'I/1993'),
(143, '1006066', 7, 'I/1993'),
(144, '1006067', 8, 'I/1993'),
(145, '1006068', 9, 'I/1993'),
(146, '1006069', 10, 'I/1993'),
(147, '1006070', 1, 'II/1993'),
(148, '1006071', 2, 'II/1993'),
(149, '1006072', 3, 'II/1993'),
(150, '1006073', 4, 'II/1993'),
(151, '1006074', 5, 'II/1993'),
(152, '1006075', 6, 'II/1993'),
(153, '1006076', 7, 'II/1993'),
(154, '1006077', 8, 'II/1993'),
(155, '1006078', 9, 'II/1993'),
(156, '1006079', 10, 'II/1993'),
(157, '1006080', 1, 'I/1994'),
(158, '1006081', 2, 'I/1994'),
(159, '1006082', 3, 'I/1994'),
(160, '1006083', 4, 'I/1994'),
(161, '1006084', 5, 'I/1994'),
(162, '1006085', 6, 'I/1994'),
(163, '1006086', 7, 'I/1994'),
(164, '1006087', 8, 'I/1994'),
(165, '1006088', 9, 'I/1994'),
(166, '1006089', 10, 'I/1994'),
(167, '1006090', 1, 'II/1994'),
(168, '1006091', 2, 'II/1994'),
(169, '1006092', 3, 'II/1994'),
(170, '1006093', 4, 'II/1994'),
(171, '1006094', 5, 'II/1994'),
(172, '1006095', 6, 'II/1994'),
(173, '1006096', 7, 'II/1994'),
(174, '1006097', 8, 'II/1994'),
(175, '1006098', 9, 'II/1994'),
(176, '1006099', 10, 'II/1994'),
(178, '1006100', 1, 'I/1995'),
(179, '1006101', 2, 'I/1995'),
(180, '1006102', 3, 'I/1995'),
(181, '1006103', 4, 'I/1995'),
(182, '1006104', 5, 'I/1995'),
(183, '1006105', 6, 'I/1995'),
(184, '1006106', 7, 'I/1995'),
(185, '1006107', 8, 'I/1995'),
(186, '1006108', 9, 'I/1995'),
(187, '1006109', 10, 'I/1995'),
(188, '1006110', 1, 'II/1995'),
(189, '1006111', 2, 'II/1995'),
(190, '1006112', 3, 'II/1995'),
(191, '1006113', 4, 'II/1995'),
(192, '1006114', 5, 'II/1995'),
(193, '1006115', 6, 'II/1995'),
(194, '1006116', 7, 'II/1995'),
(195, '1006117', 8, 'II/1995'),
(196, '1006118', 9, 'II/1995'),
(197, '1006119', 10, 'II/1995'),
(198, '1006120', 1, 'I/1996'),
(199, '1006121', 2, 'I/1996'),
(200, '1006122', 3, 'I/1996'),
(201, '1006123', 4, 'I/1996'),
(202, '1006124', 5, 'I/1996'),
(203, '1006125', 6, 'I/1996'),
(204, '1006126', 7, 'I/1996'),
(205, '1006127', 8, 'I/1996'),
(206, '1006128', 9, 'I/1996'),
(207, '1006129', 10, 'I/1996'),
(208, '1006130', 1, 'II/1996'),
(209, '1006131', 2, 'II/1996'),
(210, '1006132', 3, 'II/1996'),
(211, '1006133', 4, 'II/1996'),
(212, '1006134', 5, 'II/1996'),
(213, '1006135', 6, 'II/1996'),
(214, '1006136', 7, 'II/1996'),
(215, '1006137', 8, 'II/1996'),
(216, '1006138', 9, 'II/1996'),
(217, '1006139', 10, 'II/1996'),
(218, '1006140', 1, 'I/1997'),
(219, '1006141', 2, 'I/1997'),
(220, '1006142', 3, 'I/1997'),
(221, '1006143', 4, 'I/1997'),
(222, '1006144', 5, 'I/1997'),
(223, '1006145', 6, 'I/1997'),
(224, '1006146', 7, 'I/1997'),
(225, '1006147', 8, 'I/1997'),
(226, '1006148', 9, 'I/1997'),
(227, '1006149', 10, 'I/1997'),
(228, '1006150', 1, 'II/1997'),
(229, '1006151', 2, 'II/1997'),
(230, '1006152', 3, 'II/1997'),
(231, '1006153', 4, 'II/1997'),
(232, '1006154', 5, 'II/1997'),
(233, '1006155', 6, 'II/1997'),
(234, '1006156', 7, 'II/1997'),
(235, '1006157', 8, 'II/1997'),
(236, '1006158', 9, 'II/1997'),
(237, '1006159', 10, 'II/1997'),
(238, '1006160', 1, 'II/1997'),
(239, '1006161', 2, 'II/1997'),
(240, '1006162', 3, 'II/1997'),
(241, '1006163', 4, 'II/1997'),
(242, '1006164', 5, 'II/1997'),
(243, '1006165', 6, 'II/1997'),
(244, '1006166', 7, 'II/1997'),
(245, '1006167', 8, 'II/1997'),
(246, '1006168', 9, 'II/1997'),
(247, '1006169', 10, 'II/1997'),
(248, '1006170', 1, 'I/1998'),
(249, '1006171', 2, 'I/1998'),
(250, '1006172', 3, 'I/1998'),
(251, '1006173', 4, 'I/1998'),
(252, '1006174', 5, 'I/1998'),
(253, '1006175', 6, 'I/1998'),
(254, '1006176', 7, 'I/1998'),
(255, '1006177', 8, 'I/1998'),
(256, '1006178', 9, 'I/1998'),
(257, '1006179', 10, 'I/1998'),
(258, '1006180', 1, 'II/1998'),
(259, '1006181', 2, 'II/1998'),
(260, '1006182', 3, 'II/1998'),
(261, '1006183', 4, 'II/1998'),
(262, '1006184', 5, 'II/1998'),
(263, '1006185', 6, 'II/1998'),
(264, '1006186', 7, 'II/1998'),
(265, '1006187', 8, 'II/1998'),
(266, '1006188', 9, 'II/1998'),
(267, '1006189', 10, 'II/1998'),
(268, '1006190', 1, 'I/1999'),
(269, '1006191', 2, 'I/1999'),
(270, '1006192', 3, 'I/1999'),
(271, '1006193', 4, 'I/1999'),
(272, '1006194', 5, 'I/1999'),
(273, '1006195', 6, 'I/1999'),
(274, '1006196', 7, 'I/1999'),
(275, '1006197', 8, 'I/1999'),
(276, '1006198', 9, 'I/1999'),
(277, '1006199', 10, 'I/1999'),
(278, '1006200', 1, 'II/1999'),
(279, '1006201', 2, 'II/1999'),
(280, '1006202', 3, 'II/1999'),
(281, '1006203', 4, 'II/1999'),
(282, '1006204', 5, 'II/1999'),
(283, '1006205', 6, 'II/1999'),
(284, '1006206', 7, 'II/1999'),
(285, '1006207', 8, 'II/1999'),
(286, '1006208', 9, 'II/1999'),
(287, '1006209', 10, 'II/1999'),
(288, '1006210', 1, 'I/2000'),
(289, '1006211', 2, 'I/2000'),
(290, '1006212', 3, 'I/2000'),
(291, '1006213', 4, 'I/2000'),
(292, '1006214', 5, 'I/2000'),
(293, '1006215', 6, 'I/2000'),
(294, '1006216', 7, 'I/2000'),
(295, '1006217', 8, 'I/2000'),
(296, '1006218', 9, 'I/2000'),
(297, '1006219', 10, 'I/2000'),
(298, '1006220', 1, 'II/2000'),
(299, '1006221', 2, 'II/2000'),
(300, '1006222', 3, 'II/2000'),
(301, '1006223', 4, 'II/2000'),
(302, '1006224', 5, 'II/2000'),
(303, '1006225', 6, 'II/2000'),
(304, '1006226', 7, 'II/2000'),
(305, '1006227', 8, 'II/2000'),
(306, '1006228', 9, 'II/2000'),
(307, '1006229', 10, 'II/2000'),
(308, '1006230', 1, 'I/2001'),
(309, '1006231', 2, 'I/2001'),
(310, '1006232', 3, 'I/2001'),
(311, '1006233', 4, 'I/2001'),
(312, '1006234', 5, 'I/2001'),
(313, '1006235', 6, 'I/2001'),
(314, '1006236', 7, 'I/2001'),
(315, '1006237', 8, 'I/2001'),
(316, '1006238', 9, 'I/2001'),
(317, '1006239', 10, 'I/2001'),
(318, '1006240', 1, 'II/2001'),
(319, '1006241', 2, 'II/2001'),
(320, '1006242', 3, 'II/2001'),
(321, '1006243', 4, 'II/2001'),
(322, '1006244', 5, 'II/2001'),
(323, '1006245', 6, 'II/2001'),
(324, '1006246', 7, 'II/2001'),
(325, '1006247', 8, 'II/2001'),
(326, '1006248', 9, 'II/2001'),
(327, '1006249', 10, 'II/2001'),
(328, '1006250', 1, 'I/2024'),
(329, '1006251', 2, 'I/2024'),
(330, '1006252', 3, 'I/2024'),
(331, '1006253', 4, 'I/2024'),
(332, '1006254', 5, 'I/2024'),
(333, '1006255', 6, 'I/2024'),
(334, '1006256', 7, 'I/2024'),
(335, '1006257', 8, 'I/2024'),
(336, '1006258', 9, 'I/2024'),
(337, '1006259', 10, 'I/2024'),
(338, '1006260', 1, 'II/2024'),
(339, '1006261', 2, 'II/2024'),
(340, '1006262', 3, 'II/2024'),
(341, '1006263', 4, 'II/2024'),
(342, '1006264', 5, 'II/2024'),
(343, '1006265', 6, 'II/2024'),
(344, '1006266', 7, 'II/2024'),
(345, '1006267', 8, 'II/2024'),
(346, '1006268', 9, 'II/2024'),
(347, '1006269', 10, 'II/2024'),
(348, '1006270', 1, 'I/2025'),
(349, '1006271', 2, 'I/2025'),
(350, '1006272', 3, 'I/2025'),
(351, '1006273', 4, 'I/2025'),
(352, '1006274', 5, 'I/2025'),
(353, '1006275', 6, 'I/2025'),
(354, '1006276', 7, 'I/2025'),
(355, '1006277', 8, 'I/2025'),
(356, '1006278', 9, 'I/2025'),
(357, '1006279', 10, 'I/2025'),
(358, '1006280', 1, 'II/2025'),
(359, '1006281', 2, 'II/2025'),
(360, '1006282', 3, 'II/2025'),
(361, '1006283', 4, 'II/2025'),
(362, '1006284', 5, 'II/2025'),
(363, '1006285', 6, 'II/2025'),
(364, '1006286', 7, 'II/2025'),
(365, '1006287', 8, 'II/2025'),
(366, '1006288', 9, 'II/2025'),
(367, '1006289', 10, 'II/2025'),
(368, '1006290', 1, 'I/2026'),
(369, '1006291', 2, 'I/2026'),
(370, '1006292', 3, 'I/2026'),
(371, '1006293', 4, 'I/2026'),
(372, '1006294', 5, 'I/2026'),
(373, '1006295', 6, 'I/2026'),
(374, '1006296', 7, 'I/2026'),
(375, '1006297', 8, 'I/2026'),
(376, '1006298', 9, 'I/2026'),
(377, '1006299', 10, 'I/2026'),
(378, '1006300', 1, 'II/2026'),
(379, '1006301', 2, 'II/2026'),
(380, '1006302', 3, 'II/2026'),
(381, '1006303', 4, 'II/2026'),
(382, '1006304', 5, 'II/2026'),
(383, '1006305', 6, 'II/2026'),
(384, '1006306', 7, 'II/2026'),
(385, '1006307', 8, 'II/2026'),
(386, '1006308', 9, 'II/2026'),
(387, '1006309', 10, 'II/2026'),
(388, '1006310', 1, 'I/2026'),
(389, '1006311', 2, 'I/2026'),
(390, '1006312', 3, 'I/2026'),
(391, '1006313', 4, 'I/2026'),
(392, '1006314', 5, 'I/2026'),
(393, '1006315', 6, 'I/2026'),
(394, '1006316', 7, 'I/2026'),
(395, '1006317', 8, 'I/2026'),
(396, '1006318', 9, 'I/2026'),
(397, '1006319', 10, 'I/2026'),
(398, '1006320', 1, 'I/2026'),
(399, '1006321', 2, 'I/2026'),
(400, '1006322', 3, 'I/2026'),
(401, '1006323', 4, 'I/2026'),
(402, '1006324', 5, 'I/2026'),
(403, '1006325', 6, 'I/2026'),
(404, '1006326', 7, 'I/2026'),
(405, '1006327', 8, 'I/2026'),
(406, '1006328', 9, 'I/2026'),
(407, '1006329', 10, 'I/2026'),
(408, '1006330', 1, 'I/2025'),
(409, '1006331', 2, 'I/2025'),
(410, '1006332', 3, 'I/2025'),
(411, '1006333', 4, 'I/2025'),
(412, '1006334', 5, 'I/2025'),
(413, '1006335', 6, 'I/2025'),
(414, '1006336', 7, 'I/2025'),
(415, '1006337', 8, 'I/2025'),
(416, '1006338', 9, 'I/2025'),
(417, '1006339', 10, 'I/2025'),
(418, '1006340', 1, 'I/2026'),
(419, '1006341', 2, 'I/2026'),
(420, '1006342', 3, 'I/2026'),
(421, '1006343', 4, 'I/2026'),
(422, '1006344', 5, 'I/2026'),
(423, '1006345', 6, 'I/2026'),
(424, '1006346', 7, 'I/2026'),
(425, '1006347', 8, 'I/2026'),
(426, '1006348', 9, 'I/2026'),
(427, '1006349', 10, 'I/2026'),
(428, '1006350', 1, 'I/2026'),
(429, '1006351', 2, 'I/2026'),
(430, '1006352', 3, 'I/2026'),
(431, '1006353', 4, 'I/2026'),
(432, '1006354', 5, 'I/2026'),
(433, '1006355', 6, 'I/2026'),
(434, '1006356', 7, 'I/2026'),
(435, '1006357', 8, 'I/2026'),
(436, '1006358', 9, 'I/2026'),
(437, '1006359', 10, 'I/2026'),
(438, '1006360', 1, 'I/2025'),
(439, '1006361', 2, 'I/2025'),
(440, '1006362', 3, 'I/2025'),
(441, '1006363', 4, 'I/2025'),
(442, '1006364', 5, 'I/2025'),
(443, '1006365', 6, 'I/2025'),
(444, '1006366', 7, 'I/2025'),
(445, '1006367', 8, 'I/2025'),
(446, '1006368', 9, 'I/2025'),
(447, '1006369', 10, 'I/2025'),
(448, '1006370', 1, 'I/2026'),
(449, '1006371', 2, 'I/2026'),
(450, '1006372', 3, 'I/2026'),
(451, '1006373', 4, 'I/2026'),
(452, '1006374', 5, 'I/2026'),
(453, '1006375', 6, 'I/2026'),
(454, '1006376', 7, 'I/2026'),
(455, '1006377', 8, 'I/2026'),
(456, '1006378', 9, 'I/2026'),
(457, '1006379', 10, 'I/2026'),
(458, '1006380', 1, 'I/2026'),
(459, '1006381', 2, 'I/2026'),
(460, '1006382', 3, 'I/2026'),
(461, '1006383', 4, 'I/2026'),
(462, '1006384', 5, 'I/2026'),
(463, '1006385', 6, 'I/2026'),
(464, '1006386', 7, 'I/2026'),
(465, '1006387', 8, 'I/2026'),
(466, '1006388', 9, 'I/2026'),
(467, '1006389', 10, 'I/2026'),
(468, '1006390', 1, 'I/2026'),
(469, '1006391', 2, 'I/2026'),
(470, '1006392', 3, 'I/2026'),
(471, '1006393', 4, 'I/2026'),
(472, '1006394', 5, 'I/2026'),
(473, '1006395', 6, 'I/2026'),
(474, '1006396', 7, 'I/2026'),
(475, '1006397', 8, 'I/2026'),
(476, '1006398', 9, 'I/2026'),
(477, '1006399', 10, 'I/2026'),
(478, '1006400', 1, 'I/2025');

--
-- Disparadores `estudiante`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_estudiante_insert` AFTER INSERT ON `estudiante` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nuevo estudiante RU=', NEW.ru, ' Plan=', NEW.id_plan, ' Ingreso=', NEW.anio_ingreso), CURDATE(), CURTIME());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_auto_ru_estudiante` BEFORE INSERT ON `estudiante` FOR EACH ROW BEGIN
    DECLARE v_max_ru INT;
    
    IF NEW.ru IS NULL OR NEW.ru = '' THEN
        SELECT COALESCE(MAX(CAST(ru AS UNSIGNED)), 1005999) INTO v_max_ru FROM estudiante;
        SET NEW.ru = v_max_ru + 1;
    END IF;
END
$$
DELIMITER ;

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
(1, 'I/2020', 'Cerrada'),
(2, 'Invierno/2020', 'Cerrada'),
(3, 'II/2020', 'Cerrada'),
(4, 'Verano/2021', 'Cerrada'),
(5, 'I/2021', 'Cerrada'),
(6, 'Invierno/2021', 'Cerrada'),
(7, 'II/2021', 'Cerrada'),
(8, 'Verano/2022', 'Cerrada'),
(9, 'I/2022', 'Cerrada'),
(10, 'Invierno/2022', 'Cerrada'),
(11, 'II/2022', 'Cerrada'),
(12, 'Verano/2023', 'Cerrada'),
(13, 'I/2023', 'Cerrada'),
(14, 'Invierno/2023', 'Cerrada'),
(15, 'II/2023', 'Cerrada'),
(16, 'Verano/2024', 'Cerrada'),
(17, 'I/2024', 'Cerrada'),
(18, 'Invierno/2024', 'Cerrada'),
(19, 'II/2024', 'Cerrada'),
(20, 'Verano/2025', 'Cerrada'),
(21, 'I/2025', 'Cerrada'),
(22, 'Invierno/2025', 'Cerrada'),
(23, 'II/2025', 'Cerrada'),
(24, 'Verano/2026', 'Cerrada'),
(25, 'I/2026', 'Cerrada'),
(26, 'Invierno/2026', 'Cerrada');

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
(2, 'Lunes', '10:00:00', '12:00:00'),
(3, 'Lunes', '12:00:00', '14:00:00'),
(4, 'Lunes', '14:00:00', '16:00:00'),
(5, 'Lunes', '16:00:00', '18:00:00'),
(6, 'Lunes', '18:00:00', '20:00:00'),
(7, 'Martes', '08:00:00', '10:00:00'),
(8, 'Martes', '10:00:00', '12:00:00'),
(9, 'Martes', '12:00:00', '14:00:00'),
(10, 'Martes', '14:00:00', '16:00:00'),
(11, 'Martes', '16:00:00', '18:00:00'),
(12, 'Martes', '18:00:00', '20:00:00'),
(13, 'Miércoles', '08:00:00', '10:00:00'),
(14, 'Miércoles', '10:00:00', '12:00:00'),
(15, 'Miércoles', '12:00:00', '14:00:00'),
(16, 'Miércoles', '14:00:00', '16:00:00'),
(17, 'Miércoles', '16:00:00', '18:00:00'),
(18, 'Miércoles', '18:00:00', '20:00:00'),
(19, 'Jueves', '08:00:00', '10:00:00'),
(20, 'Jueves', '10:00:00', '12:00:00'),
(21, 'Jueves', '12:00:00', '14:00:00'),
(22, 'Jueves', '14:00:00', '16:00:00'),
(23, 'Jueves', '16:00:00', '18:00:00'),
(24, 'Jueves', '18:00:00', '20:00:00'),
(25, 'Viernes', '08:00:00', '10:00:00'),
(26, 'Viernes', '10:00:00', '12:00:00'),
(27, 'Viernes', '12:00:00', '14:00:00'),
(28, 'Viernes', '14:00:00', '16:00:00'),
(29, 'Viernes', '16:00:00', '18:00:00'),
(30, 'Viernes', '18:00:00', '20:00:00'),
(31, 'Lunes', '08:00:00', '12:00:00'),
(32, 'Lunes', '12:00:00', '16:00:00'),
(33, 'Lunes', '16:00:00', '20:00:00'),
(34, 'Martes', '08:00:00', '12:00:00'),
(35, 'Martes', '12:00:00', '16:00:00'),
(36, 'Martes', '16:00:00', '20:00:00'),
(37, 'Miércoles', '08:00:00', '12:00:00'),
(38, 'Miércoles', '12:00:00', '16:00:00'),
(39, 'Miércoles', '16:00:00', '20:00:00'),
(40, 'Jueves', '08:00:00', '12:00:00'),
(41, 'Jueves', '12:00:00', '16:00:00'),
(42, 'Jueves', '16:00:00', '20:00:00'),
(43, 'Viernes', '08:00:00', '12:00:00'),
(44, 'Viernes', '12:00:00', '16:00:00'),
(45, 'Viernes', '16:00:00', '20:00:00');

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

--
-- Volcado de datos para la tabla `inscripcion`
--

INSERT INTO `inscripcion` (`id_inscripcion`, `id_estudiante`, `id_gestion`, `fecha_registro`) VALUES
(100, 4, 6, '2026-07-20'),
(101, 1, 6, '2026-07-20'),
(102, 478, 26, '2026-07-26'),
(103, 456, 26, '2026-07-26');

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
(1, 'INF-111', 'Programación I', 40, 'Activo'),
(2, 'INF-112', 'Fundamentos digitales', 40, 'Activo'),
(3, 'INF-113', 'Programación web I', 40, 'Activo'),
(4, 'INF-114', 'Algebra', 40, 'Activo'),
(5, 'INF-115', 'Calculo I', 40, 'Activo'),
(6, 'INF-117', 'Matemática discreta', 40, 'Activo'),
(7, 'INF-121', 'Programación II', 40, 'Activo'),
(8, 'INF-122', 'Programación web II', 40, 'Activo'),
(9, 'INF-123', 'Electrónica general I', 40, 'Activo'),
(10, 'INF-124', 'Estadística I', 40, 'Activo'),
(11, 'INF-125', 'Algebra lineal', 40, 'Activo'),
(12, 'INF-126', 'Cálculo II', 40, 'Activo'),
(13, 'INF-131', 'Programación III', 40, 'Activo'),
(14, 'INF-132', 'Base de datos I', 40, 'Activo'),
(15, 'INF-133', 'Programación web III', 40, 'Activo'),
(16, 'INF-134', 'Estadistica II', 40, 'Activo'),
(17, 'INF-135', 'Sistemas Operativos', 40, 'Activo'),
(18, 'TRA-136', 'Metodologia de la investigación', 40, 'Activo'),
(19, 'INF-241', 'Análisis y diseño de sistemas I', 40, 'Activo'),
(20, 'INF-242', 'Redes I', 40, 'Activo'),
(21, 'INF-243', 'Investigación Operativa I', 40, 'Activo'),
(22, 'INF-251', 'Ingeniería de software I', 40, 'Activo'),
(23, 'TRA-256', 'Legislación informática y ética', 40, 'Activo'),
(24, 'INF-265', 'Seguridad de la Información', 40, 'Activo'),
(25, 'INF-266', 'Taller de Técnico Superior', 40, 'Activo'),
(26, 'TRA-374', 'Práctica profesional', 40, 'Activo'),
(27, 'INF-384', 'Taller de graduación I', 40, 'Activo'),
(28, 'INF-391', 'Taller de graduación II', 40, 'Activo'),
(29, 'INF-116', 'Fisica', 40, 'Activo'),
(30, 'INF-244', 'Introducción a la Robótica', 40, 'Activo'),
(31, 'INF-245', 'Programación de dispositivos móviles I', 40, 'Activo'),
(32, 'INF-246', 'Fundamentos de diseño y animación', 40, 'Activo'),
(33, 'INF-252', 'Base de datos II', 40, 'Activo'),
(34, 'INF-253', 'Análisis y diseño de sistemas II', 40, 'Activo'),
(35, 'INF-254', 'Programación de dispositivos móviles II', 40, 'Activo'),
(36, 'INF-261', 'Ingeniería de Software II', 40, 'Activo'),
(37, 'INF-262', 'Base de Datos III', 40, 'Activo'),
(38, 'INF-263', 'Desarrollo de aplicaciones multimedia', 40, 'Activo'),
(39, 'INF-264', 'Emprendimiento e innovación tecnológica', 40, 'Activo'),
(40, 'INF-371', 'Seguridad de la información', 40, 'Activo'),
(41, 'INF-372', 'Inteligencia Artificial', 40, 'Activo'),
(42, 'INF-373', 'Métodos numéricos I', 40, 'Activo'),
(43, 'INF-381', 'Simulación de sistemas', 40, 'Activo'),
(44, 'INF-382', 'Ingeniería de software III', 40, 'Activo'),
(45, 'COM-244', 'Reconocimiento de patrones', 40, 'Activo'),
(46, 'COM-245', 'Lógica para la Ciencia de la Computación', 40, 'Activo'),
(47, 'INF-247', 'Calculo III', 40, 'Activo'),
(48, 'COM-252', 'Inteligencia artificial', 40, 'Activo'),
(49, 'COM-253', 'Criptografia I', 40, 'Activo'),
(50, 'COM-254', 'Métodos numéricos I', 40, 'Activo'),
(51, 'COM-261', 'Lenguajes Formales y autómatas', 40, 'Activo'),
(52, 'COM-262', 'Compiladores', 40, 'Activo'),
(53, 'COM-263', 'Computación paralela', 40, 'Activo'),
(54, 'COM-371', 'Simulación de Sistemas', 40, 'Activo'),
(55, 'COM-372', 'Arquitectura orientada a servicios', 40, 'Activo'),
(56, 'COM-381', 'Interacción Humano-Computador', 40, 'Activo'),
(57, 'COM-382', 'Web semántica', 40, 'Activo'),
(58, 'IID-135', 'Electrónica general II', 40, 'Activo'),
(59, 'IID-246', 'Electrónica industrial', 40, 'Activo'),
(60, 'IID-247', 'Cálculo III', 40, 'Activo'),
(61, 'IID-251', 'Sistemas de control', 40, 'Activo'),
(62, 'IID-252', 'Microcontroladores', 40, 'Activo'),
(63, 'IID-253', 'Aplicaciones informáticas industriales', 40, 'Activo'),
(64, 'IID-254', 'Controladores lógico programables', 40, 'Activo'),
(65, 'IID-261', 'Simulación de sistemas', 40, 'Activo'),
(66, 'IID-262', 'Robótica industrial', 40, 'Activo'),
(67, 'IID-263', 'Internet de las cosas', 40, 'Activo'),
(68, 'IID-264', 'Ingeniería de software I', 40, 'Activo'),
(69, 'IID-265', 'Redes industriales', 40, 'Activo'),
(70, 'IID-371', 'Gestión de proyectos industriales', 40, 'Activo'),
(71, 'IID-372', 'Automatización industrial', 40, 'Activo'),
(72, 'IID-381', 'Automatización de sistemas y procesos', 40, 'Activo'),
(73, 'IID-382', 'Gestión de la seguridad', 40, 'Activo'),
(74, 'SIS-245', 'Sistemas de información', 40, 'Activo'),
(75, 'SIS-246', 'Ingeniería de sistemas', 40, 'Activo'),
(76, 'SEG-252', 'Redes II', 40, 'Activo'),
(77, 'SIS-253', 'Preparación y evaluación de proyectos', 40, 'Activo'),
(78, 'SIS-255', 'Comercio electrónico y marketing digital', 40, 'Activo'),
(79, 'SIS-262', 'Dinámica de sistemas', 40, 'Activo'),
(80, 'SIS-263', 'Sistemas de gestión empresarial', 40, 'Activo'),
(81, 'SIS-371', 'Sistemas distribuidos', 40, 'Activo'),
(82, 'SIS-372', 'Computación en la nube', 40, 'Activo'),
(83, 'SIS-373', 'Organización y métodos', 40, 'Activo'),
(84, 'SIS-382', 'Auditoria de sistemas', 40, 'Activo'),
(85, 'DAT-135', 'Calculo III', 40, 'Activo'),
(86, 'DAT-241', 'Programación distribuida y paralela', 40, 'Activo'),
(87, 'DAT-242', 'Métodos numéricos I', 40, 'Activo'),
(88, 'DAT-245', 'Inteligencia artificial', 40, 'Activo'),
(89, 'DAT-246', 'Modelación estadística', 40, 'Activo'),
(90, 'DAT-251', 'Base de Datos III', 40, 'Activo'),
(91, 'DAT-252', 'Métodos numéricos II', 40, 'Activo'),
(92, 'DAT-253', 'Minería de Datos (Data Mining)', 40, 'Activo'),
(93, 'DAT-254', 'Investigación Operativa II', 40, 'Activo'),
(94, 'DAT-255', 'Aprendizaje automático (Machine Learning)', 40, 'Activo'),
(95, 'DAT-261', 'Procesamiento del Lenguaje Natural', 40, 'Activo'),
(96, 'DAT-262', 'Procesos estocásticos y análisis de series', 40, 'Activo'),
(97, 'DAT-263', 'Análisis de datos', 40, 'Activo'),
(98, 'DAT-264', 'Aprendizaje profundo (Deep Learning)', 40, 'Activo'),
(99, 'DAT-371', 'Inteligencia de negocios (BI)', 40, 'Activo'),
(100, 'DAT-381', 'Macrodatos y analitica de datos (Big Data)', 40, 'Activo'),
(101, 'DAT-382', 'Visualización de datos', 40, 'Activo'),
(102, 'TIC-135', 'Introducción a las redes', 40, 'Activo'),
(103, 'TIC-246', 'Sistemas Operativos', 40, 'Activo'),
(104, 'TIC-247', 'Laboratorio de redes', 40, 'Activo'),
(105, 'TIC-251', 'Aplicaciones y servicios multimedia', 40, 'Activo'),
(106, 'TIC-253', 'Dirección de proyectos informáticos', 40, 'Activo'),
(107, 'TIC-254', 'Redes inalámbricas', 40, 'Activo'),
(108, 'TIC-255', 'Aplicaciones y servicios TIC', 40, 'Activo'),
(109, 'TIC-261', 'Centro de datos (Data Center)', 40, 'Activo'),
(110, 'TIC-262', 'Sistemas de gestión de Red', 40, 'Activo'),
(111, 'TIC-263', 'Redes de Comunicación', 40, 'Activo'),
(112, 'TIC-371', 'Ingenieria de software I', 40, 'Activo'),
(113, 'TIC-372', 'Seguridad de Redes I', 40, 'Activo'),
(114, 'TIC-373', 'Redes de comunicación II', 40, 'Activo'),
(115, 'TIC-381', 'Administración de centros de datos y de red', 40, 'Activo'),
(116, 'TIC-382', 'Seguridad de Redes II', 40, 'Activo'),
(117, 'TIC-383', 'Redes de comunicación III', 40, 'Activo'),
(118, 'SEG-244', 'Seguridad de la Información', 40, 'Activo'),
(119, 'SEG-246', 'Criptografia I', 40, 'Activo'),
(120, 'SEG-253', 'Seguridad en Base de datos', 40, 'Activo'),
(121, 'SEG-254', 'Criptografia II', 40, 'Activo'),
(122, 'SEG-261', 'Hacking ético I', 40, 'Activo'),
(123, 'SEG-262', 'Seguridad de Redes I', 40, 'Activo'),
(124, 'SEG-263', 'Software malicioso', 40, 'Activo'),
(125, 'SEG-264', 'Redes inalámbricas', 40, 'Activo'),
(126, 'SEG-371', 'Gestión de incidentes y continuidad', 40, 'Activo'),
(127, 'SEG-372', 'Seguridad de Redes II', 40, 'Activo'),
(128, 'SEG-373', 'Informática forense', 40, 'Activo'),
(129, 'SEG-381', 'Gestión de Riesgos en Seguridad', 40, 'Activo'),
(130, 'SEG-383', 'Gestión de activos de información', 40, 'Activo'),
(131, 'COMU-111', 'Teoría de la Comunicación I', 40, 'Activo'),
(132, 'COMU-112', 'Taller de Redacción I', 40, 'Activo'),
(133, 'COMU-113', 'Fotografía Básica', 40, 'Activo'),
(134, 'COMU-114', 'Historia de los Medios', 40, 'Activo'),
(135, 'COMU-115', 'Sociología', 40, 'Activo'),
(136, 'COMU-116', 'Lenguaje y Gramática', 40, 'Activo'),
(137, 'COMU-121', 'Teoría de la Comunicación II', 40, 'Activo'),
(138, 'COMU-122', 'Taller de Redacción II', 40, 'Activo'),
(139, 'COMU-123', 'Lenguaje Audiovisual', 40, 'Activo'),
(140, 'COMU-124', 'Semiótica', 40, 'Activo'),
(141, 'COMU-125', 'Antropología', 40, 'Activo'),
(142, 'COMU-126', 'Psicología de la Comunicación', 40, 'Activo'),
(143, 'COMU-131', 'Metodología de la Investigación', 40, 'Activo'),
(144, 'COMU-132', 'Ética Periodística', 40, 'Activo'),
(145, 'COMU-133', 'Taller de Radio', 40, 'Activo'),
(146, 'COMU-134', 'Diseño Gráfico', 40, 'Activo'),
(147, 'COMU-135', 'Relaciones Públicas Básicas', 40, 'Activo'),
(148, 'COMU-136', 'Economía Política', 40, 'Activo'),
(149, 'COMU-241', 'Legislación de Medios', 40, 'Activo'),
(150, 'COMU-242', 'Taller de Televisión', 40, 'Activo'),
(151, 'COMU-243', 'Periodismo Informativo', 40, 'Activo'),
(152, 'COMU-244', 'Estadística para Ciencias Sociales', 40, 'Activo'),
(153, 'COMU-245', 'Publicidad', 40, 'Activo'),
(154, 'COMU-246', 'Opinión Pública', 40, 'Activo'),
(155, 'COMU-251', 'Periodismo Interpretativo', 40, 'Activo'),
(156, 'COMU-252', 'Marketing Básico', 40, 'Activo'),
(157, 'COMU-253', 'Comunicación Organizacional Básica', 40, 'Activo'),
(158, 'COMU-254', 'Proyectos de Comunicación', 40, 'Activo'),
(159, 'COMU-255', 'Comunicación y Cultura', 40, 'Activo'),
(160, 'COMU-256', 'Electiva I', 40, 'Activo'),
(161, 'COMU-384', 'Práctica Profesional', 40, 'Activo'),
(162, 'COMU-385', 'Taller de Graduación I', 40, 'Activo'),
(163, 'COMU-391', 'Taller de Graduación II', 40, 'Activo'),
(164, 'PER-261', 'Periodismo de Datos', 40, 'Activo'),
(165, 'PER-262', 'Gestión de Redes Sociales', 40, 'Activo'),
(166, 'PER-263', 'Edición Digital', 40, 'Activo'),
(167, 'PER-264', 'Periodismo de Investigación', 40, 'Activo'),
(168, 'PER-265', 'Taller Multimedia I', 40, 'Activo'),
(169, 'PER-371', 'Ciberperiodismo', 40, 'Activo'),
(170, 'PER-372', 'Diseño de Interfaces (UI/UX)', 40, 'Activo'),
(171, 'PER-373', 'Narrativas Transmedia', 40, 'Activo'),
(172, 'PER-374', 'Producción de Podcast', 40, 'Activo'),
(173, 'PER-375', 'Taller Multimedia II', 40, 'Activo'),
(174, 'PER-381', 'Periodismo Especializado', 40, 'Activo'),
(175, 'PER-382', 'Analítica Web', 40, 'Activo'),
(176, 'PER-383', 'Emprendimiento en Medios', 40, 'Activo'),
(177, 'AUD-261', 'Guion Cinematográfico', 40, 'Activo'),
(178, 'AUD-262', 'Producción de TV I', 40, 'Activo'),
(179, 'AUD-263', 'Dirección de Fotografía', 40, 'Activo'),
(180, 'AUD-264', 'Sonido y Musicalización', 40, 'Activo'),
(181, 'AUD-265', 'Historia del Cine', 40, 'Activo'),
(182, 'AUD-371', 'Edición y Postproducción', 40, 'Activo'),
(183, 'AUD-372', 'Producción de TV II', 40, 'Activo'),
(184, 'AUD-373', 'Dirección de Cine', 40, 'Activo'),
(185, 'AUD-374', 'Cine Documental', 40, 'Activo'),
(186, 'AUD-375', 'Animación Básica', 40, 'Activo'),
(187, 'AUD-381', 'Realización Cinematográfica', 40, 'Activo'),
(188, 'AUD-382', 'Crítica de Cine', 40, 'Activo'),
(189, 'AUD-383', 'Distribución Audiovisual', 40, 'Activo'),
(190, 'RRPP-261', 'Comunicación Organizacional Avanzada', 40, 'Activo'),
(191, 'RRPP-262', 'Relaciones Públicas Estratégicas', 40, 'Activo'),
(192, 'RRPP-263', 'Identidad Corporativa', 40, 'Activo'),
(193, 'RRPP-264', 'Protocolo y Eventos', 40, 'Activo'),
(194, 'RRPP-265', 'Comunicación Interna', 40, 'Activo'),
(195, 'RRPP-371', 'Gestión de Crisis y Reputación', 40, 'Activo'),
(196, 'RRPP-372', 'Marketing Político', 40, 'Activo'),
(197, 'RRPP-373', 'Responsabilidad Social Empresarial', 40, 'Activo'),
(198, 'RRPP-374', 'Media Training', 40, 'Activo'),
(199, 'RRPP-375', 'Asuntos Públicos (Lobby)', 40, 'Activo'),
(200, 'RRPP-381', 'Auditoría de Comunicación', 40, 'Activo'),
(201, 'RRPP-382', 'Campañas de RRPP', 40, 'Activo'),
(202, 'RRPP-383', 'Negociación y Resolución de Conflictos', 40, 'Activo'),
(203, 'COM-311', 'Sistemas estocásticos', 40, 'Activo'),
(204, 'COM-312', 'Programación Lógica', 40, 'Activo'),
(205, 'COM-313', 'Sistemas expertos', 40, 'Activo'),
(206, 'INF-314', 'Inglés técnico', 40, 'Activo'),
(207, 'INF-315', 'Preparación y evaluación de proyectos', 40, 'Activo'),
(208, 'COM-316', 'Procesamiento del lenguaje natural', 40, 'Activo'),
(209, 'COM-317', 'Geometría computacional', 40, 'Activo'),
(210, 'INF-318', 'Computación en la nube', 40, 'Activo'),
(211, 'INF-333', 'Redes II', 40, 'Activo'),
(212, 'COM-320', 'Especificación formal y verificación', 40, 'Activo'),
(213, 'COM-321', 'Sistemas Inteligentes', 40, 'Activo'),
(214, 'COM-322', 'Base de datos II', 40, 'Activo'),
(215, 'COM-323', 'Computabilidad y complejidad algorítmica', 40, 'Activo'),
(216, 'INF-324', 'Aprendizaje Profundo (Deep learning)', 40, 'Activo'),
(217, 'INF-331', 'Investigación operativa II', 40, 'Activo'),
(218, 'INF-336', 'Visión Artificial y manejo de imágenes', 40, 'Activo'),
(219, 'INF-311', 'Minería de datos (Data Mining)', 40, 'Activo'),
(220, 'INF-312', 'Bioinformática', 40, 'Activo'),
(221, 'INF-313', 'Realidad aumentada y virtual', 40, 'Activo'),
(222, 'INF-316', 'Informática Forense', 40, 'Activo'),
(223, 'INF-317', 'Internet de las cosas', 40, 'Activo'),
(224, 'INF-319', 'Programación a bajo nivel', 40, 'Activo'),
(225, 'INF-320', 'Auditoria de sistemas', 40, 'Activo'),
(226, 'INF-321', 'Cálculo III', 40, 'Activo'),
(227, 'INF-322', 'Macrodatos y analitica de datos (Big Data)', 40, 'Activo'),
(228, 'INF-323', 'Aprendizaje automático (Machine learning)', 40, 'Activo'),
(229, 'INF-325', 'Derecho informático', 40, 'Activo'),
(230, 'INF-326', 'Negociaciones y Toma de Decisiones', 40, 'Activo'),
(231, 'INF-327', 'Inteligencia de negocios (Bussines Intelligence)', 40, 'Activo'),
(232, 'INF-328', 'Visión por computadora', 40, 'Activo'),
(233, 'INF-329', 'Procesamiento digital de imágenes', 40, 'Activo'),
(234, 'INF-330', 'Informática Médica', 40, 'Activo'),
(235, 'INF-332', 'Hacking ético I', 40, 'Activo'),
(236, 'INF-334', 'Dirección de proyectos informáticos', 40, 'Activo'),
(237, 'IID-311', 'Programación de dispositivos móviles II', 40, 'Activo'),
(238, 'IID-312', 'Comunicaciones por satélite', 40, 'Activo'),
(239, 'IID-313', 'Sistemas avanzados de comunicaciones', 40, 'Activo'),
(240, 'IID-316', 'Lenguajes formales y autómatas', 40, 'Activo'),
(241, 'IID-317', 'Instrumentación de procesos para la industria minera', 40, 'Activo'),
(242, 'IID-320', 'Sistemas Hidráulicos y Neumáticos de Potencia', 40, 'Activo'),
(243, 'INF-335', 'Inteligencia artificial', 40, 'Activo'),
(244, 'SIS-313', 'Datawarehouse', 40, 'Activo'),
(245, 'SIS-315', 'Teoría General de sistemas', 40, 'Activo'),
(246, 'SIS-318', 'Ciberseguridad', 40, 'Activo'),
(247, 'SIS-320', 'Sistemas de Información Geográfica', 40, 'Activo'),
(248, 'SIS-324', 'Programación distribuida y paralela', 40, 'Activo'),
(249, 'SIS-325', 'Sistemas contables', 40, 'Activo'),
(250, 'SIS-328', 'Sistemas económicos', 40, 'Activo'),
(251, 'DAT-311', 'Cálculo IV', 40, 'Activo'),
(252, 'DAT-312', 'Modelos Generativos', 40, 'Activo'),
(253, 'DAT-313', 'Comercio electrónico y Marketing Digital', 40, 'Activo'),
(254, 'DAT-318', 'Simulación de sistemas', 40, 'Activo'),
(255, 'DAT-319', 'Programación de dispositivos móviles I', 40, 'Activo'),
(256, 'DAT-321', 'Seguridad de la Información', 40, 'Activo'),
(257, 'INF-337', 'Emprendimiento e innovación tecnológica', 40, 'Activo'),
(258, 'TIC-311', 'Sistemas embebidos', 40, 'Activo'),
(259, 'TIC-312', 'Administración de servidores', 40, 'Activo'),
(260, 'TIC-313', 'Gestión de la seguridad', 40, 'Activo'),
(261, 'TIC-316', 'Comunicaciones por satélite', 40, 'Activo'),
(262, 'TIC-319', 'Sistemas avanzados de comunicaciones (TIC)', 40, 'Activo'),
(263, 'TIC-322', 'Ingeniería de sistemas', 40, 'Activo'),
(264, 'TIC-323', 'Servicios en la nube', 40, 'Activo'),
(265, 'SEG-311', 'Redes de comunicación I', 40, 'Activo'),
(266, 'SEG-312', 'Redes de comunicación II', 40, 'Activo'),
(267, 'SEG-313', 'Arquitectura orientada a servicios', 40, 'Activo'),
(268, 'SEG-316', 'Hacking ético II', 40, 'Activo'),
(269, 'SEG-317', 'Administración de centros de operaciones de red', 40, 'Activo'),
(270, 'SEG-318', 'Gobierno y gestión de seguridad de la información', 40, 'Activo'),
(271, 'PER-E1', 'Taller de Crónica Urbana', 40, 'Activo'),
(272, 'PER-E2', 'Periodismo de Guerra e Internacional', 40, 'Activo'),
(273, 'PER-E3', 'Fotoperiodismo Avanzado', 40, 'Activo'),
(274, 'PER-E4', 'Monetización de Contenidos Digitales', 40, 'Activo'),
(275, 'PER-E5', 'Ética en el uso de IA para el Periodismo', 40, 'Activo'),
(276, 'AUD-E1', 'Actuación para Cine y TV', 40, 'Activo'),
(277, 'AUD-E2', 'Efectos Especiales Visuales (VFX)', 40, 'Activo'),
(278, 'AUD-E3', 'Documental de Naturaleza', 40, 'Activo'),
(279, 'AUD-E4', 'Creación de Series Web', 40, 'Activo'),
(280, 'AUD-E5', 'Marketing Audiovisual', 40, 'Activo'),
(281, 'RRPP-E1', 'Ceremonial y Protocolo Internacional', 40, 'Activo'),
(282, 'RRPP-E2', 'Gestión de Imagen de Funcionarios Públicos', 40, 'Activo'),
(283, 'RRPP-E3', 'Comunicación Interna y Clima Laboral', 40, 'Activo'),
(284, 'RRPP-E4', 'Organización de Mega Eventos', 40, 'Activo'),
(285, 'RRPP-E5', 'Relaciones Comunitarias y RSE', 40, 'Activo'),
(286, 'TSI-251', 'Procesamiento de imagen digital', 40, 'Activo'),
(287, 'TSI-261', 'Aprendizaje automático (Machine Learning)', 40, 'Activo'),
(288, 'TCS-251', 'Calidad de Software', 40, 'Activo'),
(289, 'TCS-261', 'Ingenieria de software II', 40, 'Activo'),
(290, 'TVD-251', 'Electiva I. Programación gráfica', 40, 'Activo'),
(291, 'TVD-261', 'Electiva II. Animación digital 2D y 3D', 40, 'Activo'),
(292, 'TIE-251', 'Electiva I. Administración de Entornos Virtuales de Aprendizaje', 40, 'Activo'),
(293, 'TIE-261', 'Electiva II. Desarrollo de software educativo', 40, 'Activo'),
(294, 'TAW-251', 'Electiva I. Desarrollo web BackEnd', 40, 'Activo'),
(295, 'TAW-261', 'Electiva II. Ingenieria Web', 40, 'Activo'),
(296, 'TAM-251', 'Electiva I. Sistemas embebidos', 40, 'Activo'),
(297, 'TAM-261', 'Electiva II. Desarrollo de aplicaciones móviles multiplataforma', 40, 'Activo'),
(298, 'TAR-251', 'Monitoreo y control de sistemas industriales', 40, 'Activo'),
(299, 'TAR-261', 'Sistemas domóticos', 40, 'Activo'),
(300, 'TIOT-251', 'Sistemas embebidos', 40, 'Activo'),
(301, 'TIOT-261', 'Desarrollo loT', 40, 'Activo'),
(302, 'TRC-251', 'Teoria de la Información y la codificación', 40, 'Activo'),
(303, 'TRC-261', 'Redes industriales', 40, 'Activo'),
(304, 'TAT-251', 'Sistemas móviles, multimedia y difusión', 40, 'Activo'),
(305, 'TAT-261', 'Aplicaciones y servicios distribuidos', 40, 'Activo'),
(306, 'TCP-251', 'Confiabilidad de sistemas tolerantes a fallos', 40, 'Activo'),
(307, 'TCP-261', 'Metodologias de desarrollo seguro de software', 40, 'Activo'),
(308, 'TSS-251', 'Administración de redes y servicios de infraestructura TI', 40, 'Activo'),
(309, 'TSS-261', 'Computación en la nube', 40, 'Activo');

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
-- Volcado de datos para la tabla `nota`
--

INSERT INTO `nota` (`id_nota`, `id_detalle`, `id_criterio`, `nota_obtenida`) VALUES
(1001, 501, 10, 30),
(1002, 501, 11, 31),
(1003, 501, 12, 27),
(1005, 504, 10, 13.5),
(1006, 504, 11, 16),
(1007, 502, 14, 36.8),
(1008, 502, 15, 52.8),
(1011, 511, 10, 15),
(1012, 511, 11, 31),
(1013, 511, 12, 30);

--
-- Disparadores `nota`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_nota_insert` AFTER INSERT ON `nota` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nueva nota ID=', NEW.id_nota, ' puntaje=', NEW.nota_obtenida, ' criterio=', NEW.id_criterio), CURDATE(), CURTIME());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_auditoria_nota_update` AFTER UPDATE ON `nota` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'UPDATE', CONCAT('Nota ID=', NEW.id_nota, ' actualizada de ', OLD.nota_obtenida, ' a ', NEW.nota_obtenida), CURDATE(), CURTIME());
END
$$
DELIMITER ;
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
DELIMITER $$
CREATE TRIGGER `trg_validar_nota_max` BEFORE INSERT ON `nota` FOR EACH ROW BEGIN
    DECLARE v_max_ponderacion FLOAT;
    
    SELECT COALESCE(ponderacion, 100) INTO v_max_ponderacion
    FROM criterio_evaluacion
    WHERE id_criterio = NEW.id_criterio;
    
    IF NEW.nota_obtenida > v_max_ponderacion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La nota obtenida no puede exceder la ponderación máxima asignada al criterio.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_validar_nota_max_update` BEFORE UPDATE ON `nota` FOR EACH ROW BEGIN
    DECLARE v_max_ponderacion FLOAT;
    
    SELECT COALESCE(ponderacion, 100) INTO v_max_ponderacion
    FROM criterio_evaluacion
    WHERE id_criterio = NEW.id_criterio;
    
    IF NEW.nota_obtenida > v_max_ponderacion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La nota obtenida no puede exceder la ponderación máxima asignada al criterio.';
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
  `id_docente` int(11) DEFAULT NULL,
  `id_gestion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `paralelo`
--

INSERT INTO `paralelo` (`id_materia`, `id_paralelo`, `nombre`, `cupo_maximo`, `cupo_actual`, `id_docente`, `id_gestion`) VALUES
(1, 1, 'A', 40, 0, 2, 6),
(1, 1, 'A', 40, 0, NULL, 25),
(1, 1, 'A', 40, 0, 29, 26),
(2, 1, 'A', 40, 0, 2, 6),
(2, 1, 'A', 40, 0, NULL, 25),
(2, 1, 'A', 40, 1, NULL, 26),
(3, 1, 'A', 40, 1, 3, 6),
(3, 1, 'A', 40, 0, NULL, 25),
(3, 1, 'A', 40, 0, NULL, 26),
(4, 1, 'A', 40, 0, NULL, 6),
(4, 1, 'A', 40, 0, NULL, 25),
(4, 1, 'A', 40, 0, NULL, 26),
(5, 1, 'A', 40, 0, NULL, 6),
(5, 1, 'A', 40, 0, NULL, 25),
(5, 1, 'A', 40, 0, NULL, 26),
(6, 1, 'A', 40, 0, NULL, 6),
(6, 1, 'A', 40, 0, NULL, 25),
(6, 1, 'A', 40, 0, NULL, 26),
(7, 1, 'A', 40, 2, 3, 6),
(7, 1, 'A', 40, 0, NULL, 25),
(7, 1, 'A', 40, 0, NULL, 26),
(8, 1, 'A', 40, 0, NULL, 6),
(8, 1, 'A', 40, 0, NULL, 25),
(8, 1, 'A', 40, 0, NULL, 26),
(9, 1, 'A', 40, 0, NULL, 25),
(9, 1, 'A', 40, 0, NULL, 26),
(10, 1, 'A', 40, 0, NULL, 25),
(10, 1, 'A', 40, 0, NULL, 26),
(11, 1, 'A', 40, 0, NULL, 25),
(11, 1, 'A', 40, 0, NULL, 26),
(12, 1, 'A', 40, 0, NULL, 25),
(12, 1, 'A', 40, 0, NULL, 26),
(13, 1, 'A', 40, 0, NULL, 6),
(13, 1, 'A', 40, 0, NULL, 25),
(13, 1, 'A', 40, 0, NULL, 26),
(14, 1, 'A', 40, 0, NULL, 6),
(14, 1, 'A', 40, 0, NULL, 25),
(14, 1, 'A', 40, 0, NULL, 26),
(15, 1, 'A', 40, 0, NULL, 25),
(15, 1, 'A', 40, 0, NULL, 26),
(16, 1, 'A', 40, 0, NULL, 25),
(16, 1, 'A', 40, 0, NULL, 26),
(17, 1, 'A', 40, 0, NULL, 25),
(17, 1, 'A', 40, 0, NULL, 26),
(18, 1, 'A', 40, 0, NULL, 25),
(18, 1, 'A', 40, 0, NULL, 26),
(19, 1, 'A', 40, 0, NULL, 25),
(19, 1, 'A', 40, 0, NULL, 26),
(20, 1, 'A', 40, 0, NULL, 25),
(20, 1, 'A', 40, 0, NULL, 26),
(21, 1, 'A', 40, 0, NULL, 25),
(21, 1, 'A', 40, 0, 29, 26),
(22, 1, 'A', 40, 0, NULL, 25),
(22, 1, 'A', 40, 0, 29, 26),
(23, 1, 'A', 40, 0, NULL, 25),
(23, 1, 'A', 40, 0, NULL, 26),
(24, 1, 'A', 40, 0, NULL, 25),
(24, 1, 'A', 40, 0, NULL, 26),
(25, 1, 'A', 40, 0, NULL, 25),
(25, 1, 'A', 40, 0, NULL, 26),
(26, 1, 'A', 40, 0, NULL, 25),
(26, 1, 'A', 40, 0, NULL, 26),
(27, 1, 'A', 40, 0, NULL, 25),
(27, 1, 'A', 40, 0, NULL, 26),
(28, 1, 'A', 40, 0, NULL, 25),
(28, 1, 'A', 40, 0, NULL, 26),
(29, 1, 'A', 40, 0, NULL, 25),
(29, 1, 'A', 40, 0, NULL, 26),
(30, 1, 'A', 40, 0, NULL, 25),
(30, 1, 'A', 40, 0, NULL, 26),
(31, 1, 'A', 40, 0, NULL, 25),
(31, 1, 'A', 40, 0, NULL, 26),
(32, 1, 'A', 40, 0, NULL, 25),
(32, 1, 'A', 40, 0, NULL, 26),
(33, 1, 'A', 40, 0, NULL, 25),
(33, 1, 'A', 40, 0, NULL, 26),
(34, 1, 'A', 40, 0, NULL, 25),
(34, 1, 'A', 40, 0, NULL, 26),
(35, 1, 'A', 40, 0, NULL, 25),
(35, 1, 'A', 40, 0, NULL, 26),
(36, 1, 'A', 40, 0, NULL, 25),
(36, 1, 'A', 40, 0, NULL, 26),
(37, 1, 'A', 40, 0, NULL, 25),
(37, 1, 'A', 40, 0, NULL, 26),
(38, 1, 'A', 40, 0, NULL, 25),
(38, 1, 'A', 40, 0, NULL, 26),
(39, 1, 'A', 40, 0, NULL, 25),
(39, 1, 'A', 40, 0, NULL, 26),
(40, 1, 'A', 40, 0, NULL, 25),
(40, 1, 'A', 40, 0, NULL, 26),
(41, 1, 'A', 40, 0, NULL, 25),
(41, 1, 'A', 40, 0, NULL, 26),
(42, 1, 'A', 40, 0, NULL, 25),
(42, 1, 'A', 40, 0, NULL, 26),
(43, 1, 'A', 40, 0, NULL, 25),
(43, 1, 'A', 40, 0, NULL, 26),
(44, 1, 'A', 40, 0, NULL, 25),
(44, 1, 'A', 40, 0, NULL, 26),
(45, 1, 'A', 40, 0, NULL, 25),
(45, 1, 'A', 40, 0, NULL, 26),
(46, 1, 'A', 40, 0, NULL, 25),
(46, 1, 'A', 40, 0, NULL, 26),
(47, 1, 'A', 40, 0, NULL, 25),
(47, 1, 'A', 40, 0, NULL, 26),
(48, 1, 'A', 40, 0, NULL, 25),
(48, 1, 'A', 40, 0, NULL, 26),
(49, 1, 'A', 40, 0, NULL, 25),
(49, 1, 'A', 40, 0, NULL, 26),
(50, 1, 'A', 40, 0, NULL, 25),
(50, 1, 'A', 40, 0, NULL, 26),
(51, 1, 'A', 40, 0, NULL, 25),
(51, 1, 'A', 40, 0, NULL, 26),
(52, 1, 'A', 40, 0, NULL, 25),
(52, 1, 'A', 40, 0, NULL, 26),
(53, 1, 'A', 40, 0, NULL, 25),
(53, 1, 'A', 40, 0, NULL, 26),
(54, 1, 'A', 40, 0, NULL, 25),
(54, 1, 'A', 40, 0, NULL, 26),
(55, 1, 'A', 40, 0, NULL, 25),
(55, 1, 'A', 40, 0, NULL, 26),
(56, 1, 'A', 40, 0, NULL, 25),
(56, 1, 'A', 40, 0, NULL, 26),
(57, 1, 'A', 40, 0, NULL, 25),
(57, 1, 'A', 40, 0, NULL, 26),
(58, 1, 'A', 40, 0, NULL, 25),
(58, 1, 'A', 40, 0, NULL, 26),
(59, 1, 'A', 40, 0, NULL, 25),
(59, 1, 'A', 40, 0, NULL, 26),
(60, 1, 'A', 40, 0, NULL, 25),
(60, 1, 'A', 40, 0, NULL, 26),
(61, 1, 'A', 40, 0, NULL, 25),
(61, 1, 'A', 40, 0, NULL, 26),
(62, 1, 'A', 40, 0, NULL, 25),
(62, 1, 'A', 40, 0, NULL, 26),
(63, 1, 'A', 40, 0, NULL, 25),
(63, 1, 'A', 40, 0, NULL, 26),
(64, 1, 'A', 40, 0, NULL, 25),
(64, 1, 'A', 40, 0, NULL, 26),
(65, 1, 'A', 40, 0, NULL, 25),
(65, 1, 'A', 40, 0, NULL, 26),
(66, 1, 'A', 40, 0, NULL, 25),
(66, 1, 'A', 40, 0, NULL, 26),
(67, 1, 'A', 40, 0, NULL, 25),
(67, 1, 'A', 40, 0, NULL, 26),
(68, 1, 'A', 40, 0, NULL, 25),
(68, 1, 'A', 40, 0, NULL, 26),
(69, 1, 'A', 40, 0, NULL, 25),
(69, 1, 'A', 40, 0, NULL, 26),
(70, 1, 'A', 40, 0, NULL, 25),
(70, 1, 'A', 40, 0, NULL, 26),
(71, 1, 'A', 40, 0, NULL, 25),
(71, 1, 'A', 40, 0, NULL, 26),
(72, 1, 'A', 40, 0, NULL, 25),
(72, 1, 'A', 40, 0, NULL, 26),
(73, 1, 'A', 40, 0, NULL, 25),
(73, 1, 'A', 40, 0, NULL, 26),
(74, 1, 'A', 40, 0, NULL, 25),
(74, 1, 'A', 40, 0, NULL, 26),
(75, 1, 'A', 40, 0, NULL, 25),
(75, 1, 'A', 40, 0, NULL, 26),
(76, 1, 'A', 40, 0, NULL, 25),
(76, 1, 'A', 40, 0, NULL, 26),
(77, 1, 'A', 40, 0, NULL, 25),
(77, 1, 'A', 40, 0, NULL, 26),
(78, 1, 'A', 40, 0, NULL, 25),
(78, 1, 'A', 40, 0, NULL, 26),
(79, 1, 'A', 40, 0, NULL, 25),
(79, 1, 'A', 40, 0, NULL, 26),
(80, 1, 'A', 40, 0, NULL, 25),
(80, 1, 'A', 40, 0, NULL, 26),
(81, 1, 'A', 40, 0, NULL, 25),
(81, 1, 'A', 40, 0, NULL, 26),
(82, 1, 'A', 40, 0, NULL, 25),
(82, 1, 'A', 40, 0, NULL, 26),
(83, 1, 'A', 40, 0, NULL, 25),
(83, 1, 'A', 40, 0, NULL, 26),
(84, 1, 'A', 40, 0, NULL, 25),
(84, 1, 'A', 40, 0, NULL, 26),
(85, 1, 'A', 40, 0, NULL, 25),
(85, 1, 'A', 40, 0, NULL, 26),
(86, 1, 'A', 40, 0, NULL, 25),
(86, 1, 'A', 40, 0, NULL, 26),
(87, 1, 'A', 40, 0, NULL, 25),
(87, 1, 'A', 40, 0, NULL, 26),
(88, 1, 'A', 40, 0, NULL, 25),
(88, 1, 'A', 40, 0, NULL, 26),
(89, 1, 'A', 40, 0, NULL, 25),
(89, 1, 'A', 40, 0, NULL, 26),
(90, 1, 'A', 40, 0, NULL, 25),
(90, 1, 'A', 40, 0, NULL, 26),
(91, 1, 'A', 40, 0, NULL, 25),
(91, 1, 'A', 40, 0, NULL, 26),
(92, 1, 'A', 40, 0, NULL, 25),
(92, 1, 'A', 40, 0, NULL, 26),
(93, 1, 'A', 40, 0, NULL, 25),
(93, 1, 'A', 40, 0, NULL, 26),
(94, 1, 'A', 40, 0, NULL, 25),
(94, 1, 'A', 40, 0, NULL, 26),
(95, 1, 'A', 40, 0, NULL, 25),
(95, 1, 'A', 40, 0, NULL, 26),
(96, 1, 'A', 40, 0, NULL, 25),
(96, 1, 'A', 40, 0, NULL, 26),
(97, 1, 'A', 40, 0, NULL, 25),
(97, 1, 'A', 40, 0, NULL, 26),
(98, 1, 'A', 40, 0, NULL, 25),
(98, 1, 'A', 40, 0, NULL, 26),
(99, 1, 'A', 40, 0, NULL, 25),
(99, 1, 'A', 40, 0, NULL, 26),
(100, 1, 'A', 40, 0, NULL, 25),
(100, 1, 'A', 40, 0, NULL, 26),
(101, 1, 'A', 40, 0, NULL, 25),
(101, 1, 'A', 40, 0, NULL, 26),
(102, 1, 'A', 40, 0, NULL, 25),
(102, 1, 'A', 40, 0, NULL, 26),
(103, 1, 'A', 40, 0, NULL, 25),
(103, 1, 'A', 40, 0, NULL, 26),
(104, 1, 'A', 40, 0, NULL, 25),
(104, 1, 'A', 40, 0, NULL, 26),
(105, 1, 'A', 40, 0, NULL, 25),
(105, 1, 'A', 40, 0, NULL, 26),
(106, 1, 'A', 40, 0, NULL, 25),
(106, 1, 'A', 40, 0, NULL, 26),
(107, 1, 'A', 40, 0, NULL, 25),
(107, 1, 'A', 40, 0, NULL, 26),
(108, 1, 'A', 40, 0, NULL, 25),
(108, 1, 'A', 40, 0, NULL, 26),
(109, 1, 'A', 40, 0, NULL, 25),
(109, 1, 'A', 40, 0, NULL, 26),
(110, 1, 'A', 40, 0, NULL, 25),
(110, 1, 'A', 40, 0, NULL, 26),
(111, 1, 'A', 40, 0, NULL, 25),
(111, 1, 'A', 40, 0, NULL, 26),
(112, 1, 'A', 40, 0, NULL, 25),
(112, 1, 'A', 40, 0, NULL, 26),
(113, 1, 'A', 40, 0, NULL, 25),
(113, 1, 'A', 40, 0, NULL, 26),
(114, 1, 'A', 40, 0, NULL, 25),
(114, 1, 'A', 40, 0, NULL, 26),
(115, 1, 'A', 40, 0, NULL, 25),
(115, 1, 'A', 40, 0, NULL, 26),
(116, 1, 'A', 40, 0, NULL, 25),
(116, 1, 'A', 40, 0, NULL, 26),
(117, 1, 'A', 40, 0, NULL, 25),
(117, 1, 'A', 40, 0, NULL, 26),
(118, 1, 'A', 40, 0, NULL, 25),
(118, 1, 'A', 40, 0, NULL, 26),
(119, 1, 'A', 40, 0, NULL, 25),
(119, 1, 'A', 40, 0, NULL, 26),
(120, 1, 'A', 40, 0, NULL, 25),
(120, 1, 'A', 40, 0, NULL, 26),
(121, 1, 'A', 40, 0, NULL, 25),
(121, 1, 'A', 40, 0, NULL, 26),
(122, 1, 'A', 40, 0, NULL, 25),
(122, 1, 'A', 40, 0, NULL, 26),
(123, 1, 'A', 40, 0, NULL, 25),
(123, 1, 'A', 40, 0, NULL, 26),
(124, 1, 'A', 40, 0, NULL, 25),
(124, 1, 'A', 40, 0, NULL, 26),
(125, 1, 'A', 40, 0, NULL, 25),
(125, 1, 'A', 40, 0, NULL, 26),
(126, 1, 'A', 40, 0, NULL, 25),
(126, 1, 'A', 40, 0, NULL, 26),
(127, 1, 'A', 40, 0, NULL, 25),
(127, 1, 'A', 40, 0, NULL, 26),
(128, 1, 'A', 40, 0, NULL, 25),
(128, 1, 'A', 40, 0, NULL, 26),
(129, 1, 'A', 40, 0, NULL, 25),
(129, 1, 'A', 40, 0, NULL, 26),
(130, 1, 'A', 40, 0, NULL, 25),
(130, 1, 'A', 40, 0, NULL, 26),
(131, 1, 'A', 40, 0, NULL, 25),
(131, 1, 'A', 40, 0, NULL, 26),
(132, 1, 'A', 40, 0, NULL, 25),
(132, 1, 'A', 40, 0, NULL, 26),
(133, 1, 'A', 40, 0, NULL, 25),
(133, 1, 'A', 40, 0, NULL, 26),
(134, 1, 'A', 40, 0, NULL, 25),
(134, 1, 'A', 40, 0, NULL, 26),
(135, 1, 'A', 40, 0, NULL, 25),
(135, 1, 'A', 40, 0, NULL, 26),
(136, 1, 'A', 40, 0, NULL, 25),
(136, 1, 'A', 40, 0, NULL, 26),
(137, 1, 'A', 40, 0, NULL, 25),
(137, 1, 'A', 40, 0, NULL, 26),
(138, 1, 'A', 40, 0, NULL, 25),
(138, 1, 'A', 40, 0, NULL, 26),
(139, 1, 'A', 40, 0, NULL, 25),
(139, 1, 'A', 40, 0, NULL, 26),
(140, 1, 'A', 40, 0, NULL, 25),
(140, 1, 'A', 40, 0, NULL, 26),
(141, 1, 'A', 40, 0, NULL, 25),
(141, 1, 'A', 40, 0, NULL, 26),
(142, 1, 'A', 40, 0, NULL, 25),
(142, 1, 'A', 40, 0, NULL, 26),
(143, 1, 'A', 40, 0, NULL, 25),
(143, 1, 'A', 40, 0, NULL, 26),
(144, 1, 'A', 40, 0, NULL, 25),
(144, 1, 'A', 40, 0, NULL, 26),
(145, 1, 'A', 40, 0, NULL, 25),
(145, 1, 'A', 40, 0, NULL, 26),
(146, 1, 'A', 40, 0, NULL, 25),
(146, 1, 'A', 40, 0, NULL, 26),
(147, 1, 'A', 40, 0, NULL, 25),
(147, 1, 'A', 40, 0, NULL, 26),
(148, 1, 'A', 40, 0, NULL, 25),
(148, 1, 'A', 40, 0, NULL, 26),
(149, 1, 'A', 40, 0, NULL, 25),
(149, 1, 'A', 40, 0, NULL, 26),
(150, 1, 'A', 40, 0, NULL, 25),
(150, 1, 'A', 40, 0, NULL, 26),
(151, 1, 'A', 40, 0, NULL, 25),
(151, 1, 'A', 40, 0, NULL, 26),
(152, 1, 'A', 40, 0, NULL, 25),
(152, 1, 'A', 40, 0, NULL, 26),
(153, 1, 'A', 40, 0, NULL, 25),
(153, 1, 'A', 40, 0, NULL, 26),
(154, 1, 'A', 40, 0, NULL, 25),
(154, 1, 'A', 40, 0, NULL, 26),
(155, 1, 'A', 40, 0, NULL, 25),
(155, 1, 'A', 40, 0, NULL, 26),
(156, 1, 'A', 40, 0, NULL, 25),
(156, 1, 'A', 40, 0, NULL, 26),
(157, 1, 'A', 40, 0, NULL, 25),
(157, 1, 'A', 40, 0, NULL, 26),
(158, 1, 'A', 40, 0, NULL, 25),
(158, 1, 'A', 40, 0, NULL, 26),
(159, 1, 'A', 40, 0, NULL, 25),
(159, 1, 'A', 40, 0, NULL, 26),
(160, 1, 'A', 40, 0, NULL, 25),
(160, 1, 'A', 40, 0, NULL, 26),
(161, 1, 'A', 40, 0, NULL, 25),
(161, 1, 'A', 40, 0, NULL, 26),
(162, 1, 'A', 40, 0, NULL, 25),
(162, 1, 'A', 40, 0, NULL, 26),
(163, 1, 'A', 40, 0, NULL, 25),
(163, 1, 'A', 40, 0, NULL, 26),
(164, 1, 'A', 40, 0, NULL, 25),
(164, 1, 'A', 40, 0, NULL, 26),
(165, 1, 'A', 40, 0, NULL, 25),
(165, 1, 'A', 40, 0, NULL, 26),
(166, 1, 'A', 40, 0, NULL, 25),
(166, 1, 'A', 40, 0, NULL, 26),
(167, 1, 'A', 40, 0, NULL, 25),
(167, 1, 'A', 40, 0, NULL, 26),
(168, 1, 'A', 40, 0, NULL, 25),
(168, 1, 'A', 40, 0, NULL, 26),
(169, 1, 'A', 40, 0, NULL, 25),
(169, 1, 'A', 40, 0, NULL, 26),
(170, 1, 'A', 40, 0, NULL, 25),
(170, 1, 'A', 40, 0, NULL, 26),
(171, 1, 'A', 40, 0, NULL, 25),
(171, 1, 'A', 40, 0, NULL, 26),
(172, 1, 'A', 40, 0, NULL, 25),
(172, 1, 'A', 40, 0, NULL, 26),
(173, 1, 'A', 40, 0, NULL, 25),
(173, 1, 'A', 40, 0, NULL, 26),
(174, 1, 'A', 40, 0, NULL, 25),
(174, 1, 'A', 40, 0, NULL, 26),
(175, 1, 'A', 40, 0, NULL, 25),
(175, 1, 'A', 40, 0, NULL, 26),
(176, 1, 'A', 40, 0, NULL, 25),
(176, 1, 'A', 40, 0, NULL, 26),
(177, 1, 'A', 40, 0, NULL, 25),
(177, 1, 'A', 40, 0, NULL, 26),
(178, 1, 'A', 40, 0, NULL, 25),
(178, 1, 'A', 40, 0, NULL, 26),
(179, 1, 'A', 40, 0, NULL, 25),
(179, 1, 'A', 40, 0, NULL, 26),
(180, 1, 'A', 40, 0, NULL, 25),
(180, 1, 'A', 40, 0, NULL, 26),
(181, 1, 'A', 40, 0, NULL, 25),
(181, 1, 'A', 40, 0, NULL, 26),
(182, 1, 'A', 40, 0, NULL, 25),
(182, 1, 'A', 40, 0, NULL, 26),
(183, 1, 'A', 40, 0, NULL, 25),
(183, 1, 'A', 40, 0, NULL, 26),
(184, 1, 'A', 40, 0, NULL, 25),
(184, 1, 'A', 40, 0, NULL, 26),
(185, 1, 'A', 40, 0, NULL, 25),
(185, 1, 'A', 40, 0, NULL, 26),
(186, 1, 'A', 40, 0, NULL, 25),
(186, 1, 'A', 40, 0, NULL, 26),
(187, 1, 'A', 40, 0, NULL, 25),
(187, 1, 'A', 40, 0, NULL, 26),
(188, 1, 'A', 40, 0, NULL, 25),
(188, 1, 'A', 40, 0, NULL, 26),
(189, 1, 'A', 40, 0, NULL, 25),
(189, 1, 'A', 40, 0, NULL, 26),
(190, 1, 'A', 40, 0, NULL, 25),
(190, 1, 'A', 40, 0, NULL, 26),
(191, 1, 'A', 40, 0, NULL, 25),
(191, 1, 'A', 40, 0, NULL, 26),
(192, 1, 'A', 40, 0, NULL, 25),
(192, 1, 'A', 40, 0, NULL, 26),
(193, 1, 'A', 40, 0, NULL, 25),
(193, 1, 'A', 40, 0, NULL, 26),
(194, 1, 'A', 40, 0, NULL, 25),
(194, 1, 'A', 40, 0, NULL, 26),
(195, 1, 'A', 40, 0, NULL, 25),
(195, 1, 'A', 40, 0, NULL, 26),
(196, 1, 'A', 40, 0, NULL, 25),
(196, 1, 'A', 40, 0, NULL, 26),
(197, 1, 'A', 40, 0, NULL, 25),
(197, 1, 'A', 40, 0, NULL, 26),
(198, 1, 'A', 40, 0, NULL, 25),
(198, 1, 'A', 40, 0, NULL, 26),
(199, 1, 'A', 40, 0, NULL, 25),
(199, 1, 'A', 40, 0, NULL, 26),
(200, 1, 'A', 40, 0, NULL, 25),
(200, 1, 'A', 40, 0, NULL, 26),
(201, 1, 'A', 40, 0, NULL, 25),
(201, 1, 'A', 40, 0, NULL, 26),
(202, 1, 'A', 40, 0, NULL, 25),
(202, 1, 'A', 40, 0, NULL, 26),
(203, 1, 'A', 40, 0, NULL, 25),
(203, 1, 'A', 40, 0, NULL, 26),
(204, 1, 'A', 40, 0, NULL, 25),
(204, 1, 'A', 40, 0, NULL, 26),
(205, 1, 'A', 40, 0, NULL, 25),
(205, 1, 'A', 40, 0, NULL, 26),
(206, 1, 'A', 40, 0, NULL, 25),
(206, 1, 'A', 40, 0, NULL, 26),
(207, 1, 'A', 40, 0, NULL, 25),
(207, 1, 'A', 40, 0, NULL, 26),
(208, 1, 'A', 40, 0, NULL, 25),
(208, 1, 'A', 40, 0, NULL, 26),
(209, 1, 'A', 40, 0, NULL, 25),
(209, 1, 'A', 40, 0, NULL, 26),
(210, 1, 'A', 40, 0, NULL, 25),
(210, 1, 'A', 40, 0, NULL, 26),
(211, 1, 'A', 40, 0, NULL, 25),
(211, 1, 'A', 40, 0, NULL, 26),
(212, 1, 'A', 40, 0, NULL, 25),
(212, 1, 'A', 40, 0, NULL, 26),
(213, 1, 'A', 40, 0, NULL, 25),
(213, 1, 'A', 40, 0, NULL, 26),
(214, 1, 'A', 40, 0, NULL, 25),
(214, 1, 'A', 40, 0, NULL, 26),
(215, 1, 'A', 40, 0, NULL, 25),
(215, 1, 'A', 40, 0, NULL, 26),
(216, 1, 'A', 40, 0, NULL, 25),
(216, 1, 'A', 40, 0, NULL, 26),
(217, 1, 'A', 40, 0, NULL, 25),
(217, 1, 'A', 40, 0, NULL, 26),
(218, 1, 'A', 40, 0, NULL, 25),
(218, 1, 'A', 40, 0, NULL, 26),
(219, 1, 'A', 40, 0, NULL, 25),
(219, 1, 'A', 40, 0, NULL, 26),
(220, 1, 'A', 40, 0, NULL, 25),
(220, 1, 'A', 40, 0, NULL, 26),
(221, 1, 'A', 40, 0, NULL, 25),
(221, 1, 'A', 40, 0, NULL, 26),
(222, 1, 'A', 40, 0, NULL, 25),
(222, 1, 'A', 40, 0, NULL, 26),
(223, 1, 'A', 40, 0, NULL, 25),
(223, 1, 'A', 40, 0, NULL, 26),
(224, 1, 'A', 40, 0, NULL, 25),
(224, 1, 'A', 40, 0, NULL, 26),
(225, 1, 'A', 40, 0, NULL, 25),
(225, 1, 'A', 40, 0, NULL, 26),
(226, 1, 'A', 40, 0, NULL, 25),
(226, 1, 'A', 40, 0, NULL, 26),
(227, 1, 'A', 40, 0, NULL, 25),
(227, 1, 'A', 40, 0, NULL, 26),
(228, 1, 'A', 40, 0, NULL, 25),
(228, 1, 'A', 40, 0, NULL, 26),
(229, 1, 'A', 40, 0, NULL, 25),
(229, 1, 'A', 40, 0, NULL, 26),
(230, 1, 'A', 40, 0, NULL, 25),
(230, 1, 'A', 40, 0, NULL, 26),
(231, 1, 'A', 40, 0, NULL, 25),
(231, 1, 'A', 40, 0, NULL, 26),
(232, 1, 'A', 40, 0, NULL, 25),
(232, 1, 'A', 40, 0, NULL, 26),
(233, 1, 'A', 40, 0, NULL, 25),
(233, 1, 'A', 40, 0, NULL, 26),
(234, 1, 'A', 40, 0, NULL, 25),
(234, 1, 'A', 40, 0, NULL, 26),
(235, 1, 'A', 40, 0, NULL, 25),
(235, 1, 'A', 40, 0, NULL, 26),
(236, 1, 'A', 40, 0, NULL, 25),
(236, 1, 'A', 40, 0, NULL, 26),
(237, 1, 'A', 40, 0, NULL, 25),
(237, 1, 'A', 40, 0, NULL, 26),
(238, 1, 'A', 40, 0, NULL, 25),
(238, 1, 'A', 40, 0, NULL, 26),
(239, 1, 'A', 40, 0, NULL, 25),
(239, 1, 'A', 40, 0, NULL, 26),
(240, 1, 'A', 40, 0, NULL, 25),
(240, 1, 'A', 40, 0, NULL, 26),
(241, 1, 'A', 40, 0, NULL, 25),
(241, 1, 'A', 40, 0, NULL, 26),
(242, 1, 'A', 40, 0, NULL, 25),
(242, 1, 'A', 40, 0, NULL, 26),
(243, 1, 'A', 40, 0, NULL, 25),
(243, 1, 'A', 40, 0, NULL, 26),
(244, 1, 'A', 40, 0, NULL, 25),
(244, 1, 'A', 40, 0, NULL, 26),
(245, 1, 'A', 40, 0, NULL, 25),
(245, 1, 'A', 40, 0, NULL, 26),
(246, 1, 'A', 40, 0, NULL, 25),
(246, 1, 'A', 40, 0, NULL, 26),
(247, 1, 'A', 40, 0, NULL, 25),
(247, 1, 'A', 40, 0, NULL, 26),
(248, 1, 'A', 40, 0, NULL, 25),
(248, 1, 'A', 40, 0, NULL, 26),
(249, 1, 'A', 40, 0, NULL, 25),
(249, 1, 'A', 40, 0, NULL, 26),
(250, 1, 'A', 40, 0, NULL, 25),
(250, 1, 'A', 40, 0, NULL, 26),
(251, 1, 'A', 40, 0, NULL, 25),
(251, 1, 'A', 40, 0, NULL, 26),
(252, 1, 'A', 40, 0, NULL, 25),
(252, 1, 'A', 40, 0, NULL, 26),
(253, 1, 'A', 40, 0, NULL, 25),
(253, 1, 'A', 40, 0, NULL, 26),
(254, 1, 'A', 40, 0, NULL, 25),
(254, 1, 'A', 40, 0, NULL, 26),
(255, 1, 'A', 40, 0, NULL, 25),
(255, 1, 'A', 40, 0, NULL, 26),
(256, 1, 'A', 40, 0, NULL, 25),
(256, 1, 'A', 40, 0, NULL, 26),
(257, 1, 'A', 40, 0, NULL, 25),
(257, 1, 'A', 40, 0, NULL, 26),
(258, 1, 'A', 40, 0, NULL, 25),
(258, 1, 'A', 40, 0, NULL, 26),
(259, 1, 'A', 40, 0, NULL, 25),
(259, 1, 'A', 40, 0, NULL, 26),
(260, 1, 'A', 40, 0, NULL, 25),
(260, 1, 'A', 40, 0, NULL, 26),
(261, 1, 'A', 40, 0, NULL, 25),
(261, 1, 'A', 40, 0, NULL, 26),
(262, 1, 'A', 40, 0, NULL, 25),
(262, 1, 'A', 40, 0, NULL, 26),
(263, 1, 'A', 40, 0, NULL, 25),
(263, 1, 'A', 40, 0, NULL, 26),
(264, 1, 'A', 40, 0, NULL, 25),
(264, 1, 'A', 40, 0, NULL, 26),
(265, 1, 'A', 40, 0, NULL, 25),
(265, 1, 'A', 40, 0, NULL, 26),
(266, 1, 'A', 40, 0, NULL, 25),
(266, 1, 'A', 40, 0, NULL, 26),
(267, 1, 'A', 40, 0, NULL, 25),
(267, 1, 'A', 40, 0, NULL, 26),
(268, 1, 'A', 40, 0, NULL, 25),
(268, 1, 'A', 40, 0, NULL, 26),
(269, 1, 'A', 40, 0, NULL, 25),
(269, 1, 'A', 40, 0, NULL, 26),
(270, 1, 'A', 40, 0, NULL, 25),
(270, 1, 'A', 40, 0, NULL, 26),
(271, 1, 'A', 40, 0, NULL, 25),
(271, 1, 'A', 40, 0, NULL, 26),
(272, 1, 'A', 40, 0, NULL, 25),
(272, 1, 'A', 40, 0, NULL, 26),
(273, 1, 'A', 40, 0, NULL, 25),
(273, 1, 'A', 40, 0, NULL, 26),
(274, 1, 'A', 40, 0, NULL, 25),
(274, 1, 'A', 40, 0, NULL, 26),
(275, 1, 'A', 40, 0, NULL, 25),
(275, 1, 'A', 40, 0, NULL, 26),
(276, 1, 'A', 40, 0, NULL, 25),
(276, 1, 'A', 40, 0, NULL, 26),
(277, 1, 'A', 40, 0, NULL, 25),
(277, 1, 'A', 40, 0, NULL, 26),
(278, 1, 'A', 40, 0, NULL, 25),
(278, 1, 'A', 40, 0, NULL, 26),
(279, 1, 'A', 40, 0, NULL, 25),
(279, 1, 'A', 40, 0, NULL, 26),
(280, 1, 'A', 40, 0, NULL, 25),
(280, 1, 'A', 40, 0, NULL, 26),
(281, 1, 'A', 40, 0, NULL, 25),
(281, 1, 'A', 40, 0, NULL, 26),
(282, 1, 'A', 40, 0, NULL, 25),
(282, 1, 'A', 40, 0, NULL, 26),
(283, 1, 'A', 40, 0, NULL, 25),
(283, 1, 'A', 40, 0, NULL, 26),
(284, 1, 'A', 40, 0, NULL, 25),
(284, 1, 'A', 40, 0, NULL, 26),
(285, 1, 'A', 40, 0, NULL, 25),
(285, 1, 'A', 40, 0, NULL, 26),
(286, 1, 'A', 40, 0, NULL, 25),
(286, 1, 'A', 40, 0, NULL, 26),
(287, 1, 'A', 40, 0, NULL, 25),
(287, 1, 'A', 40, 0, NULL, 26),
(288, 1, 'A', 40, 0, NULL, 25),
(288, 1, 'A', 40, 0, NULL, 26),
(289, 1, 'A', 40, 0, NULL, 25),
(289, 1, 'A', 40, 0, NULL, 26),
(290, 1, 'A', 40, 0, NULL, 25),
(290, 1, 'A', 40, 0, NULL, 26),
(291, 1, 'A', 40, 0, NULL, 25),
(291, 1, 'A', 40, 0, NULL, 26),
(292, 1, 'A', 40, 0, NULL, 25),
(292, 1, 'A', 40, 0, NULL, 26),
(293, 1, 'A', 40, 0, NULL, 25),
(293, 1, 'A', 40, 0, NULL, 26),
(294, 1, 'A', 40, 0, NULL, 25),
(294, 1, 'A', 40, 0, NULL, 26),
(295, 1, 'A', 40, 0, NULL, 25),
(295, 1, 'A', 40, 0, NULL, 26),
(296, 1, 'A', 40, 0, NULL, 25),
(296, 1, 'A', 40, 0, NULL, 26),
(297, 1, 'A', 40, 0, NULL, 25),
(297, 1, 'A', 40, 0, NULL, 26),
(298, 1, 'A', 40, 0, NULL, 25),
(298, 1, 'A', 40, 0, NULL, 26),
(299, 1, 'A', 40, 0, NULL, 25),
(299, 1, 'A', 40, 0, NULL, 26),
(300, 1, 'A', 40, 0, NULL, 25),
(300, 1, 'A', 40, 0, NULL, 26),
(301, 1, 'A', 40, 0, NULL, 25),
(301, 1, 'A', 40, 0, NULL, 26),
(302, 1, 'A', 40, 0, NULL, 25),
(302, 1, 'A', 40, 0, NULL, 26),
(303, 1, 'A', 40, 0, NULL, 25),
(303, 1, 'A', 40, 0, NULL, 26),
(304, 1, 'A', 40, 0, NULL, 25),
(304, 1, 'A', 40, 0, NULL, 26),
(305, 1, 'A', 40, 0, NULL, 25),
(305, 1, 'A', 40, 0, NULL, 26),
(306, 1, 'A', 40, 0, NULL, 25),
(306, 1, 'A', 40, 0, NULL, 26),
(307, 1, 'A', 40, 0, NULL, 25),
(307, 1, 'A', 40, 0, NULL, 26),
(308, 1, 'A', 40, 0, NULL, 25),
(308, 1, 'A', 40, 0, NULL, 26),
(309, 1, 'A', 40, 0, NULL, 25),
(309, 1, 'A', 40, 0, NULL, 26);

--
-- Disparadores `paralelo`
--
DELIMITER $$
CREATE TRIGGER `trg_validar_max_paralelos_docente` BEFORE UPDATE ON `paralelo` FOR EACH ROW BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    
    -- Solo validar cuando se asigna un docente (no cuando se quita)
    IF NEW.id_docente IS NOT NULL THEN
        SELECT COUNT(*) INTO v_cantidad
        FROM paralelo
        WHERE id_docente = NEW.id_docente
          AND id_gestion = NEW.id_gestion
          AND NOT (id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo);
        
        IF v_cantidad >= 3 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El docente ya dirige 3 paralelos en esta gestión. No puede tomar más.';
        END IF;
    END IF;
END
$$
DELIMITER ;

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
(1, '4832015LP', 'Carlos', 'Mendoza Quispe', '1985-03-15', 'M', 'cmendoza@fcpn.edu.bo', 'Activo'),
(2, '5978842LP', 'Manuel Ramiro', 'Condori Mamani', '1988-07-22', 'F', 'mcondori@fcpn.edu.bo', 'Activo'),
(3, '6123456LP', 'Francisco', 'Flores Ticona', '1986-11-08', 'M', 'jflores@fcpn.edu.bo', 'Activo'),
(4, '5214789LP', 'Luis Alejandro', 'Arancibia Rojas', '1987-05-30', 'F', 'garancibia@fcpn.edu.bo', 'Activo'),
(5, '6459871LP', 'Roberto', 'Limachi Vargas', '1984-09-14', 'M', 'rlimachi@fcpn.edu.bo', 'Activo'),
(6, '5896321LP', 'Patricia', 'Gutiérrez Choque', '1989-01-25', 'F', 'pgutierrez@fcpn.edu.bo', 'Activo'),
(7, '3451289LP', 'Francisco', 'Mamani Apaza', '1975-04-12', 'M', 'fmamani@fcpn.edu.bo', 'Activo'),
(8, '4521367LP', 'Silvia', 'Huanca Laura', '1978-08-25', 'F', 'shuanca@fcpn.edu.bo', 'Activo'),
(9, '5678901LP', 'Raúl', 'Quispe Alanoca', '1976-11-03', 'M', 'rquispe@fcpn.edu.bo', 'Activo'),
(10, '6789012LP', 'Carmen', 'Ticona Pari', '1980-02-18', 'F', 'cticona@fcpn.edu.bo', 'Activo'),
(11, '7890123LP', 'Alberto', 'Condori Calle', '1974-09-30', 'M', 'acondori@fcpn.edu.bo', 'Activo'),
(12, '8901234LP', 'Lucía', 'Mamani Choque', '1982-06-15', 'F', 'lmamani@fcpn.edu.bo', 'Activo'),
(13, '9012345LP', 'Fernando', 'Vargas Luna', '1973-12-01', 'M', 'fvargas@fcpn.edu.bo', 'Activo'),
(14, '1123456LP', 'Daniela', 'Apaza Cruz', '1984-03-20', 'F', 'dapaza@fcpn.edu.bo', 'Activo'),
(15, '2234567LP', 'Gustavo', 'Laura Pinto', '1977-07-14', 'M', 'glaura@fcpn.edu.bo', 'Activo'),
(16, '3345678LP', 'Rosa', 'Calle Tito', '1981-10-08', 'F', 'rcalle@fcpn.edu.bo', 'Activo'),
(17, '4456789LP', 'Miguel Angel', 'Pari Mamani', '1975-05-22', 'M', 'mpari@fcpn.edu.bo', 'Activo'),
(18, '5567890LP', 'Sonia', 'Flores Condori', '1983-08-11', 'F', 'sflores@fcpn.edu.bo', 'Activo'),
(19, '6678901LP', 'Diego', 'Quispe Huanca', '1976-01-28', 'M', 'dquispe@fcpn.edu.bo', 'Activo'),
(20, '7789012LP', 'Andrea', 'Mendoza Ticona', '1985-04-05', 'F', 'amendozat@fcpn.edu.bo', 'Activo'),
(21, '8890123LP', 'Hugo', 'Tito Quispe', '1972-09-19', 'M', 'htito@fcpn.edu.bo', 'Activo'),
(22, '9901234LP', 'Beatriz', 'Condori Mamani', '1986-12-12', 'F', 'bcondori@fcpn.edu.bo', 'Activo'),
(23, '1012345LP', 'Ricardo', 'Laura Apaza', '1974-06-08', 'M', 'rlaura@fcpn.edu.bo', 'Activo'),
(24, '1213456LP', 'Natalia', 'Mamani Flores', '1982-03-25', 'F', 'nmamani@fcpn.edu.bo', 'Activo'),
(25, '1314567LP', 'Oscar', 'Quispe Ticona', '1979-10-17', 'M', 'oquispe@fcpn.edu.bo', 'Activo'),
(26, '1415678LP', 'Verónica', 'Pari Condori', '1984-07-30', 'F', 'vpari@fcpn.edu.bo', 'Activo'),
(27, '1516789LP', 'Felipe', 'Huanca Laura', '1973-11-22', 'M', 'fhuanca@fcpn.edu.bo', 'Activo'),
(28, '1617890LP', 'Marcela', 'Mamani Ticona', '1981-05-14', 'F', 'mmamanit@fcpn.edu.bo', 'Activo'),
(29, '1718901LP', 'Manuel Ramiro', 'Flores', '1970-08-30', 'M', 'mrflores@fcpn.edu.bo', 'Activo'),
(30, '1819012LP', 'Cecilia', 'Quispe Mamani', '1983-02-28', 'F', 'cquispe@fcpn.edu.bo', 'Activo'),
(31, '1920123LP', 'Javier', 'Condori Apaza', '1977-09-15', 'M', 'jcondori@fcpn.edu.bo', 'Activo'),
(32, '2021234LP', 'Lorena', 'Ticona Flores', '1985-11-10', 'F', 'lticona@fcpn.edu.bo', 'Activo'),
(33, '2122345LP', 'René', 'Mamani Calle', '1972-04-20', 'M', 'rmamani@fcpn.edu.bo', 'Activo'),
(34, '2223456LP', 'Paola', 'Apaza Laura', '1987-07-08', 'F', 'papaza@fcpn.edu.bo', 'Activo'),
(35, '2324567LP', 'Mauricio', 'Calle Mamani', '1978-12-03', 'M', 'mcalle@fcpn.edu.bo', 'Activo'),
(36, '2425678LP', 'Ximena', 'Flores Quispe', '1984-05-18', 'F', 'xflores@fcpn.edu.bo', 'Activo'),
(37, '2526789LP', 'Ernesto', 'Laura Ticona', '1975-10-25', 'M', 'elaura@fcpn.edu.bo', 'Activo'),
(38, '2627890LP', 'Tania', 'Condori Flores', '1982-01-30', 'F', 'tcondori@fcpn.edu.bo', 'Activo'),
(39, '2728901LP', 'Víctor', 'Mamani Apaza', '1976-06-12', 'M', 'vmamani@fcpn.edu.bo', 'Activo'),
(40, '2829012LP', 'Katherine', 'Quispe Pari', '1988-09-22', 'F', 'kquispe@fcpn.edu.bo', 'Activo'),
(41, '2930123LP', 'Alejandro', 'Ticona Calle', '1974-03-08', 'M', 'aticona@fcpn.edu.bo', 'Activo'),
(42, '3031234LP', 'Mónica', 'Mamani Laura', '1981-08-14', 'F', 'mmamanil@fcpn.edu.bo', 'Activo'),
(43, '3132345LP', 'Pablo', 'Flores Condori', '1979-05-28', 'M', 'pflores@fcpn.edu.bo', 'Activo'),
(44, '3233456LP', 'Claudia', 'Apaza Mamani', '1985-12-19', 'F', 'capaza@fcpn.edu.bo', 'Activo'),
(45, '3334567LP', 'Héctor', 'Calle Ticona', '1973-07-02', 'M', 'hcalle@fcpn.edu.bo', 'Activo'),
(46, '3435678LP', 'Yolanda', 'Laura Flores', '1986-04-11', 'F', 'ylaura@fcpn.edu.bo', 'Activo'),
(47, '3536789LP', 'Ángel', 'Condori Apaza', '1977-11-05', 'M', 'acondoria@fcpn.edu.bo', 'Activo'),
(48, '3637890LP', 'Susana', 'Mamani Ticona', '1983-06-20', 'F', 'smamani@fcpn.edu.bo', 'Activo'),
(49, '3738901LP', 'David', 'Quispe Laura', '1975-01-15', 'M', 'dquispel@fcpn.edu.bo', 'Activo'),
(50, '3839012LP', 'Roxana', 'Pari Flores', '1984-09-30', 'F', 'rparif@fcpn.edu.bo', 'Activo'),
(51, '3940123LP', 'Christian', 'Mamani Calle', '1978-04-25', 'M', 'cmamani@fcpn.edu.bo', 'Activo'),
(52, '4041234LP', 'Marisol', 'Ticona Apaza', '1982-10-08', 'F', 'mticona@fcpn.edu.bo', 'Activo'),
(53, '4142345LP', 'Rodrigo', 'Flores Mamani', '1976-03-18', 'M', 'rfloresf@fcpn.edu.bo', 'Activo'),
(54, '4243456LP', 'Diana', 'Laura Condori', '1987-07-22', 'F', 'dlaura@fcpn.edu.bo', 'Activo'),
(55, '4344567LP', 'Eduardo', 'Apaza Quispe', '1974-12-10', 'M', 'eapaza@fcpn.edu.bo', 'Activo'),
(56, '4445678LP', 'Fabiola', 'Calle Mamani', '1981-05-05', 'F', 'fcalle@fcpn.edu.bo', 'Activo'),
(57, '2233501LP', 'Antonio', 'Gutiérrez Mamani', '1955-06-15', 'M', 'agutierrezm@fcpn.edu.bo', 'Activo'),
(58, '2233502LP', 'Manuel', 'Rojas Ticona', '1958-09-20', 'M', 'mrojast@fcpn.edu.bo', 'Activo'),
(59, '2233503LP', 'Teresa', 'Flores Apaza', '1960-03-10', 'F', 'tfloresa@fcpn.edu.bo', 'Activo'),
(60, '2233504LP', 'Ramón', 'Condori Laura', '1957-11-25', 'M', 'rcondoril@fcpn.edu.bo', 'Activo'),
(61, '2233505LP', 'Margarita', 'Quispe Calle', '1962-07-30', 'F', 'mquispec@fcpn.edu.bo', 'Activo'),
(62, '2233506LP', 'Pedro', 'Mamani Vargas', '1954-12-05', 'M', 'pmamaniv@fcpn.edu.bo', 'Activo'),
(63, '2233507LP', 'Rosa Elena', 'Ticona Pari', '1961-05-18', 'F', 'rticonap@fcpn.edu.bo', 'Activo'),
(64, '2233508LP', 'Jaime', 'Laura Huanca', '1959-08-22', 'M', 'jlaurah@fcpn.edu.bo', 'Activo'),
(65, '2233509LP', 'Nancy', 'Apaza Flores', '1963-02-14', 'F', 'napazaf@fcpn.edu.bo', 'Activo'),
(66, '2233510LP', 'Guillermo', 'Calle Mamani', '1956-10-08', 'M', 'gcallem@fcpn.edu.bo', 'Activo'),
(67, '2233511LP', 'Miriam', 'Condori Quispe', '1964-04-30', 'F', 'mcondoriq@fcpn.edu.bo', 'Activo'),
(68, '2233512LP', 'Alfonso', 'Mamani Ticona', '1953-06-12', 'M', 'amamanit@fcpn.edu.bo', 'Activo'),
(69, '2233513LP', 'Juana', 'Flores Mamani', '1965-09-25', 'F', 'jfloresm@fcpn.edu.bo', 'Activo'),
(70, '2233514LP', 'Boris', 'Quispe Apaza', '1952-01-18', 'M', 'bquispea@fcpn.edu.bo', 'Activo'),
(71, '2233515LP', 'Elena', 'Ticona Flores', '1966-07-08', 'F', 'eticonaf@fcpn.edu.bo', 'Activo'),
(72, '2233516LP', 'Marcelo', 'Laura Condori', '1957-03-22', 'M', 'mlaurac@fcpn.edu.bo', 'Activo'),
(73, '2233517LP', 'Gladys', 'Pari Mamani', '1961-11-15', 'F', 'gparim@fcpn.edu.bo', 'Activo'),
(74, '2233518LP', 'Renato', 'Huanca Quispe', '1954-05-30', 'M', 'rhuancaq@fcpn.edu.bo', 'Activo'),
(75, '2233519LP', 'Sandra', 'Calle Apaza', '1963-08-12', 'F', 'scallea@fcpn.edu.bo', 'Activo'),
(76, '2233520LP', 'Omar', 'Mamani Flores', '1958-12-28', 'M', 'omamanif@fcpn.edu.bo', 'Activo'),
(77, '2000101LP', 'Juan Carlos', 'Mamani Quispe', '1972-03-15', 'M', 'jmamaniq@fcpn.edu.bo', 'Activo'),
(78, '2000102LP', 'María Elena', 'Flores Apaza', '1973-07-22', 'F', 'mfloresa@fcpn.edu.bo', 'Activo'),
(79, '2000103LP', 'Pedro Luis', 'Condori Mamani', '1971-11-08', 'M', 'pcondorim@fcpn.edu.bo', 'Activo'),
(80, '2000104LP', 'Ana María', 'Ticona Laura', '1974-01-30', 'F', 'aticonal@fcpn.edu.bo', 'Activo'),
(81, '2000105LP', 'José Antonio', 'Huanca Pari', '1972-09-14', 'M', 'jhuancap@fcpn.edu.bo', 'Activo'),
(82, '2000106LP', 'Rosa Elena', 'Apaza Flores', '1973-05-18', 'F', 'rapazaf@fcpn.edu.bo', 'Activo'),
(83, '2000107LP', 'Carlos Alberto', 'Mamani Condori', '1971-12-03', 'M', 'cmamanic@fcpn.edu.bo', 'Activo'),
(84, '2000108LP', 'Patricia', 'Laura Quispe', '1974-08-25', 'F', 'plauraq@fcpn.edu.bo', 'Activo'),
(85, '2000109LP', 'Miguel Ángel', 'Flores Ticona', '1972-02-10', 'M', 'mflorest@fcpn.edu.bo', 'Activo'),
(86, '2000110LP', 'Sonia', 'Condori Huanca', '1973-10-05', 'F', 'scondorih@fcpn.edu.bo', 'Activo'),
(87, '2000111LP', 'Roberto', 'Quispe Mamani', '1971-06-20', 'M', 'rquispem@fcpn.edu.bo', 'Activo'),
(88, '2000112LP', 'Carmen', 'Ticona Apaza', '1974-04-12', 'F', 'cticonaa@fcpn.edu.bo', 'Activo'),
(89, '2000113LP', 'Fernando', 'Mamani Flores', '1972-11-28', 'M', 'fmamanif@fcpn.edu.bo', 'Activo'),
(90, '2000114LP', 'Gloria', 'Huanca Laura', '1973-03-07', 'F', 'ghuancal@fcpn.edu.bo', 'Activo'),
(91, '2000115LP', 'Ricardo', 'Apaza Condori', '1971-08-19', 'M', 'rapazac@fcpn.edu.bo', 'Activo'),
(92, '2000116LP', 'Nancy', 'Laura Quispe', '1974-12-01', 'F', 'nlauraq@fcpn.edu.bo', 'Activo'),
(93, '2000117LP', 'Eduardo', 'Flores Mamani', '1972-05-14', 'M', 'efloresm@fcpn.edu.bo', 'Activo'),
(94, '2000118LP', 'Verónica', 'Condori Apaza', '1973-09-30', 'F', 'vcondoria@fcpn.edu.bo', 'Activo'),
(95, '2000119LP', 'Mario', 'Quispe Ticona', '1971-01-22', 'M', 'mquispet@fcpn.edu.bo', 'Activo'),
(96, '2000120LP', 'Claudia', 'Mamani Laura', '1974-07-08', 'F', 'cmamanil@fcpn.edu.bo', 'Activo'),
(97, '2000121LP', 'Héctor', 'Ticona Flores', '1972-04-03', 'M', 'hticonaf@fcpn.edu.bo', 'Activo'),
(98, '2000122LP', 'Daniela', 'Apaza Huanca', '1973-11-16', 'F', 'dapazah@fcpn.edu.bo', 'Activo'),
(99, '2000123LP', 'Gustavo', 'Laura Condori', '1971-02-28', 'M', 'glaurac@fcpn.edu.bo', 'Activo'),
(100, '2000124LP', 'Mónica', 'Flores Quispe', '1974-06-15', 'F', 'mfloresq@fcpn.edu.bo', 'Activo'),
(101, '2000125LP', 'Alejandro', 'Condori Mamani', '1972-10-09', 'M', 'acondorim@fcpn.edu.bo', 'Activo'),
(102, '2000126LP', 'Roxana', 'Quispe Apaza', '1973-08-23', 'F', 'rquispea1@fcpn.edu.bo', 'Activo'),
(103, '2000127LP', 'Pablo', 'Mamani Ticona', '1971-05-17', 'M', 'pmamanit@fcpn.edu.bo', 'Activo'),
(104, '2000128LP', 'Yolanda', 'Huanca Flores', '1974-03-11', 'F', 'yhuancaf@fcpn.edu.bo', 'Activo'),
(105, '2000129LP', 'Christian', 'Ticona Laura', '1972-12-05', 'M', 'cticonal@fcpn.edu.bo', 'Activo'),
(106, '2000130LP', 'Silvia', 'Apaza Mamani', '1973-04-29', 'F', 'sapazam@fcpn.edu.bo', 'Activo'),
(107, '2000131LP', 'Oscar', 'Laura Condori', '1971-09-13', 'M', 'olaurac@fcpn.edu.bo', 'Activo'),
(108, '2000132LP', 'Marcela', 'Flores Quispe', '1974-01-27', 'F', 'mfloresq1@fcpn.edu.bo', 'Activo'),
(109, '2000133LP', 'René', 'Condori Huanca', '1972-07-19', 'M', 'rcondorih@fcpn.edu.bo', 'Activo'),
(110, '2000134LP', 'Juana', 'Quispe Apaza', '1973-02-08', 'F', 'jquispea@fcpn.edu.bo', 'Activo'),
(111, '2000135LP', 'Boris', 'Mamani Flores', '1971-10-31', 'M', 'bmamanif@fcpn.edu.bo', 'Activo'),
(112, '2000136LP', 'Teresa', 'Ticona Laura', '1974-05-24', 'F', 'tticonal@fcpn.edu.bo', 'Activo'),
(113, '2000137LP', 'Antonio', 'Huanca Mamani', '1972-01-15', 'M', 'ahuancam@fcpn.edu.bo', 'Activo'),
(114, '2000138LP', 'Susana', 'Apaza Condori', '1973-06-09', 'F', 'sapazac@fcpn.edu.bo', 'Activo'),
(115, '2000139LP', 'Ramiro', 'Laura Quispe', '1971-03-04', 'M', 'rlauraq@fcpn.edu.bo', 'Activo'),
(116, '2000140LP', 'Elena', 'Flores Apaza', '1974-11-20', 'F', 'efloresa@fcpn.edu.bo', 'Activo'),
(117, '2000141LP', 'Víctor Hugo', 'Mamani Quispe', '1974-05-12', 'M', 'vmamaniq@fcpn.edu.bo', 'Activo'),
(118, '2000201LP', 'Andrea', 'Mamani Quispe', '1977-03-15', 'F', 'amamaniq@fcpn.edu.bo', 'Activo'),
(119, '2000143LP', 'Francisco', 'Condori Mamani', '1973-12-05', 'M', 'fcondorim@fcpn.edu.bo', 'Activo'),
(120, '2000144LP', 'Natalia', 'Ticona Laura', '1976-02-18', 'F', 'nticonal@fcpn.edu.bo', 'Activo'),
(121, '2000145LP', 'Ángel', 'Huanca Pari', '1974-09-30', 'M', 'áhuancap@fcpn.edu.bo', 'Activo'),
(122, '2000146LP', 'Katherine', 'Apaza Flores', '1975-06-14', 'F', 'kapazaf@fcpn.edu.bo', 'Activo'),
(123, '2000147LP', 'David', 'Mamani Condori', '1973-01-28', 'M', 'dmamanic@fcpn.edu.bo', 'Activo'),
(124, '2000148LP', 'Fabiola', 'Laura Quispe', '1976-10-09', 'F', 'flauraq@fcpn.edu.bo', 'Activo'),
(125, '2000149LP', 'Ernesto', 'Flores Ticona', '1974-03-17', 'M', 'eflorest@fcpn.edu.bo', 'Activo'),
(126, '2000150LP', 'Cecilia', 'Condori Huanca', '1975-11-22', 'F', 'ccondorih@fcpn.edu.bo', 'Activo'),
(127, '2000151LP', 'Marco Antonio', 'Quispe Mamani', '1973-07-08', 'M', 'mquispem@fcpn.edu.bo', 'Activo'),
(128, '2000152LP', 'Liliana', 'Ticona Apaza', '1976-04-15', 'F', 'lticonaa@fcpn.edu.bo', 'Activo'),
(129, '2000153LP', 'Rolando', 'Mamani Flores', '1974-08-30', 'M', 'rmamanif@fcpn.edu.bo', 'Activo'),
(130, '2000154LP', 'Paola', 'Huanca Laura', '1975-05-19', 'F', 'phuancal@fcpn.edu.bo', 'Activo'),
(131, '2000155LP', 'Sergio', 'Apaza Condori', '1973-09-11', 'M', 'sapazac1@fcpn.edu.bo', 'Activo'),
(132, '2000156LP', 'Adriana', 'Laura Quispe', '1976-12-03', 'F', 'alauraq@fcpn.edu.bo', 'Activo'),
(133, '2000157LP', 'Enrique', 'Flores Mamani', '1974-06-25', 'M', 'efloresm1@fcpn.edu.bo', 'Activo'),
(134, '2000158LP', 'Diana', 'Condori Apaza', '1975-02-14', 'F', 'dcondoria@fcpn.edu.bo', 'Activo'),
(135, '2000159LP', 'Jaime', 'Quispe Ticona', '1973-10-07', 'M', 'jquispet@fcpn.edu.bo', 'Activo'),
(136, '2000160LP', 'Ximena', 'Mamani Laura', '1976-07-29', 'F', 'xmamanil@fcpn.edu.bo', 'Activo'),
(137, '2000161LP', 'Guillermo', 'Ticona Flores', '1974-01-20', 'M', 'gticonaf@fcpn.edu.bo', 'Activo'),
(138, '2000162LP', 'Lorena', 'Apaza Huanca', '1975-04-06', 'F', 'lapazah@fcpn.edu.bo', 'Activo'),
(139, '2000163LP', 'Rafael', 'Laura Condori', '1973-11-18', 'M', 'rlaurac@fcpn.edu.bo', 'Activo'),
(140, '2000164LP', 'Soledad', 'Flores Quispe', '1976-09-01', 'F', 'sfloresq@fcpn.edu.bo', 'Activo'),
(141, '2000165LP', 'Alfonso', 'Condori Mamani', '1974-05-24', 'M', 'acondorim1@fcpn.edu.bo', 'Activo'),
(142, '2000166LP', 'Miriam', 'Quispe Apaza', '1975-12-10', 'F', 'mquispea@fcpn.edu.bo', 'Activo'),
(143, '2000167LP', 'Humberto', 'Mamani Ticona', '1973-03-15', 'M', 'hmamanit@fcpn.edu.bo', 'Activo'),
(144, '2000168LP', 'Gladys', 'Huanca Flores', '1976-08-08', 'F', 'ghuancaf@fcpn.edu.bo', 'Activo'),
(145, '2000169LP', 'Mauricio', 'Ticona Laura', '1974-10-02', 'M', 'mticonal@fcpn.edu.bo', 'Activo'),
(146, '2000170LP', 'Sandra', 'Apaza Mamani', '1975-07-26', 'F', 'sapazam1@fcpn.edu.bo', 'Activo'),
(147, '2000171LP', 'Leonardo', 'Laura Condori', '1973-02-19', 'M', 'llaurac@fcpn.edu.bo', 'Activo'),
(148, '2000172LP', 'Elizabeth', 'Flores Quispe', '1976-05-13', 'F', 'efloresq@fcpn.edu.bo', 'Activo'),
(149, '2000173LP', 'Rodrigo', 'Condori Huanca', '1974-09-07', 'M', 'rcondorih1@fcpn.edu.bo', 'Activo'),
(150, '2000174LP', 'Marisol', 'Quispe Apaza', '1975-01-30', 'F', 'mquispea1@fcpn.edu.bo', 'Activo'),
(151, '2000175LP', 'Omar', 'Mamani Flores', '1973-06-22', 'M', 'omamanif1@fcpn.edu.bo', 'Activo'),
(152, '2000176LP', 'Tania', 'Ticona Laura', '1976-03-16', 'F', 'tticonal1@fcpn.edu.bo', 'Activo'),
(153, '2000177LP', 'Felipe', 'Huanca Mamani', '1974-11-09', 'M', 'fhuancam@fcpn.edu.bo', 'Activo'),
(154, '2000178LP', 'Rocío', 'Apaza Condori', '1975-08-04', 'F', 'rapazac1@fcpn.edu.bo', 'Activo'),
(155, '2000179LP', 'Esteban', 'Laura Quispe', '1973-04-27', 'M', 'elauraq@fcpn.edu.bo', 'Activo'),
(156, '2000180LP', 'Carla', 'Flores Apaza', '1976-01-21', 'F', 'cfloresa@fcpn.edu.bo', 'Activo'),
(157, '2000181LP', 'Iván', 'Condori Mamani', '1974-07-14', 'M', 'icondorim@fcpn.edu.bo', 'Activo'),
(158, '2000182LP', 'Noemí', 'Quispe Ticona', '1975-05-08', 'F', 'nquispet@fcpn.edu.bo', 'Activo'),
(159, '2000183LP', 'Arturo', 'Mamani Laura', '1973-12-31', 'M', 'amamanil@fcpn.edu.bo', 'Activo'),
(160, '2000184LP', 'Jacqueline', 'Ticona Flores', '1976-10-25', 'F', 'jticonaf@fcpn.edu.bo', 'Activo'),
(161, '2000185LP', 'Raúl', 'Huanca Quispe', '1974-02-17', 'M', 'rhuancaq1@fcpn.edu.bo', 'Activo'),
(162, '2000186LP', 'Viviana', 'Apaza Mamani', '1975-09-12', 'F', 'vapazam@fcpn.edu.bo', 'Activo'),
(163, '2000187LP', 'Fabián', 'Laura Flores', '1973-05-06', 'M', 'flauraf@fcpn.edu.bo', 'Activo'),
(164, '2000188LP', 'Marlene', 'Condori Apaza', '1976-06-29', 'F', 'mcondoria@fcpn.edu.bo', 'Activo'),
(165, '2000189LP', 'Cristian', 'Mamani Huanca', '1974-12-22', 'M', 'cmamanih@fcpn.edu.bo', 'Activo'),
(166, '2000190LP', 'Pamela', 'Quispe Laura', '1975-03-18', 'F', 'pquispel@fcpn.edu.bo', 'Activo'),
(167, '2000191LP', 'Gonzalo', 'Flores Condori', '1973-08-11', 'M', 'gfloresc@fcpn.edu.bo', 'Activo'),
(168, '2000192LP', 'Erika', 'Ticona Mamani', '1976-04-05', 'F', 'eticonam@fcpn.edu.bo', 'Activo'),
(169, '2000193LP', 'Martín', 'Huanca Apaza', '1974-10-28', 'M', 'mhuancaa@fcpn.edu.bo', 'Activo'),
(170, '2000194LP', 'Alejandra', 'Apaza Laura', '1975-06-20', 'F', 'aapazal@fcpn.edu.bo', 'Activo'),
(171, '2000195LP', 'Joaquín', 'Mamani Quispe', '1973-01-14', 'M', 'jmamaniq1@fcpn.edu.bo', 'Activo'),
(172, '2000196LP', 'Rebeca', 'Condori Flores', '1976-09-07', 'F', 'rcondorif@fcpn.edu.bo', 'Activo'),
(173, '2000197LP', 'Hernán', 'Laura Ticona', '1974-05-30', 'M', 'hlaurat@fcpn.edu.bo', 'Activo'),
(174, '2000198LP', 'Mabel', 'Quispe Mamani', '1975-02-23', 'F', 'mquispem1@fcpn.edu.bo', 'Activo'),
(175, '2000199LP', 'Rubén', 'Flores Apaza', '1973-07-16', 'M', 'rfloresa@fcpn.edu.bo', 'Activo'),
(176, '2000200LP', 'Yésica', 'Ticona Laura', '1976-11-09', 'F', 'yticonal@fcpn.edu.bo', 'Activo'),
(178, '2000301LP', 'Andrea', 'Mamani Quispe', '1977-03-15', 'F', 'amamaniq1@fcpn.edu.bo', 'Activo'),
(179, '2000302LP', 'Nelson', 'Flores Apaza', '1976-07-22', 'M', 'nfloresa@fcpn.edu.bo', 'Activo'),
(180, '2000303LP', 'Leticia', 'Condori Mamani', '1975-11-08', 'F', 'lcondorim@fcpn.edu.bo', 'Activo'),
(181, '2000304LP', 'Hernando', 'Ticona Laura', '1978-01-30', 'M', 'hticonal@fcpn.edu.bo', 'Activo'),
(182, '2000305LP', 'Martha', 'Huanca Pari', '1976-09-14', 'F', 'mhuancap@fcpn.edu.bo', 'Activo'),
(183, '2000306LP', 'Wilson', 'Apaza Flores', '1977-05-18', 'M', 'wapazaf@fcpn.edu.bo', 'Activo'),
(184, '2000307LP', 'Rosario', 'Mamani Condori', '1975-12-03', 'F', 'rmamanic1@fcpn.edu.bo', 'Activo'),
(185, '2000308LP', 'Edwin', 'Laura Quispe', '1978-08-25', 'M', 'elauraq1@fcpn.edu.bo', 'Activo'),
(186, '2000309LP', 'Magaly', 'Flores Ticona', '1976-02-10', 'F', 'mflorest1@fcpn.edu.bo', 'Activo'),
(187, '2000310LP', 'César', 'Condori Huanca', '1977-10-05', 'M', 'ccondorih1@fcpn.edu.bo', 'Activo'),
(188, '2000311LP', 'Delia', 'Quispe Mamani', '1975-06-20', 'F', 'dquispem@fcpn.edu.bo', 'Activo'),
(189, '2000312LP', 'Saúl', 'Ticona Apaza', '1978-04-12', 'M', 'sticonaa@fcpn.edu.bo', 'Activo'),
(190, '2000313LP', 'Vanesa', 'Mamani Flores', '1976-11-28', 'F', 'vmamanif@fcpn.edu.bo', 'Activo'),
(191, '2000314LP', 'Damián', 'Huanca Laura', '1977-03-07', 'M', 'dhuancal@fcpn.edu.bo', 'Activo'),
(192, '2000315LP', 'Flora', 'Apaza Condori', '1975-08-19', 'F', 'fapazac@fcpn.edu.bo', 'Activo'),
(193, '2000316LP', 'Ismael', 'Laura Quispe', '1978-12-01', 'M', 'ilauraq@fcpn.edu.bo', 'Activo'),
(194, '2000317LP', 'Nilda', 'Flores Mamani', '1976-05-14', 'F', 'nfloresm@fcpn.edu.bo', 'Activo'),
(195, '2000318LP', 'Abel', 'Condori Apaza', '1977-09-30', 'M', 'acondoria1@fcpn.edu.bo', 'Activo'),
(196, '2000319LP', 'Yanet', 'Quispe Ticona', '1975-01-22', 'F', 'yquispet@fcpn.edu.bo', 'Activo'),
(197, '2000320LP', 'Vladimir', 'Mamani Laura', '1978-07-08', 'M', 'vmamanil@fcpn.edu.bo', 'Activo'),
(198, '2000321LP', 'Doris', 'Ticona Flores', '1978-03-15', 'F', 'dticonaf@fcpn.edu.bo', 'Activo'),
(199, '2000322LP', 'Elvis', 'Apaza Huanca', '1977-07-22', 'M', 'eapazah@fcpn.edu.bo', 'Activo'),
(200, '2000323LP', 'Mery', 'Laura Condori', '1976-11-08', 'F', 'mlaurac1@fcpn.edu.bo', 'Activo'),
(201, '2000324LP', 'Freddy', 'Flores Quispe', '1979-01-30', 'M', 'ffloresq@fcpn.edu.bo', 'Activo'),
(202, '2000325LP', 'Nelly', 'Condori Mamani', '1977-09-14', 'F', 'ncondorim@fcpn.edu.bo', 'Activo'),
(203, '2000326LP', 'Grover', 'Quispe Apaza', '1978-05-18', 'M', 'gquispea@fcpn.edu.bo', 'Activo'),
(204, '2000327LP', 'Lidia', 'Mamani Ticona', '1976-12-03', 'F', 'lmamanit@fcpn.edu.bo', 'Activo'),
(205, '2000328LP', 'Ronal', 'Huanca Flores', '1979-08-25', 'M', 'rhuancaf@fcpn.edu.bo', 'Activo'),
(206, '2000329LP', 'Betty', 'Ticona Laura', '1977-02-10', 'F', 'bticonal@fcpn.edu.bo', 'Activo'),
(207, '2000330LP', 'Edgar', 'Apaza Mamani', '1978-10-05', 'M', 'eapazam@fcpn.edu.bo', 'Activo'),
(208, '2000331LP', 'Elsa', 'Laura Condori', '1976-06-20', 'F', 'elaurac@fcpn.edu.bo', 'Activo'),
(209, '2000332LP', 'Wilmer', 'Flores Quispe', '1979-04-12', 'M', 'wfloresq@fcpn.edu.bo', 'Activo'),
(210, '2000333LP', 'Graciela', 'Condori Huanca', '1977-11-28', 'F', 'gcondorih@fcpn.edu.bo', 'Activo'),
(211, '2000334LP', 'Bismarck', 'Quispe Apaza', '1978-03-07', 'M', 'bquispea1@fcpn.edu.bo', 'Activo'),
(212, '2000335LP', 'Filomena', 'Mamani Flores', '1976-08-19', 'F', 'fmamanif1@fcpn.edu.bo', 'Activo'),
(213, '2000336LP', 'Adolfo', 'Ticona Laura', '1979-12-01', 'M', 'aticonal1@fcpn.edu.bo', 'Activo'),
(214, '2000337LP', 'Justina', 'Huanca Mamani', '1977-05-14', 'F', 'jhuancam@fcpn.edu.bo', 'Activo'),
(215, '2000338LP', 'Emilio', 'Apaza Condori', '1978-09-30', 'M', 'eapazac@fcpn.edu.bo', 'Activo'),
(216, '2000339LP', 'Sabina', 'Laura Quispe', '1976-01-22', 'F', 'slauraq@fcpn.edu.bo', 'Activo'),
(217, '2000340LP', 'Teófilo', 'Flores Apaza', '1979-07-08', 'M', 'tfloresa1@fcpn.edu.bo', 'Activo'),
(218, '2000341LP', 'Cintia', 'Condori Mamani', '1979-02-14', 'F', 'ccondorim@fcpn.edu.bo', 'Activo'),
(219, '2000342LP', 'Limber', 'Quispe Ticona', '1978-06-28', 'M', 'lquispet@fcpn.edu.bo', 'Activo'),
(220, '2000343LP', 'Eloísa', 'Mamani Laura', '1977-10-11', 'F', 'emamanil@fcpn.edu.bo', 'Activo'),
(221, '2000344LP', 'Benigno', 'Ticona Flores', '1980-04-05', 'M', 'bticonaf@fcpn.edu.bo', 'Activo'),
(222, '2000345LP', 'Teodora', 'Huanca Quispe', '1978-08-19', 'F', 'thuancaq@fcpn.edu.bo', 'Activo'),
(223, '2000346LP', 'Germán', 'Apaza Mamani', '1979-12-02', 'M', 'gapazam@fcpn.edu.bo', 'Activo'),
(224, '2000347LP', 'Basilia', 'Laura Flores', '1977-03-27', 'F', 'blauraf@fcpn.edu.bo', 'Activo'),
(225, '2000348LP', 'Silverio', 'Condori Apaza', '1980-07-15', 'M', 'scondoria@fcpn.edu.bo', 'Activo'),
(226, '2000349LP', 'Melania', 'Mamani Huanca', '1978-11-09', 'F', 'mmamanih@fcpn.edu.bo', 'Activo'),
(227, '2000350LP', 'Demetrio', 'Quispe Laura', '1979-05-23', 'M', 'dquispel1@fcpn.edu.bo', 'Activo'),
(228, '2000351LP', 'Eulogia', 'Flores Condori', '1977-09-16', 'F', 'efloresc@fcpn.edu.bo', 'Activo'),
(229, '2000352LP', 'Saturnino', 'Ticona Mamani', '1980-01-08', 'M', 'sticonam@fcpn.edu.bo', 'Activo'),
(230, '2000353LP', 'Gregoria', 'Huanca Apaza', '1978-05-30', 'F', 'ghuancaa@fcpn.edu.bo', 'Activo'),
(231, '2000354LP', 'Celestino', 'Apaza Laura', '1979-09-22', 'M', 'capazal@fcpn.edu.bo', 'Activo'),
(232, '2000355LP', 'Modesta', 'Mamani Quispe', '1977-01-14', 'F', 'mmamaniq@fcpn.edu.bo', 'Activo'),
(233, '2000356LP', 'Valentín', 'Condori Flores', '1980-05-07', 'M', 'vcondorif@fcpn.edu.bo', 'Activo'),
(234, '2000357LP', 'Petrona', 'Laura Ticona', '1978-09-29', 'F', 'plaurat@fcpn.edu.bo', 'Activo'),
(235, '2000358LP', 'Agapito', 'Quispe Mamani', '1979-02-20', 'M', 'aquispem@fcpn.edu.bo', 'Activo'),
(236, '2000359LP', 'Isabel', 'Flores Apaza', '1977-06-13', 'F', 'ifloresa@fcpn.edu.bo', 'Activo'),
(237, '2000360LP', 'Nicanor', 'Ticona Laura', '1980-10-04', 'M', 'nticonal1@fcpn.edu.bo', 'Activo'),
(238, '2000361LP', 'Lucila', 'Huanca Mamani', '1978-02-26', 'F', 'lhuancam@fcpn.edu.bo', 'Activo'),
(239, '2000362LP', 'Cirilo', 'Apaza Condori', '1979-07-19', 'M', 'capazac@fcpn.edu.bo', 'Activo'),
(240, '2000363LP', 'Eusebia', 'Laura Quispe', '1977-11-11', 'F', 'elauraq2@fcpn.edu.bo', 'Activo'),
(241, '2000364LP', 'Pascual', 'Flores Apaza', '1980-03-05', 'M', 'pfloresa@fcpn.edu.bo', 'Activo'),
(242, '2000365LP', 'Ignacia', 'Condori Mamani', '1978-08-28', 'F', 'icondorim1@fcpn.edu.bo', 'Activo'),
(243, '2000366LP', 'Rufino', 'Quispe Ticona', '1979-12-21', 'M', 'rquispet@fcpn.edu.bo', 'Activo'),
(244, '2000367LP', 'Visitación', 'Mamani Laura', '1977-04-16', 'F', 'vmamanil1@fcpn.edu.bo', 'Activo'),
(245, '2000368LP', 'Cipriano', 'Ticona Flores', '1980-09-08', 'M', 'cticonaf@fcpn.edu.bo', 'Activo'),
(246, '2000369LP', 'Magdalena', 'Huanca Quispe', '1978-01-31', 'F', 'mhuancaq@fcpn.edu.bo', 'Activo'),
(247, '2000370LP', 'Fortunato', 'Apaza Mamani', '1979-06-24', 'M', 'fapazam@fcpn.edu.bo', 'Activo'),
(248, '2000371LP', 'Amalia', 'Mamani Quispe', '1980-03-15', 'F', 'amamaniq2@fcpn.edu.bo', 'Activo'),
(249, '2000372LP', 'Dionisio', 'Flores Apaza', '1979-07-22', 'M', 'dfloresa@fcpn.edu.bo', 'Activo'),
(250, '2000373LP', 'Rita', 'Condori Mamani', '1978-11-08', 'F', 'rcondorim@fcpn.edu.bo', 'Activo'),
(251, '2000374LP', 'Norberto', 'Ticona Laura', '1981-01-30', 'M', 'nticonal2@fcpn.edu.bo', 'Activo'),
(252, '2000375LP', 'Celestina', 'Huanca Pari', '1979-09-14', 'F', 'chuancap@fcpn.edu.bo', 'Activo'),
(253, '2000376LP', 'Gumersindo', 'Apaza Flores', '1980-05-18', 'M', 'gapazaf@fcpn.edu.bo', 'Activo'),
(254, '2000377LP', 'Herminia', 'Mamani Condori', '1978-12-03', 'F', 'hmamanic@fcpn.edu.bo', 'Activo'),
(255, '2000378LP', 'Zacarías', 'Laura Quispe', '1981-08-25', 'M', 'zlauraq@fcpn.edu.bo', 'Activo'),
(256, '2000379LP', 'Pascuala', 'Flores Ticona', '1979-02-10', 'F', 'pflorest@fcpn.edu.bo', 'Activo'),
(257, '2000380LP', 'Anselmo', 'Condori Huanca', '1980-10-05', 'M', 'acondorih@fcpn.edu.bo', 'Activo'),
(258, '2000381LP', 'Melchora', 'Quispe Mamani', '1978-06-20', 'F', 'mquispem2@fcpn.edu.bo', 'Activo'),
(259, '2000382LP', 'Casimiro', 'Ticona Apaza', '1981-04-12', 'M', 'cticonaa1@fcpn.edu.bo', 'Activo'),
(260, '2000383LP', 'Nicomedes', 'Mamani Flores', '1979-11-28', 'M', 'nmamanif1@fcpn.edu.bo', 'Activo'),
(261, '2000384LP', 'Dorotea', 'Huanca Laura', '1980-03-07', 'F', 'dhuancal1@fcpn.edu.bo', 'Activo'),
(262, '2000385LP', 'Epifanio', 'Apaza Condori', '1978-08-19', 'M', 'eapazac1@fcpn.edu.bo', 'Activo'),
(263, '2000386LP', 'Maura', 'Laura Quispe', '1981-12-01', 'F', 'mlauraq@fcpn.edu.bo', 'Activo'),
(264, '2000387LP', 'Leoncio', 'Flores Mamani', '1979-05-14', 'M', 'lfloresm@fcpn.edu.bo', 'Activo'),
(265, '2000388LP', 'Segundina', 'Condori Apaza', '1980-09-30', 'F', 'scondoria1@fcpn.edu.bo', 'Activo'),
(266, '2000389LP', 'Eustaquio', 'Quispe Ticona', '1978-01-22', 'M', 'equispet@fcpn.edu.bo', 'Activo'),
(267, '2000390LP', 'Brigida', 'Mamani Laura', '1981-07-08', 'F', 'bmamanil@fcpn.edu.bo', 'Activo'),
(268, '2000391LP', 'Tiburcio', 'Ticona Flores', '1980-03-15', 'M', 'tticonaf@fcpn.edu.bo', 'Activo'),
(269, '2000392LP', 'Gertrudis', 'Apaza Huanca', '1979-07-22', 'F', 'gapazah@fcpn.edu.bo', 'Activo'),
(270, '2000393LP', 'Toribio', 'Laura Condori', '1978-11-08', 'M', 'tlaurac@fcpn.edu.bo', 'Activo'),
(271, '2000394LP', 'Maximiliana', 'Flores Quispe', '1981-01-30', 'F', 'mfloresq2@fcpn.edu.bo', 'Activo'),
(272, '2000395LP', 'Clemente', 'Condori Mamani', '1979-09-14', 'M', 'ccondorim1@fcpn.edu.bo', 'Activo'),
(273, '2000396LP', 'Raymunda', 'Quispe Apaza', '1980-05-18', 'F', 'rquispea2@fcpn.edu.bo', 'Activo'),
(274, '2000397LP', 'Pantaleón', 'Mamani Ticona', '1978-12-03', 'M', 'pmamanit1@fcpn.edu.bo', 'Activo'),
(275, '2000398LP', 'Dominga', 'Huanca Flores', '1981-08-25', 'F', 'dhuancaf@fcpn.edu.bo', 'Activo'),
(276, '2000399LP', 'Ambrosio', 'Ticona Laura', '1979-02-10', 'M', 'aticonal2@fcpn.edu.bo', 'Activo'),
(277, '2000400LP', 'Felicitas', 'Apaza Mamani', '1980-10-05', 'F', 'fapazam1@fcpn.edu.bo', 'Activo'),
(278, '2000401LP', 'Inocencio', 'Laura Condori', '1978-06-20', 'M', 'ilaurac@fcpn.edu.bo', 'Activo'),
(279, '2000402LP', 'Primitiva', 'Flores Quispe', '1981-04-12', 'F', 'pfloresq@fcpn.edu.bo', 'Activo'),
(280, '2000403LP', 'Dámaso', 'Condori Huanca', '1979-11-28', 'M', 'dcondorih@fcpn.edu.bo', 'Activo'),
(281, '2000404LP', 'Eulalia', 'Quispe Apaza', '1980-03-07', 'F', 'equispea@fcpn.edu.bo', 'Activo'),
(282, '2000405LP', 'Alipio', 'Mamani Flores', '1978-08-19', 'M', 'amamanif@fcpn.edu.bo', 'Activo'),
(283, '2000406LP', 'Bartolina', 'Ticona Laura', '1981-12-01', 'F', 'bticonal1@fcpn.edu.bo', 'Activo'),
(284, '2000407LP', 'Remigio', 'Huanca Mamani', '1979-05-14', 'M', 'rhuancam@fcpn.edu.bo', 'Activo'),
(285, '2000408LP', 'Anastasia', 'Apaza Condori', '1980-09-30', 'F', 'aapazac@fcpn.edu.bo', 'Activo'),
(286, '2000409LP', 'Sinforoso', 'Laura Quispe', '1978-01-22', 'M', 'slauraq1@fcpn.edu.bo', 'Activo'),
(287, '2000410LP', 'Silveria', 'Flores Apaza', '1981-07-08', 'F', 'sfloresa@fcpn.edu.bo', 'Activo'),
(288, '2000411LP', 'Zenobio', 'Condori Mamani', '1980-04-15', 'M', 'zcondorim@fcpn.edu.bo', 'Activo'),
(289, '2000412LP', 'Herculana', 'Quispe Ticona', '1979-08-22', 'F', 'hquispet@fcpn.edu.bo', 'Activo'),
(290, '2000413LP', 'Victoriano', 'Mamani Laura', '1978-12-08', 'M', 'vmamanil2@fcpn.edu.bo', 'Activo'),
(291, '2000414LP', 'Facunda', 'Ticona Flores', '1982-02-18', 'F', 'fticonaf@fcpn.edu.bo', 'Activo'),
(292, '2000415LP', 'Leocadio', 'Huanca Quispe', '1980-06-14', 'M', 'lhuancaq@fcpn.edu.bo', 'Activo'),
(293, '2000416LP', 'Perfecta', 'Apaza Mamani', '1979-10-05', 'F', 'papazam@fcpn.edu.bo', 'Activo'),
(294, '2000417LP', 'Aniceto', 'Laura Flores', '1978-03-28', 'M', 'alauraf@fcpn.edu.bo', 'Activo'),
(295, '2000418LP', 'Escolástica', 'Condori Apaza', '1982-07-15', 'F', 'econdoria@fcpn.edu.bo', 'Activo'),
(296, '2000419LP', 'Bonifacio', 'Mamani Huanca', '1980-11-09', 'M', 'bmamanih@fcpn.edu.bo', 'Activo'),
(297, '2000420LP', 'Tiburcia', 'Quispe Laura', '1979-05-23', 'F', 'tquispel@fcpn.edu.bo', 'Activo'),
(298, '2000421LP', 'Fabiana', 'Flores Condori', '1980-03-15', 'F', 'ffloresc@fcpn.edu.bo', 'Activo'),
(299, '2000422LP', 'Evaristo', 'Ticona Mamani', '1979-07-22', 'M', 'eticonam1@fcpn.edu.bo', 'Activo'),
(300, '2000423LP', 'Sulpicia', 'Huanca Apaza', '1978-11-08', 'F', 'shuancaa@fcpn.edu.bo', 'Activo'),
(301, '2000424LP', 'Gervasio', 'Apaza Laura', '1981-01-30', 'M', 'gapazal@fcpn.edu.bo', 'Activo'),
(302, '2000425LP', 'Demetria', 'Mamani Quispe', '1979-09-14', 'F', 'dmamaniq@fcpn.edu.bo', 'Activo'),
(303, '2000426LP', 'Plácido', 'Condori Flores', '1980-05-18', 'M', 'pcondorif@fcpn.edu.bo', 'Activo'),
(304, '2000427LP', 'Narcisa', 'Laura Ticona', '1978-12-03', 'F', 'nlaurat@fcpn.edu.bo', 'Activo'),
(305, '2000428LP', 'Amancio', 'Quispe Mamani', '1981-08-25', 'M', 'aquispem1@fcpn.edu.bo', 'Activo'),
(306, '2000429LP', 'Clotilde', 'Flores Apaza', '1979-02-10', 'F', 'cfloresa1@fcpn.edu.bo', 'Activo'),
(307, '2000430LP', 'Telesforo', 'Ticona Laura', '1980-10-05', 'M', 'tticonal2@fcpn.edu.bo', 'Activo'),
(308, '2000431LP', 'Alina', 'Huanca Mamani', '1981-04-15', 'F', 'ahuancam1@fcpn.edu.bo', 'Activo'),
(309, '2000432LP', 'Gaspar', 'Apaza Condori', '1980-08-22', 'M', 'gapazac@fcpn.edu.bo', 'Activo'),
(310, '2000433LP', 'Blandina', 'Laura Quispe', '1979-12-08', 'F', 'blauraq@fcpn.edu.bo', 'Activo'),
(311, '2000434LP', 'Melchor', 'Flores Apaza', '1982-02-18', 'M', 'mfloresa1@fcpn.edu.bo', 'Activo'),
(312, '2000435LP', 'Hermelinda', 'Condori Mamani', '1980-06-14', 'F', 'hcondorim@fcpn.edu.bo', 'Activo'),
(313, '2000436LP', 'Baltazar', 'Quispe Ticona', '1979-10-05', 'M', 'bquispet@fcpn.edu.bo', 'Activo'),
(314, '2000437LP', 'Aurelia', 'Mamani Laura', '1978-03-28', 'F', 'amamanil1@fcpn.edu.bo', 'Activo'),
(315, '2000438LP', 'Calixto', 'Ticona Flores', '1982-07-15', 'M', 'cticonaf1@fcpn.edu.bo', 'Activo'),
(316, '2000439LP', 'Florencia', 'Huanca Quispe', '1980-11-09', 'F', 'fhuancaq@fcpn.edu.bo', 'Activo'),
(317, '2000440LP', 'Eugenio', 'Apaza Mamani', '1979-05-23', 'M', 'eapazam1@fcpn.edu.bo', 'Activo'),
(318, '2000441LP', 'Ricarda', 'Laura Flores', '1981-07-14', 'F', 'rlauraf@fcpn.edu.bo', 'Activo'),
(319, '2000442LP', 'Cesáreo', 'Condori Apaza', '1980-03-05', 'M', 'ccondoria@fcpn.edu.bo', 'Activo'),
(320, '2000443LP', 'Odilia', 'Mamani Huanca', '1979-11-18', 'F', 'omamanih@fcpn.edu.bo', 'Activo'),
(321, '2000444LP', 'Candelario', 'Quispe Laura', '1982-05-30', 'M', 'cquispel@fcpn.edu.bo', 'Activo'),
(322, '2000445LP', 'Marcelina', 'Flores Condori', '1980-09-22', 'F', 'mfloresc@fcpn.edu.bo', 'Activo'),
(323, '2000446LP', 'Ruperto', 'Ticona Mamani', '1979-02-14', 'M', 'rticonam@fcpn.edu.bo', 'Activo'),
(324, '2000447LP', 'Luciana', 'Huanca Apaza', '1981-06-08', 'F', 'lhuancaa@fcpn.edu.bo', 'Activo'),
(325, '2000448LP', 'Atanasio', 'Apaza Laura', '1980-10-01', 'M', 'aapazal1@fcpn.edu.bo', 'Activo'),
(326, '2000449LP', 'Eusebio', 'Mamani Quispe', '1979-04-25', 'M', 'emamaniq@fcpn.edu.bo', 'Activo'),
(327, '2000450LP', 'Damiana', 'Condori Flores', '1982-08-19', 'F', 'dcondorif@fcpn.edu.bo', 'Activo'),
(328, '2000451LP', 'Kevin', 'Mamani Quispe', '2005-03-15', 'M', 'kmamaniq@fcpn.edu.bo', 'Activo'),
(329, '2000452LP', 'Brenda', 'Flores Apaza', '2004-07-22', 'F', 'bfloresa@fcpn.edu.bo', 'Activo'),
(330, '2000453LP', 'Jhonny', 'Condori Mamani', '2003-11-08', 'M', 'jcondorim@fcpn.edu.bo', 'Activo'),
(331, '2000454LP', 'Dayana', 'Ticona Laura', '2006-01-30', 'F', 'dticonal@fcpn.edu.bo', 'Activo'),
(332, '2000455LP', 'Brayan', 'Huanca Pari', '2004-09-14', 'M', 'bhuancap@fcpn.edu.bo', 'Activo'),
(333, '2000456LP', 'Yenifer', 'Apaza Flores', '2005-05-18', 'F', 'yapazaf@fcpn.edu.bo', 'Activo'),
(334, '2000457LP', 'Cristofer', 'Mamani Condori', '2003-12-03', 'M', 'cmamanic1@fcpn.edu.bo', 'Activo'),
(335, '2000458LP', 'Kimberly', 'Laura Quispe', '2006-08-25', 'F', 'klauraq@fcpn.edu.bo', 'Activo'),
(336, '2000459LP', 'Maicol', 'Flores Ticona', '2004-02-10', 'M', 'mflorest2@fcpn.edu.bo', 'Activo'),
(337, '2000460LP', 'Yessica', 'Condori Huanca', '2005-10-05', 'F', 'ycondorih@fcpn.edu.bo', 'Activo'),
(338, '2000461LP', 'Alex', 'Quispe Mamani', '2003-06-20', 'M', 'aquispem2@fcpn.edu.bo', 'Activo'),
(339, '2000462LP', 'Shirley', 'Ticona Apaza', '2006-04-12', 'F', 'sticonaa1@fcpn.edu.bo', 'Activo'),
(340, '2000463LP', 'Joel', 'Mamani Flores', '2004-11-28', 'M', 'jmamanif@fcpn.edu.bo', 'Activo'),
(341, '2000464LP', 'Abigail', 'Huanca Laura', '2005-03-07', 'F', 'ahuancal@fcpn.edu.bo', 'Activo'),
(342, '2000465LP', 'Erick', 'Apaza Condori', '2003-08-19', 'M', 'eapazac2@fcpn.edu.bo', 'Activo'),
(343, '2000466LP', 'Estefany', 'Laura Quispe', '2006-12-01', 'F', 'elauraq3@fcpn.edu.bo', 'Activo'),
(344, '2000467LP', 'Jhamil', 'Flores Mamani', '2004-05-14', 'M', 'jfloresm1@fcpn.edu.bo', 'Activo'),
(345, '2000468LP', 'Nayeli', 'Condori Apaza', '2005-09-30', 'F', 'ncondoria@fcpn.edu.bo', 'Activo'),
(346, '2000469LP', 'Yerko', 'Quispe Ticona', '2003-01-22', 'M', 'yquispet1@fcpn.edu.bo', 'Activo'),
(347, '2000470LP', 'Mia', 'Mamani Laura', '2006-07-08', 'F', 'mmamanil1@fcpn.edu.bo', 'Activo'),
(348, '2000471LP', 'Jhael', 'Ticona Flores', '2005-04-15', 'M', 'jticonaf1@fcpn.edu.bo', 'Activo'),
(349, '2000472LP', 'Ashley', 'Apaza Huanca', '2004-08-22', 'F', 'aapazah@fcpn.edu.bo', 'Activo'),
(350, '2000473LP', 'Dilan', 'Laura Condori', '2003-12-08', 'M', 'dlaurac1@fcpn.edu.bo', 'Activo'),
(351, '2000474LP', 'Zoe', 'Flores Quispe', '2006-02-18', 'F', 'zfloresq@fcpn.edu.bo', 'Activo'),
(352, '2000475LP', 'Andy', 'Condori Mamani', '2004-06-14', 'M', 'acondorim2@fcpn.edu.bo', 'Activo'),
(353, '2000476LP', 'Briana', 'Quispe Apaza', '2005-10-05', 'F', 'bquispea2@fcpn.edu.bo', 'Activo'),
(354, '2000477LP', 'Liam', 'Mamani Ticona', '2003-03-28', 'M', 'lmamanit1@fcpn.edu.bo', 'Activo'),
(355, '2000478LP', 'Ariana', 'Huanca Flores', '2006-07-15', 'F', 'ahuancaf@fcpn.edu.bo', 'Activo'),
(356, '2000479LP', 'Thiago', 'Ticona Laura', '2004-11-09', 'M', 'tticonal3@fcpn.edu.bo', 'Activo'),
(357, '2000480LP', 'Sophia', 'Apaza Mamani', '2005-05-23', 'F', 'sapazam2@fcpn.edu.bo', 'Activo'),
(358, '2000481LP', 'Matías', 'Laura Condori', '2005-07-14', 'M', 'mlaurac2@fcpn.edu.bo', 'Activo'),
(359, '2000482LP', 'Camila', 'Flores Quispe', '2004-03-05', 'F', 'cfloresq@fcpn.edu.bo', 'Activo'),
(360, '2000483LP', 'Santiago', 'Condori Huanca', '2003-11-18', 'M', 'scondorih1@fcpn.edu.bo', 'Activo'),
(361, '2000484LP', 'Valentina', 'Quispe Apaza', '2006-05-30', 'F', 'vquispea@fcpn.edu.bo', 'Activo'),
(362, '2000485LP', 'Sebastián', 'Mamani Flores', '2004-09-22', 'M', 'smamanif@fcpn.edu.bo', 'Activo'),
(363, '2000486LP', 'Isabella', 'Ticona Laura', '2005-02-14', 'F', 'iticonal@fcpn.edu.bo', 'Activo'),
(364, '2000487LP', 'Nicolás', 'Huanca Mamani', '2003-06-08', 'M', 'nhuancam@fcpn.edu.bo', 'Activo'),
(365, '2000488LP', 'Mariana', 'Apaza Condori', '2006-10-01', 'F', 'mapazac@fcpn.edu.bo', 'Activo'),
(366, '2000489LP', 'Emmanuel', 'Laura Quispe', '2004-04-25', 'M', 'elauraq4@fcpn.edu.bo', 'Activo'),
(367, '2000490LP', 'Regina', 'Flores Apaza', '2005-08-19', 'F', 'rfloresa1@fcpn.edu.bo', 'Activo'),
(368, '2000491LP', 'Gabriel', 'Condori Mamani', '2006-01-15', 'M', 'gcondorim@fcpn.edu.bo', 'Activo'),
(369, '2000492LP', 'Renata', 'Quispe Ticona', '2005-05-10', 'F', 'rquispet1@fcpn.edu.bo', 'Activo'),
(370, '2000493LP', 'Adrián', 'Mamani Laura', '2004-09-03', 'M', 'amamanil2@fcpn.edu.bo', 'Activo'),
(371, '2000494LP', 'Lucía', 'Ticona Flores', '2006-12-28', 'F', 'lticonaf1@fcpn.edu.bo', 'Activo'),
(372, '2000495LP', 'Mateo', 'Huanca Quispe', '2003-04-20', 'M', 'mhuancaq1@fcpn.edu.bo', 'Activo'),
(373, '2000496LP', 'Ximena', 'Apaza Mamani', '2005-08-14', 'F', 'xapazam@fcpn.edu.bo', 'Activo'),
(374, '2000497LP', 'Diego', 'Laura Flores', '2004-02-07', 'M', 'dlauraf@fcpn.edu.bo', 'Activo'),
(375, '2000498LP', 'Sofía', 'Condori Apaza', '2006-06-30', 'F', 'scondoria2@fcpn.edu.bo', 'Activo'),
(376, '2000499LP', 'Joaquín', 'Mamani Huanca', '2003-10-25', 'M', 'jmamanih@fcpn.edu.bo', 'Activo'),
(377, '2000500LP', 'Fernanda', 'Quispe Laura', '2005-04-18', 'F', 'fquispel@fcpn.edu.bo', 'Activo'),
(378, '2000501LP', 'Alejandro', 'Flores Condori', '2004-08-12', 'M', 'afloresc@fcpn.edu.bo', 'Activo'),
(379, '2000502LP', 'Victoria', 'Ticona Mamani', '2006-01-05', 'F', 'vticonam@fcpn.edu.bo', 'Activo'),
(380, '2000503LP', 'Leonardo', 'Huanca Apaza', '2005-05-29', 'M', 'lhuancaa1@fcpn.edu.bo', 'Activo'),
(381, '2000504LP', 'Julieta', 'Apaza Laura', '2003-09-22', 'F', 'japazal@fcpn.edu.bo', 'Activo'),
(382, '2000505LP', 'Daniel', 'Mamani Quispe', '2006-03-16', 'M', 'dmamaniq1@fcpn.edu.bo', 'Activo'),
(383, '2000506LP', 'Emma', 'Condori Flores', '2004-07-09', 'F', 'econdorif@fcpn.edu.bo', 'Activo'),
(384, '2000507LP', 'Jesús', 'Laura Ticona', '2005-11-02', 'M', 'jlaurat@fcpn.edu.bo', 'Activo'),
(385, '2000508LP', 'Emily', 'Quispe Mamani', '2003-05-26', 'F', 'equispem@fcpn.edu.bo', 'Activo'),
(386, '2000509LP', 'David', 'Flores Apaza', '2006-09-19', 'M', 'dfloresa1@fcpn.edu.bo', 'Activo'),
(387, '2000510LP', 'María José', 'Ticona Laura', '2004-01-12', 'F', 'mticonal1@fcpn.edu.bo', 'Activo'),
(388, '2000511LP', 'Ethan', 'Huanca Mamani', '2005-03-15', 'M', 'ehuancam@fcpn.edu.bo', 'Activo'),
(389, '2000512LP', 'Aitana', 'Apaza Condori', '2004-07-22', 'F', 'aapazac1@fcpn.edu.bo', 'Activo'),
(390, '2000513LP', 'Ian', 'Laura Quispe', '2003-11-08', 'M', 'ilauraq1@fcpn.edu.bo', 'Activo'),
(391, '2000514LP', 'Alma', 'Flores Apaza', '2006-01-30', 'F', 'afloresa@fcpn.edu.bo', 'Activo'),
(392, '2000515LP', 'Bruno', 'Condori Mamani', '2004-09-14', 'M', 'bcondorim1@fcpn.edu.bo', 'Activo'),
(393, '2000516LP', 'Lía', 'Quispe Ticona', '2005-05-18', 'F', 'lquispet1@fcpn.edu.bo', 'Activo'),
(394, '2000517LP', 'Dylan', 'Mamani Laura', '2003-12-03', 'M', 'dmamanil@fcpn.edu.bo', 'Activo'),
(395, '2000518LP', 'Amanda', 'Ticona Flores', '2006-08-25', 'F', 'aticonaf@fcpn.edu.bo', 'Activo'),
(396, '2000519LP', 'Axel', 'Huanca Quispe', '2004-02-10', 'M', 'ahuancaq@fcpn.edu.bo', 'Activo'),
(397, '2000520LP', 'Martina', 'Apaza Mamani', '2005-10-05', 'F', 'mapazam@fcpn.edu.bo', 'Activo'),
(398, '2000521LP', 'Lucas', 'Laura Flores', '2006-05-20', 'M', 'llauraf@fcpn.edu.bo', 'Activo'),
(399, '2000522LP', 'Antonella', 'Condori Apaza', '2005-09-12', 'F', 'acondoria11@fcpn.edu.bo', 'Activo'),
(400, '2000523LP', 'Benjamín', 'Mamani Huanca', '2004-01-08', 'M', 'bmamanih1@fcpn.edu.bo', 'Activo'),
(401, '2000524LP', 'Juliana', 'Quispe Laura', '2006-06-30', 'F', 'jquispel@fcpn.edu.bo', 'Activo'),
(402, '2000525LP', 'Ignacio', 'Flores Condori', '2003-10-22', 'M', 'ifloresc@fcpn.edu.bo', 'Activo'),
(403, '2000526LP', 'Elena', 'Ticona Mamani', '2005-04-14', 'F', 'eticonam2@fcpn.edu.bo', 'Activo'),
(404, '2000527LP', 'Tomás', 'Huanca Apaza', '2004-08-05', 'M', 'thuancaa@fcpn.edu.bo', 'Activo'),
(405, '2000528LP', 'Clara', 'Apaza Laura', '2006-02-28', 'F', 'capazal1@fcpn.edu.bo', 'Activo'),
(406, '2000529LP', 'Pablo', 'Mamani Quispe', '2003-07-15', 'M', 'pmamaniq@fcpn.edu.bo', 'Activo'),
(407, '2000530LP', 'Olivia', 'Condori Flores', '2005-12-08', 'F', 'ocondorif@fcpn.edu.bo', 'Activo'),
(408, '2000531LP', 'Thiago', 'Laura Ticona', '2004-05-25', 'M', 'tlaurat@fcpn.edu.bo', 'Activo'),
(409, '2000532LP', 'Julia', 'Quispe Mamani', '2006-10-18', 'F', 'jquispem@fcpn.edu.bo', 'Activo'),
(410, '2000533LP', 'Adrián', 'Flores Apaza', '2003-02-10', 'M', 'afloresa1@fcpn.edu.bo', 'Activo'),
(411, '2000534LP', 'Paula', 'Ticona Laura', '2005-06-05', 'F', 'pticonal@fcpn.edu.bo', 'Activo'),
(412, '2000535LP', 'Maximiliano', 'Huanca Mamani', '2004-10-29', 'M', 'mhuancam@fcpn.edu.bo', 'Activo'),
(413, '2000536LP', 'Rafaela', 'Apaza Condori', '2006-05-22', 'F', 'rapazac2@fcpn.edu.bo', 'Activo'),
(414, '2000537LP', 'Samuel', 'Laura Quispe', '2003-09-15', 'M', 'slauraq2@fcpn.edu.bo', 'Activo'),
(415, '2000538LP', 'Valeria', 'Flores Apaza', '2005-01-08', 'F', 'vfloresa@fcpn.edu.bo', 'Activo'),
(416, '2000539LP', 'Facundo', 'Condori Mamani', '2004-06-30', 'M', 'fcondorim1@fcpn.edu.bo', 'Activo'),
(417, '2000540LP', 'Carla', 'Quispe Ticona', '2006-11-25', 'F', 'cquispet@fcpn.edu.bo', 'Activo'),
(418, '2000541LP', 'Emilio', 'Mamani Laura', '2005-03-15', 'M', 'emamanil1@fcpn.edu.bo', 'Activo'),
(419, '2000542LP', 'Celia', 'Ticona Flores', '2004-07-22', 'F', 'cticonaf2@fcpn.edu.bo', 'Activo'),
(420, '2000543LP', 'Felipe', 'Huanca Quispe', '2003-11-08', 'M', 'fhuancaq1@fcpn.edu.bo', 'Activo'),
(421, '2000544LP', 'Vera', 'Apaza Mamani', '2006-01-30', 'F', 'vapazam1@fcpn.edu.bo', 'Activo'),
(422, '2000545LP', 'Hugo', 'Laura Flores', '2004-09-14', 'M', 'hlauraf@fcpn.edu.bo', 'Activo'),
(423, '2000546LP', 'Diana', 'Condori Apaza', '2005-05-18', 'F', 'dcondoria1@fcpn.edu.bo', 'Activo'),
(424, '2000547LP', 'Martín', 'Mamani Huanca', '2003-12-03', 'M', 'mmamanih1@fcpn.edu.bo', 'Activo'),
(425, '2000548LP', 'Eva', 'Quispe Laura', '2006-08-25', 'F', 'equispel@fcpn.edu.bo', 'Activo'),
(426, '2000549LP', 'Pedro', 'Flores Condori', '2004-02-10', 'M', 'pfloresc1@fcpn.edu.bo', 'Activo'),
(427, '2000550LP', 'Lola', 'Ticona Mamani', '2005-10-05', 'F', 'lticonam@fcpn.edu.bo', 'Activo'),
(428, '2000551LP', 'Álvaro', 'Huanca Apaza', '2006-05-20', 'M', 'áhuancaa@fcpn.edu.bo', 'Activo'),
(429, '2000552LP', 'Inés', 'Apaza Laura', '2005-09-12', 'F', 'iapazal@fcpn.edu.bo', 'Activo'),
(430, '2000553LP', 'Rafael', 'Mamani Quispe', '2004-01-08', 'M', 'rmamaniq@fcpn.edu.bo', 'Activo'),
(431, '2000554LP', 'Sara', 'Condori Flores', '2006-06-30', 'F', 'scondorif@fcpn.edu.bo', 'Activo'),
(432, '2000555LP', 'Marcos', 'Laura Ticona', '2003-10-22', 'M', 'mlaurat@fcpn.edu.bo', 'Activo'),
(433, '2000556LP', 'Abril', 'Quispe Mamani', '2005-04-14', 'F', 'aquispem3@fcpn.edu.bo', 'Activo'),
(434, '2000557LP', 'Vicente', 'Flores Apaza', '2004-08-05', 'M', 'vfloresa1@fcpn.edu.bo', 'Activo'),
(435, '2000558LP', 'Noa', 'Ticona Laura', '2006-02-28', 'F', 'nticonal3@fcpn.edu.bo', 'Activo'),
(436, '2000559LP', 'Gael', 'Huanca Mamani', '2003-07-15', 'M', 'ghuancam@fcpn.edu.bo', 'Activo'),
(437, '2000560LP', 'Alba', 'Apaza Condori', '2005-12-08', 'F', 'aapazac2@fcpn.edu.bo', 'Activo'),
(438, '2000561LP', 'Eric', 'Laura Quispe', '2004-05-25', 'M', 'elauraq5@fcpn.edu.bo', 'Activo'),
(439, '2000562LP', 'Chloe', 'Flores Apaza', '2006-10-18', 'F', 'cfloresa2@fcpn.edu.bo', 'Activo'),
(440, '2000563LP', 'Héctor', 'Condori Mamani', '2003-02-10', 'M', 'hcondorim1@fcpn.edu.bo', 'Activo'),
(441, '2000564LP', 'Nora', 'Quispe Ticona', '2005-06-05', 'F', 'nquispet1@fcpn.edu.bo', 'Activo'),
(442, '2000565LP', 'Iker', 'Mamani Laura', '2004-10-29', 'M', 'imamanil@fcpn.edu.bo', 'Activo'),
(443, '2000566LP', 'Alicia', 'Ticona Flores', '2006-05-22', 'F', 'aticonaf1@fcpn.edu.bo', 'Activo'),
(444, '2000567LP', 'Asier', 'Huanca Quispe', '2003-09-15', 'M', 'ahuancaq1@fcpn.edu.bo', 'Activo'),
(445, '2000568LP', 'Carmen', 'Apaza Mamani', '2005-01-08', 'F', 'capazam1@fcpn.edu.bo', 'Activo'),
(446, '2000569LP', 'Jon', 'Laura Flores', '2004-06-30', 'M', 'jlauraf@fcpn.edu.bo', 'Activo'),
(447, '2000570LP', 'Triana', 'Condori Apaza', '2006-11-25', 'F', 'tcondoria@fcpn.edu.bo', 'Activo'),
(448, '2000571LP', 'Unai', 'Mamani Huanca', '2005-07-12', 'M', 'umamanih@fcpn.edu.bo', 'Activo'),
(449, '2000572LP', 'Laia', 'Quispe Laura', '2004-11-25', 'F', 'lquispel@fcpn.edu.bo', 'Activo'),
(450, '2000573LP', 'Biel', 'Flores Condori', '2003-05-18', 'M', 'bfloresc@fcpn.edu.bo', 'Activo'),
(451, '2000574LP', 'Ona', 'Ticona Mamani', '2006-09-08', 'F', 'oticonam@fcpn.edu.bo', 'Activo'),
(452, '2000575LP', 'Arnau', 'Huanca Apaza', '2004-02-14', 'M', 'ahuancaa1@fcpn.edu.bo', 'Activo'),
(453, '2000576LP', 'Marina', 'Apaza Laura', '2005-08-30', 'F', 'mapazal@fcpn.edu.bo', 'Activo'),
(454, '2000577LP', 'Pol', 'Mamani Quispe', '2003-12-22', 'M', 'pmamaniq1@fcpn.edu.bo', 'Activo'),
(455, '2000578LP', 'Elsa', 'Condori Flores', '2006-04-15', 'F', 'econdorif1@fcpn.edu.bo', 'Activo'),
(456, '2000579LP', 'Jan', 'Laura Ticona', '2004-10-05', 'M', 'jlaurat1@fcpn.edu.bo', 'Activo'),
(457, '2000580LP', 'Blanca', 'Quispe Mamani', '2005-06-28', 'F', 'bquispem@fcpn.edu.bo', 'Activo'),
(458, '2000581LP', 'Oriol', 'Flores Apaza', '2005-03-15', 'M', 'ofloresa@fcpn.edu.bo', 'Activo'),
(459, '2000582LP', 'Neus', 'Ticona Laura', '2004-07-22', 'F', 'nticonal4@fcpn.edu.bo', 'Activo'),
(460, '2000583LP', 'Gerard', 'Huanca Mamani', '2003-11-08', 'M', 'ghuancam1@fcpn.edu.bo', 'Activo'),
(461, '2000584LP', 'Ivet', 'Apaza Condori', '2006-01-30', 'F', 'iapazac@fcpn.edu.bo', 'Activo'),
(462, '2000585LP', 'Quim', 'Laura Quispe', '2004-09-14', 'M', 'qlauraq@fcpn.edu.bo', 'Activo'),
(463, '2000586LP', 'Txell', 'Flores Apaza', '2005-05-18', 'F', 'tfloresa2@fcpn.edu.bo', 'Activo'),
(464, '2000587LP', 'Nil', 'Condori Mamani', '2003-12-03', 'M', 'ncondorim1@fcpn.edu.bo', 'Activo'),
(465, '2000588LP', 'Bruna', 'Quispe Ticona', '2006-08-25', 'F', 'bquispet1@fcpn.edu.bo', 'Activo'),
(466, '2000589LP', 'Roc', 'Mamani Laura', '2004-02-10', 'M', 'rmamanil@fcpn.edu.bo', 'Activo'),
(467, '2000590LP', 'Jana', 'Ticona Flores', '2005-10-05', 'F', 'jticonaf2@fcpn.edu.bo', 'Activo'),
(468, '2000591LP', 'Pau', 'Huanca Quispe', '2006-05-20', 'M', 'phuancaq@fcpn.edu.bo', 'Activo'),
(469, '2000592LP', 'Lluc', 'Apaza Mamani', '2005-09-12', 'F', 'lapazam@fcpn.edu.bo', 'Activo'),
(470, '2000593LP', 'Max', 'Laura Flores', '2004-01-08', 'M', 'mlauraf@fcpn.edu.bo', 'Activo'),
(471, '2000594LP', 'Iris', 'Condori Apaza', '2006-06-30', 'F', 'icondoria@fcpn.edu.bo', 'Activo'),
(472, '2000595LP', 'Teo', 'Mamani Huanca', '2003-10-22', 'M', 'tmamanih@fcpn.edu.bo', 'Activo'),
(473, '2000596LP', 'Lara', 'Quispe Laura', '2005-04-14', 'F', 'lquispel1@fcpn.edu.bo', 'Activo'),
(474, '2000597LP', 'Enzo', 'Flores Condori', '2004-08-05', 'M', 'efloresc1@fcpn.edu.bo', 'Activo'),
(475, '2000598LP', 'Claudia', 'Ticona Mamani', '2006-02-28', 'F', 'cticonam@fcpn.edu.bo', 'Activo'),
(476, '2000599LP', 'Leo', 'Huanca Apaza', '2003-07-15', 'M', 'lhuancaa2@fcpn.edu.bo', 'Activo'),
(477, '2000600LP', 'Ana', 'Apaza Laura', '2005-12-08', 'F', 'aapazal2@fcpn.edu.bo', 'Activo'),
(478, '12896709', 'Luis Alejandro', 'Zeballos Quiroz', '2006-12-21', 'M', 'lzeballosq@fcpn.edu.bo', 'Activo');

--
-- Disparadores `persona`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_persona_delete` AFTER DELETE ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'DELETE', CONCAT('Eliminada persona ID=', OLD.id_persona, ' (', OLD.nombres, ' ', OLD.apellidos, ')'), CURDATE(), CURTIME());
END
$$
DELIMITER ;
DELIMITER $$

CREATE TRIGGER trg_auditoria_persona_insert
AFTER INSERT ON persona
FOR EACH ROW
BEGIN
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

DELIMITER $$
CREATE TRIGGER `trg_auditoria_persona_update` AFTER UPDATE ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'UPDATE', CONCAT('Actualización persona ID=', NEW.id_persona, ' de ', OLD.nombres, ' a ', NEW.nombres), CURDATE(), CURTIME());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_auto_email_persona` BEFORE INSERT ON `persona` FOR EACH ROW BEGIN
    DECLARE v_username_temp VARCHAR(50);
    
    -- Si el email viene vacío, generarlo automáticamente
    IF NEW.email IS NULL OR NEW.email = '' THEN
        SET v_username_temp = fn_generar_username(NEW.nombres, NEW.apellidos);
        SET NEW.email = fn_generar_email(v_username_temp);
    ELSE
        -- Si viene con valor, validar formato
        IF NEW.email NOT LIKE '%@fcpn.edu.bo' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El email debe tener formato @fcpn.edu.bo';
        END IF;
    END IF;
END
$$
DELIMITER ;

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

--
-- Volcado de datos para la tabla `se_cursa`
--

INSERT INTO `se_cursa` (`id_materia`, `id_paralelo`, `id_aula`, `id_horario`) VALUES
(1, 1, 34, 33),
(1, 1, 34, 36),
(1, 1, 34, 39),
(1, 1, 34, 42),
(1, 1, 34, 45),
(2, 1, 31, 32),
(2, 1, 31, 35),
(2, 1, 31, 38),
(2, 1, 31, 41),
(2, 1, 31, 44),
(3, 1, 44, 33),
(3, 1, 44, 36),
(3, 1, 44, 39),
(3, 1, 44, 42),
(3, 1, 44, 45),
(4, 1, 62, 33),
(4, 1, 62, 36),
(4, 1, 62, 39),
(4, 1, 62, 42),
(4, 1, 62, 45),
(5, 1, 41, 31),
(5, 1, 41, 34),
(5, 1, 41, 37),
(5, 1, 41, 40),
(5, 1, 41, 43),
(6, 1, 35, 31),
(6, 1, 35, 34),
(6, 1, 35, 37),
(6, 1, 35, 40),
(6, 1, 35, 43),
(7, 1, 3, 31),
(7, 1, 3, 34),
(7, 1, 3, 37),
(7, 1, 3, 40),
(7, 1, 3, 43),
(8, 1, 56, 33),
(8, 1, 56, 36),
(8, 1, 56, 39),
(8, 1, 56, 42),
(8, 1, 56, 45),
(9, 1, 63, 32),
(9, 1, 63, 35),
(9, 1, 63, 38),
(9, 1, 63, 41),
(9, 1, 63, 44),
(10, 1, 56, 31),
(10, 1, 56, 34),
(10, 1, 56, 37),
(10, 1, 56, 40),
(10, 1, 56, 43),
(11, 1, 21, 32),
(11, 1, 21, 35),
(11, 1, 21, 38),
(11, 1, 21, 41),
(11, 1, 21, 44),
(12, 1, 58, 32),
(12, 1, 58, 35),
(12, 1, 58, 38),
(12, 1, 58, 41),
(12, 1, 58, 44),
(13, 1, 7, 32),
(13, 1, 7, 35),
(13, 1, 7, 38),
(13, 1, 7, 41),
(13, 1, 7, 44),
(14, 1, 33, 32),
(14, 1, 33, 35),
(14, 1, 33, 38),
(14, 1, 33, 41),
(14, 1, 33, 44),
(15, 1, 22, 32),
(15, 1, 22, 35),
(15, 1, 22, 38),
(15, 1, 22, 41),
(15, 1, 22, 44),
(16, 1, 6, 33),
(16, 1, 6, 36),
(16, 1, 6, 39),
(16, 1, 6, 42),
(16, 1, 6, 45),
(17, 1, 39, 33),
(17, 1, 39, 36),
(17, 1, 39, 39),
(17, 1, 39, 42),
(17, 1, 39, 45),
(18, 1, 55, 31),
(18, 1, 55, 34),
(18, 1, 55, 37),
(18, 1, 55, 40),
(18, 1, 55, 43),
(19, 1, 40, 31),
(19, 1, 40, 34),
(19, 1, 40, 37),
(19, 1, 40, 40),
(19, 1, 40, 43),
(20, 1, 55, 33),
(20, 1, 55, 36),
(20, 1, 55, 39),
(20, 1, 55, 42),
(20, 1, 55, 45),
(21, 1, 49, 31),
(21, 1, 49, 34),
(21, 1, 49, 37),
(21, 1, 49, 40),
(21, 1, 49, 43),
(22, 1, 27, 32),
(22, 1, 27, 35),
(22, 1, 27, 38),
(22, 1, 27, 41),
(22, 1, 27, 44),
(23, 1, 21, 31),
(23, 1, 21, 34),
(23, 1, 21, 37),
(23, 1, 21, 40),
(23, 1, 21, 43),
(24, 1, 1, 32),
(24, 1, 1, 35),
(24, 1, 1, 38),
(24, 1, 1, 41),
(24, 1, 1, 44),
(25, 1, 29, 33),
(25, 1, 29, 36),
(25, 1, 29, 39),
(25, 1, 29, 42),
(25, 1, 29, 45),
(26, 1, 13, 31),
(26, 1, 13, 34),
(26, 1, 13, 37),
(26, 1, 13, 40),
(26, 1, 13, 43),
(27, 1, 34, 32),
(27, 1, 34, 35),
(27, 1, 34, 38),
(27, 1, 34, 41),
(27, 1, 34, 44),
(28, 1, 61, 31),
(28, 1, 61, 34),
(28, 1, 61, 37),
(28, 1, 61, 40),
(28, 1, 61, 43),
(29, 1, 48, 33),
(29, 1, 48, 36),
(29, 1, 48, 39),
(29, 1, 48, 42),
(29, 1, 48, 45),
(30, 1, 16, 32),
(30, 1, 16, 35),
(30, 1, 16, 38),
(30, 1, 16, 41),
(30, 1, 16, 44),
(31, 1, 19, 33),
(31, 1, 19, 36),
(31, 1, 19, 39),
(31, 1, 19, 42),
(31, 1, 19, 45),
(32, 1, 37, 31),
(32, 1, 37, 34),
(32, 1, 37, 37),
(32, 1, 37, 40),
(32, 1, 37, 43),
(33, 1, 54, 31),
(33, 1, 54, 34),
(33, 1, 54, 37),
(33, 1, 54, 40),
(33, 1, 54, 43),
(34, 1, 37, 33),
(34, 1, 37, 36),
(34, 1, 37, 39),
(34, 1, 37, 42),
(34, 1, 37, 45),
(35, 1, 40, 33),
(35, 1, 40, 36),
(35, 1, 40, 39),
(35, 1, 40, 42),
(35, 1, 40, 45),
(36, 1, 30, 32),
(36, 1, 30, 35),
(36, 1, 30, 38),
(36, 1, 30, 41),
(36, 1, 30, 44),
(37, 1, 51, 31),
(37, 1, 51, 34),
(37, 1, 51, 37),
(37, 1, 51, 40),
(37, 1, 51, 43),
(38, 1, 63, 31),
(38, 1, 63, 34),
(38, 1, 63, 37),
(38, 1, 63, 40),
(38, 1, 63, 43),
(39, 1, 44, 31),
(39, 1, 44, 34),
(39, 1, 44, 37),
(39, 1, 44, 40),
(39, 1, 44, 43),
(40, 1, 49, 33),
(40, 1, 49, 36),
(40, 1, 49, 39),
(40, 1, 49, 42),
(40, 1, 49, 45),
(41, 1, 35, 32),
(41, 1, 35, 35),
(41, 1, 35, 38),
(41, 1, 35, 41),
(41, 1, 35, 44),
(42, 1, 10, 33),
(42, 1, 10, 36),
(42, 1, 10, 39),
(42, 1, 10, 42),
(42, 1, 10, 45),
(43, 1, 32, 32),
(43, 1, 32, 35),
(43, 1, 32, 38),
(43, 1, 32, 41),
(43, 1, 32, 44),
(44, 1, 16, 31),
(44, 1, 16, 34),
(44, 1, 16, 37),
(44, 1, 16, 40),
(44, 1, 16, 43),
(45, 1, 27, 31),
(45, 1, 27, 34),
(45, 1, 27, 37),
(45, 1, 27, 40),
(45, 1, 27, 43),
(46, 1, 15, 32),
(46, 1, 15, 35),
(46, 1, 15, 38),
(46, 1, 15, 41),
(46, 1, 15, 44),
(47, 1, 33, 31),
(47, 1, 33, 34),
(47, 1, 33, 37),
(47, 1, 33, 40),
(47, 1, 33, 43),
(48, 1, 32, 31),
(48, 1, 32, 34),
(48, 1, 32, 37),
(48, 1, 32, 40),
(48, 1, 32, 43),
(49, 1, 48, 31),
(49, 1, 48, 34),
(49, 1, 48, 37),
(49, 1, 48, 40),
(49, 1, 48, 43),
(50, 1, 48, 32),
(50, 1, 48, 35),
(50, 1, 48, 38),
(50, 1, 48, 41),
(50, 1, 48, 44),
(51, 1, 50, 32),
(51, 1, 50, 35),
(51, 1, 50, 38),
(51, 1, 50, 41),
(51, 1, 50, 44),
(52, 1, 11, 32),
(52, 1, 11, 35),
(52, 1, 11, 38),
(52, 1, 11, 41),
(52, 1, 11, 44),
(53, 1, 41, 33),
(53, 1, 41, 36),
(53, 1, 41, 39),
(53, 1, 41, 42),
(53, 1, 41, 45),
(54, 1, 5, 33),
(54, 1, 5, 36),
(54, 1, 5, 39),
(54, 1, 5, 42),
(54, 1, 5, 45),
(55, 1, 58, 31),
(55, 1, 58, 34),
(55, 1, 58, 37),
(55, 1, 58, 40),
(55, 1, 58, 43),
(56, 1, 6, 31),
(56, 1, 6, 34),
(56, 1, 6, 37),
(56, 1, 6, 40),
(56, 1, 6, 43),
(57, 1, 49, 32),
(57, 1, 49, 35),
(57, 1, 49, 38),
(57, 1, 49, 41),
(57, 1, 49, 44),
(58, 1, 26, 31),
(58, 1, 26, 34),
(58, 1, 26, 37),
(58, 1, 26, 40),
(58, 1, 26, 43),
(59, 1, 12, 33),
(59, 1, 12, 36),
(59, 1, 12, 39),
(59, 1, 12, 42),
(59, 1, 12, 45),
(60, 1, 17, 33),
(60, 1, 17, 36),
(60, 1, 17, 39),
(60, 1, 17, 42),
(60, 1, 17, 45),
(61, 1, 8, 33),
(61, 1, 8, 36),
(61, 1, 8, 39),
(61, 1, 8, 42),
(61, 1, 8, 45),
(62, 1, 11, 31),
(62, 1, 11, 34),
(62, 1, 11, 37),
(62, 1, 11, 40),
(62, 1, 11, 43),
(63, 1, 3, 32),
(63, 1, 3, 35),
(63, 1, 3, 38),
(63, 1, 3, 41),
(63, 1, 3, 44),
(64, 1, 5, 31),
(64, 1, 5, 34),
(64, 1, 5, 37),
(64, 1, 5, 40),
(64, 1, 5, 43),
(65, 1, 52, 33),
(65, 1, 52, 36),
(65, 1, 52, 39),
(65, 1, 52, 42),
(65, 1, 52, 45),
(66, 1, 39, 31),
(66, 1, 39, 34),
(66, 1, 39, 37),
(66, 1, 39, 40),
(66, 1, 39, 43),
(67, 1, 43, 31),
(67, 1, 43, 34),
(67, 1, 43, 37),
(67, 1, 43, 40),
(67, 1, 43, 43),
(68, 1, 47, 32),
(68, 1, 47, 35),
(68, 1, 47, 38),
(68, 1, 47, 41),
(68, 1, 47, 44),
(69, 1, 19, 31),
(69, 1, 19, 34),
(69, 1, 19, 37),
(69, 1, 19, 40),
(69, 1, 19, 43),
(70, 1, 42, 32),
(70, 1, 42, 35),
(70, 1, 42, 38),
(70, 1, 42, 41),
(70, 1, 42, 44),
(71, 1, 20, 32),
(71, 1, 20, 35),
(71, 1, 20, 38),
(71, 1, 20, 41),
(71, 1, 20, 44),
(72, 1, 16, 33),
(72, 1, 16, 36),
(72, 1, 16, 39),
(72, 1, 16, 42),
(72, 1, 16, 45),
(73, 1, 58, 33),
(73, 1, 58, 36),
(73, 1, 58, 39),
(73, 1, 58, 42),
(73, 1, 58, 45),
(74, 1, 53, 31),
(74, 1, 53, 34),
(74, 1, 53, 37),
(74, 1, 53, 40),
(74, 1, 53, 43),
(75, 1, 22, 31),
(75, 1, 22, 34),
(75, 1, 22, 37),
(75, 1, 22, 40),
(75, 1, 22, 43),
(76, 1, 24, 32),
(76, 1, 24, 35),
(76, 1, 24, 38),
(76, 1, 24, 41),
(76, 1, 24, 44),
(77, 1, 34, 31),
(77, 1, 34, 34),
(77, 1, 34, 37),
(77, 1, 34, 40),
(77, 1, 34, 43),
(78, 1, 15, 33),
(78, 1, 15, 36),
(78, 1, 15, 39),
(78, 1, 15, 42),
(78, 1, 15, 45),
(79, 1, 24, 31),
(79, 1, 24, 34),
(79, 1, 24, 37),
(79, 1, 24, 40),
(79, 1, 24, 43),
(80, 1, 59, 32),
(80, 1, 59, 35),
(80, 1, 59, 38),
(80, 1, 59, 41),
(80, 1, 59, 44),
(81, 1, 23, 32),
(81, 1, 23, 35),
(81, 1, 23, 38),
(81, 1, 23, 41),
(81, 1, 23, 44),
(82, 1, 25, 31),
(82, 1, 25, 34),
(82, 1, 25, 37),
(82, 1, 25, 40),
(82, 1, 25, 43),
(83, 1, 29, 32),
(83, 1, 29, 35),
(83, 1, 29, 38),
(83, 1, 29, 41),
(83, 1, 29, 44),
(84, 1, 46, 31),
(84, 1, 46, 34),
(84, 1, 46, 37),
(84, 1, 46, 40),
(84, 1, 46, 43),
(85, 1, 40, 32),
(85, 1, 40, 35),
(85, 1, 40, 38),
(85, 1, 40, 41),
(85, 1, 40, 44),
(86, 1, 13, 32),
(86, 1, 13, 35),
(86, 1, 13, 38),
(86, 1, 13, 41),
(86, 1, 13, 44),
(87, 1, 46, 32),
(87, 1, 46, 35),
(87, 1, 46, 38),
(87, 1, 46, 41),
(87, 1, 46, 44),
(88, 1, 2, 33),
(88, 1, 2, 36),
(88, 1, 2, 39),
(88, 1, 2, 42),
(88, 1, 2, 45),
(89, 1, 59, 33),
(89, 1, 59, 36),
(89, 1, 59, 39),
(89, 1, 59, 42),
(89, 1, 59, 45),
(90, 1, 41, 32),
(90, 1, 41, 35),
(90, 1, 41, 38),
(90, 1, 41, 41),
(90, 1, 41, 44),
(91, 1, 10, 31),
(91, 1, 10, 34),
(91, 1, 10, 37),
(91, 1, 10, 40),
(91, 1, 10, 43),
(92, 1, 45, 32),
(92, 1, 45, 35),
(92, 1, 45, 38),
(92, 1, 45, 41),
(92, 1, 45, 44),
(93, 1, 32, 33),
(93, 1, 32, 36),
(93, 1, 32, 39),
(93, 1, 32, 42),
(93, 1, 32, 45),
(94, 1, 54, 32),
(94, 1, 54, 35),
(94, 1, 54, 38),
(94, 1, 54, 41),
(94, 1, 54, 44),
(95, 1, 45, 31),
(95, 1, 45, 34),
(95, 1, 45, 37),
(95, 1, 45, 40),
(95, 1, 45, 43),
(96, 1, 30, 33),
(96, 1, 30, 36),
(96, 1, 30, 39),
(96, 1, 30, 42),
(96, 1, 30, 45),
(97, 1, 62, 32),
(97, 1, 62, 35),
(97, 1, 62, 38),
(97, 1, 62, 41),
(97, 1, 62, 44),
(98, 1, 50, 31),
(98, 1, 50, 34),
(98, 1, 50, 37),
(98, 1, 50, 40),
(98, 1, 50, 43),
(99, 1, 12, 32),
(99, 1, 12, 35),
(99, 1, 12, 38),
(99, 1, 12, 41),
(99, 1, 12, 44),
(100, 1, 30, 31),
(100, 1, 30, 34),
(100, 1, 30, 37),
(100, 1, 30, 40),
(100, 1, 30, 43),
(101, 1, 53, 33),
(101, 1, 53, 36),
(101, 1, 53, 39),
(101, 1, 53, 42),
(101, 1, 53, 45),
(102, 1, 36, 31),
(102, 1, 36, 34),
(102, 1, 36, 37),
(102, 1, 36, 40),
(102, 1, 36, 43),
(103, 1, 60, 31),
(103, 1, 60, 34),
(103, 1, 60, 37),
(103, 1, 60, 40),
(103, 1, 60, 43),
(104, 1, 51, 32),
(104, 1, 51, 35),
(104, 1, 51, 38),
(104, 1, 51, 41),
(104, 1, 51, 44),
(105, 1, 27, 33),
(105, 1, 27, 36),
(105, 1, 27, 39),
(105, 1, 27, 42),
(105, 1, 27, 45),
(106, 1, 10, 32),
(106, 1, 10, 35),
(106, 1, 10, 38),
(106, 1, 10, 41),
(106, 1, 10, 44),
(107, 1, 9, 33),
(107, 1, 9, 36),
(107, 1, 9, 39),
(107, 1, 9, 42),
(107, 1, 9, 45),
(108, 1, 46, 33),
(108, 1, 46, 36),
(108, 1, 46, 39),
(108, 1, 46, 42),
(108, 1, 46, 45),
(109, 1, 14, 31),
(109, 1, 14, 34),
(109, 1, 14, 37),
(109, 1, 14, 40),
(109, 1, 14, 43),
(110, 1, 53, 32),
(110, 1, 53, 35),
(110, 1, 53, 38),
(110, 1, 53, 41),
(110, 1, 53, 44),
(111, 1, 18, 32),
(111, 1, 18, 35),
(111, 1, 18, 38),
(111, 1, 18, 41),
(111, 1, 18, 44),
(112, 1, 5, 32),
(112, 1, 5, 35),
(112, 1, 5, 38),
(112, 1, 5, 41),
(112, 1, 5, 44),
(113, 1, 20, 33),
(113, 1, 20, 36),
(113, 1, 20, 39),
(113, 1, 20, 42),
(113, 1, 20, 45),
(114, 1, 36, 32),
(114, 1, 36, 35),
(114, 1, 36, 38),
(114, 1, 36, 41),
(114, 1, 36, 44),
(115, 1, 6, 32),
(115, 1, 6, 35),
(115, 1, 6, 38),
(115, 1, 6, 41),
(115, 1, 6, 44),
(116, 1, 18, 33),
(116, 1, 18, 36),
(116, 1, 18, 39),
(116, 1, 18, 42),
(116, 1, 18, 45),
(117, 1, 20, 31),
(117, 1, 20, 34),
(117, 1, 20, 37),
(117, 1, 20, 40),
(117, 1, 20, 43),
(118, 1, 35, 33),
(118, 1, 35, 36),
(118, 1, 35, 39),
(118, 1, 35, 42),
(118, 1, 35, 45),
(119, 1, 23, 31),
(119, 1, 23, 34),
(119, 1, 23, 37),
(119, 1, 23, 40),
(119, 1, 23, 43),
(120, 1, 38, 32),
(120, 1, 38, 35),
(120, 1, 38, 38),
(120, 1, 38, 41),
(120, 1, 38, 44),
(121, 1, 13, 33),
(121, 1, 13, 36),
(121, 1, 13, 39),
(121, 1, 13, 42),
(121, 1, 13, 45),
(122, 1, 57, 32),
(122, 1, 57, 35),
(122, 1, 57, 38),
(122, 1, 57, 41),
(122, 1, 57, 44),
(123, 1, 60, 33),
(123, 1, 60, 36),
(123, 1, 60, 39),
(123, 1, 60, 42),
(123, 1, 60, 45),
(124, 1, 28, 32),
(124, 1, 28, 35),
(124, 1, 28, 38),
(124, 1, 28, 41),
(124, 1, 28, 44),
(125, 1, 55, 32),
(125, 1, 55, 35),
(125, 1, 55, 38),
(125, 1, 55, 41),
(125, 1, 55, 44),
(126, 1, 37, 32),
(126, 1, 37, 35),
(126, 1, 37, 38),
(126, 1, 37, 41),
(126, 1, 37, 44),
(127, 1, 14, 33),
(127, 1, 14, 36),
(127, 1, 14, 39),
(127, 1, 14, 42),
(127, 1, 14, 45),
(128, 1, 9, 32),
(128, 1, 9, 35),
(128, 1, 9, 38),
(128, 1, 9, 41),
(128, 1, 9, 44),
(129, 1, 52, 31),
(129, 1, 52, 34),
(129, 1, 52, 37),
(129, 1, 52, 40),
(129, 1, 52, 43),
(130, 1, 12, 31),
(130, 1, 12, 34),
(130, 1, 12, 37),
(130, 1, 12, 40),
(130, 1, 12, 43),
(131, 1, 51, 33),
(131, 1, 51, 36),
(131, 1, 51, 39),
(131, 1, 51, 42),
(131, 1, 51, 45),
(132, 1, 1, 33),
(132, 1, 1, 36),
(132, 1, 1, 39),
(132, 1, 1, 42),
(132, 1, 1, 45),
(133, 1, 42, 31),
(133, 1, 42, 34),
(133, 1, 42, 37),
(133, 1, 42, 40),
(133, 1, 42, 43),
(134, 1, 43, 32),
(134, 1, 43, 35),
(134, 1, 43, 38),
(134, 1, 43, 41),
(134, 1, 43, 44),
(135, 1, 2, 31),
(135, 1, 2, 34),
(135, 1, 2, 37),
(135, 1, 2, 40),
(135, 1, 2, 43),
(136, 1, 21, 33),
(136, 1, 21, 36),
(136, 1, 21, 39),
(136, 1, 21, 42),
(136, 1, 21, 45),
(137, 1, 31, 33),
(137, 1, 31, 36),
(137, 1, 31, 39),
(137, 1, 31, 42),
(137, 1, 31, 45),
(138, 1, 42, 33),
(138, 1, 42, 36),
(138, 1, 42, 39),
(138, 1, 42, 42),
(138, 1, 42, 45),
(139, 1, 63, 33),
(139, 1, 63, 36),
(139, 1, 63, 39),
(139, 1, 63, 42),
(139, 1, 63, 45),
(140, 1, 4, 33),
(140, 1, 4, 36),
(140, 1, 4, 39),
(140, 1, 4, 42),
(140, 1, 4, 45),
(141, 1, 2, 32),
(141, 1, 2, 35),
(141, 1, 2, 38),
(141, 1, 2, 41),
(141, 1, 2, 44),
(142, 1, 44, 32),
(142, 1, 44, 35),
(142, 1, 44, 38),
(142, 1, 44, 41),
(142, 1, 44, 44),
(143, 1, 26, 33),
(143, 1, 26, 36),
(143, 1, 26, 39),
(143, 1, 26, 42),
(143, 1, 26, 45),
(144, 1, 29, 31),
(144, 1, 29, 34),
(144, 1, 29, 37),
(144, 1, 29, 40),
(144, 1, 29, 43),
(145, 1, 1, 31),
(145, 1, 1, 34),
(145, 1, 1, 37),
(145, 1, 1, 40),
(145, 1, 1, 43),
(146, 1, 31, 31),
(146, 1, 31, 34),
(146, 1, 31, 37),
(146, 1, 31, 40),
(146, 1, 31, 43),
(147, 1, 17, 31),
(147, 1, 17, 34),
(147, 1, 17, 37),
(147, 1, 17, 40),
(147, 1, 17, 43),
(148, 1, 7, 31),
(148, 1, 7, 34),
(148, 1, 7, 37),
(148, 1, 7, 40),
(148, 1, 7, 43),
(149, 1, 26, 32),
(149, 1, 26, 35),
(149, 1, 26, 38),
(149, 1, 26, 41),
(149, 1, 26, 44),
(150, 1, 7, 33),
(150, 1, 7, 36),
(150, 1, 7, 39),
(150, 1, 7, 42),
(150, 1, 7, 45),
(151, 1, 8, 32),
(151, 1, 8, 35),
(151, 1, 8, 38),
(151, 1, 8, 41),
(151, 1, 8, 44),
(152, 1, 3, 33),
(152, 1, 3, 36),
(152, 1, 3, 39),
(152, 1, 3, 42),
(152, 1, 3, 45),
(153, 1, 45, 33),
(153, 1, 45, 36),
(153, 1, 45, 39),
(153, 1, 45, 42),
(153, 1, 45, 45),
(154, 1, 57, 31),
(154, 1, 57, 34),
(154, 1, 57, 37),
(154, 1, 57, 40),
(154, 1, 57, 43),
(155, 1, 47, 33),
(155, 1, 47, 36),
(155, 1, 47, 39),
(155, 1, 47, 42),
(155, 1, 47, 45),
(156, 1, 52, 32),
(156, 1, 52, 35),
(156, 1, 52, 38),
(156, 1, 52, 41),
(156, 1, 52, 44),
(157, 1, 28, 33),
(157, 1, 28, 36),
(157, 1, 28, 39),
(157, 1, 28, 42),
(157, 1, 28, 45),
(158, 1, 38, 33),
(158, 1, 38, 36),
(158, 1, 38, 39),
(158, 1, 38, 42),
(158, 1, 38, 45),
(159, 1, 17, 32),
(159, 1, 17, 35),
(159, 1, 17, 38),
(159, 1, 17, 41),
(159, 1, 17, 44),
(160, 1, 36, 33),
(160, 1, 36, 36),
(160, 1, 36, 39),
(160, 1, 36, 42),
(160, 1, 36, 45),
(161, 1, 11, 33),
(161, 1, 11, 36),
(161, 1, 11, 39),
(161, 1, 11, 42),
(161, 1, 11, 45),
(162, 1, 54, 33),
(162, 1, 54, 36),
(162, 1, 54, 39),
(162, 1, 54, 42),
(162, 1, 54, 45),
(163, 1, 39, 32),
(163, 1, 39, 35),
(163, 1, 39, 38),
(163, 1, 39, 41),
(163, 1, 39, 44),
(164, 1, 23, 33),
(164, 1, 23, 36),
(164, 1, 23, 39),
(164, 1, 23, 42),
(164, 1, 23, 45),
(165, 1, 62, 31),
(165, 1, 62, 34),
(165, 1, 62, 37),
(165, 1, 62, 40),
(165, 1, 62, 43),
(166, 1, 18, 31),
(166, 1, 18, 34),
(166, 1, 18, 37),
(166, 1, 18, 40),
(166, 1, 18, 43),
(167, 1, 28, 31),
(167, 1, 28, 34),
(167, 1, 28, 37),
(167, 1, 28, 40),
(167, 1, 28, 43),
(168, 1, 25, 32),
(168, 1, 25, 35),
(168, 1, 25, 38),
(168, 1, 25, 41),
(168, 1, 25, 44),
(169, 1, 61, 32),
(169, 1, 61, 35),
(169, 1, 61, 38),
(169, 1, 61, 41),
(169, 1, 61, 44),
(170, 1, 4, 31),
(170, 1, 4, 34),
(170, 1, 4, 37),
(170, 1, 4, 40),
(170, 1, 4, 43),
(171, 1, 57, 33),
(171, 1, 57, 36),
(171, 1, 57, 39),
(171, 1, 57, 42),
(171, 1, 57, 45),
(172, 1, 43, 33),
(172, 1, 43, 36),
(172, 1, 43, 39),
(172, 1, 43, 42),
(172, 1, 43, 45),
(173, 1, 25, 33),
(173, 1, 25, 36),
(173, 1, 25, 39),
(173, 1, 25, 42),
(173, 1, 25, 45),
(174, 1, 24, 33),
(174, 1, 24, 36),
(174, 1, 24, 39),
(174, 1, 24, 42),
(174, 1, 24, 45),
(175, 1, 56, 32),
(175, 1, 56, 35),
(175, 1, 56, 38),
(175, 1, 56, 41),
(175, 1, 56, 44),
(176, 1, 9, 31),
(176, 1, 9, 34),
(176, 1, 9, 37),
(176, 1, 9, 40),
(176, 1, 9, 43),
(177, 1, 15, 31),
(177, 1, 15, 34),
(177, 1, 15, 37),
(177, 1, 15, 40),
(177, 1, 15, 43),
(178, 1, 61, 33),
(178, 1, 61, 36),
(178, 1, 61, 39),
(178, 1, 61, 42),
(178, 1, 61, 45),
(179, 1, 4, 32),
(179, 1, 4, 35),
(179, 1, 4, 38),
(179, 1, 4, 41),
(179, 1, 4, 44),
(180, 1, 47, 31),
(180, 1, 47, 34),
(180, 1, 47, 37),
(180, 1, 47, 40),
(180, 1, 47, 43),
(181, 1, 60, 32),
(181, 1, 60, 35),
(181, 1, 60, 38),
(181, 1, 60, 41),
(181, 1, 60, 44),
(182, 1, 8, 31),
(182, 1, 8, 34),
(182, 1, 8, 37),
(182, 1, 8, 40),
(182, 1, 8, 43),
(183, 1, 22, 33),
(183, 1, 22, 36),
(183, 1, 22, 39),
(183, 1, 22, 42),
(183, 1, 22, 45),
(184, 1, 50, 33),
(184, 1, 50, 36),
(184, 1, 50, 39),
(184, 1, 50, 42),
(184, 1, 50, 45),
(185, 1, 59, 31),
(185, 1, 59, 34),
(185, 1, 59, 37),
(185, 1, 59, 40),
(185, 1, 59, 43),
(186, 1, 19, 32),
(186, 1, 19, 35),
(186, 1, 19, 38),
(186, 1, 19, 41),
(186, 1, 19, 44),
(187, 1, 33, 33),
(187, 1, 33, 36),
(187, 1, 33, 39),
(187, 1, 33, 42),
(187, 1, 33, 45),
(188, 1, 38, 31),
(188, 1, 38, 34),
(188, 1, 38, 37),
(188, 1, 38, 40),
(188, 1, 38, 43),
(189, 1, 14, 32),
(189, 1, 14, 35),
(189, 1, 14, 38),
(189, 1, 14, 41),
(189, 1, 14, 44);

--
-- Disparadores `se_cursa`
--
DELIMITER $$
CREATE TRIGGER `trg_validar_aula_horario` BEFORE INSERT ON `se_cursa` FOR EACH ROW BEGIN
    DECLARE v_conflicto INT;
    
    SELECT COUNT(*) INTO v_conflicto
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    JOIN paralelo p2 ON NEW.id_materia = p2.id_materia AND NEW.id_paralelo = p2.id_paralelo
    WHERE sc.id_aula = NEW.id_aula 
      AND sc.id_horario = NEW.id_horario
      AND p.id_gestion = p2.id_gestion;
    
    IF v_conflicto > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflicto: Ya existe una materia asignada en esta aula y horario.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_validar_docente_horario` BEFORE INSERT ON `se_cursa` FOR EACH ROW BEGIN
    DECLARE v_conflicto INT;
    
    SELECT COUNT(*) INTO v_conflicto
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    JOIN paralelo p_actual ON NEW.id_materia = p_actual.id_materia AND NEW.id_paralelo = p_actual.id_paralelo
    WHERE p.id_docente = p_actual.id_docente
      AND sc.id_horario = NEW.id_horario
      AND p.id_gestion = p_actual.id_gestion
      AND (sc.id_materia != NEW.id_materia OR sc.id_paralelo != NEW.id_paralelo);
    
    IF v_conflicto > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflicto: El docente ya tiene otra materia en este horario.';
    END IF;
END
$$
DELIMITER ;

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
(1, 'cmendozaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 1, 1, 'Activo'),
(2, 'mcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 2, 1, 'Activo'),
(3, 'jflorest', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 3, 1, 'Activo'),
(4, 'garancibiar', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 4, 1, 'Activo'),
(5, 'rlimachiv', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 5, 1, 'Activo'),
(6, 'pgutierrezc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 6, 1, 'Activo'),
(7, 'fmamania', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 7, 3, 'Activo'),
(8, 'shuancal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 8, 3, 'Activo'),
(9, 'rquispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 9, 3, 'Activo'),
(10, 'cticonap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 10, 3, 'Activo'),
(11, 'acondoric', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 11, 3, 'Activo'),
(12, 'lmamanic', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 12, 3, 'Activo'),
(13, 'fvargasl', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 13, 3, 'Activo'),
(14, 'dapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 14, 3, 'Activo'),
(15, 'glaurap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 15, 3, 'Activo'),
(16, 'rcallet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 16, 3, 'Activo'),
(17, 'mparim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 17, 3, 'Activo'),
(18, 'sfloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 18, 3, 'Activo'),
(19, 'dquispeh', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 19, 3, 'Activo'),
(20, 'amendozat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 20, 3, 'Activo'),
(21, 'htitoq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 21, 3, 'Activo'),
(22, 'bcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 22, 3, 'Activo'),
(23, 'rlauraa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 23, 3, 'Activo'),
(24, 'nmamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 24, 3, 'Activo'),
(25, 'oquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 25, 3, 'Activo'),
(26, 'vparic', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 26, 3, 'Activo'),
(27, 'fhuancal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 27, 3, 'Activo'),
(28, 'mmamanit', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 28, 3, 'Activo'),
(29, 'mrflores', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 29, 2, 'Activo'),
(30, 'cquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 30, 3, 'Activo'),
(31, 'jcondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 31, 3, 'Activo'),
(32, 'lticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 32, 3, 'Activo'),
(33, 'rmamanic', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 33, 3, 'Activo'),
(34, 'papazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 34, 3, 'Activo'),
(35, 'mcallem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 35, 3, 'Activo'),
(36, 'xfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 36, 3, 'Activo'),
(37, 'elaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 37, 3, 'Activo'),
(38, 'tcondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 38, 3, 'Activo'),
(39, 'vmamania', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 39, 3, 'Activo'),
(40, 'kquispep', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 40, 3, 'Activo'),
(41, 'aticonac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 41, 3, 'Activo'),
(42, 'mmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 42, 3, 'Activo'),
(43, 'pfloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 43, 3, 'Activo'),
(44, 'capazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 44, 3, 'Activo'),
(45, 'hcallet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 45, 3, 'Activo'),
(46, 'ylauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 46, 3, 'Activo'),
(47, 'acondoria2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 47, 3, 'Activo'),
(48, 'smamanit', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 48, 3, 'Activo'),
(49, 'dquispel2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 49, 3, 'Activo'),
(50, 'rparif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 50, 3, 'Activo'),
(51, 'cmamanic2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 51, 3, 'Activo'),
(52, 'mticonaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 52, 3, 'Activo'),
(53, 'rfloresf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 53, 3, 'Activo'),
(54, 'dlaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 54, 3, 'Activo'),
(55, 'eapazaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 55, 3, 'Activo'),
(56, 'fcallem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 56, 3, 'Activo'),
(57, 'agutierrezm', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 57, 3, 'Activo'),
(58, 'mrojast', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 58, 3, 'Activo'),
(59, 'tfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 59, 3, 'Activo'),
(60, 'rcondoril', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 60, 3, 'Activo'),
(61, 'mquispec', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 61, 3, 'Activo'),
(62, 'pmamaniv', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 62, 3, 'Activo'),
(63, 'rticonap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 63, 3, 'Activo'),
(64, 'jlaurah', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 64, 3, 'Activo'),
(65, 'napazaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 65, 3, 'Activo'),
(66, 'gcallem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 66, 3, 'Activo'),
(67, 'mcondoriq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 67, 3, 'Activo'),
(68, 'amamanit', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 68, 3, 'Activo'),
(69, 'jfloresm', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 69, 3, 'Activo'),
(70, 'bquispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 70, 3, 'Activo'),
(71, 'eticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 71, 3, 'Activo'),
(72, 'mlaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 72, 3, 'Activo'),
(73, 'gparim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 73, 3, 'Activo'),
(74, 'rhuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 74, 3, 'Activo'),
(75, 'scallea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 75, 3, 'Activo'),
(76, 'omamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 76, 3, 'Activo'),
(77, 'jmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 77, 4, 'Activo'),
(78, 'mfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 78, 4, 'Activo'),
(79, 'pcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 79, 4, 'Activo'),
(80, 'aticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 80, 4, 'Activo'),
(81, 'jhuancap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 81, 4, 'Activo'),
(82, 'rapazaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 82, 4, 'Activo'),
(83, 'cmamanic', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 83, 4, 'Activo'),
(84, 'plauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 84, 4, 'Activo'),
(85, 'mflorest', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 85, 4, 'Activo'),
(86, 'scondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 86, 4, 'Activo'),
(87, 'rquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 87, 4, 'Activo'),
(88, 'cticonaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 88, 4, 'Activo'),
(89, 'fmamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 89, 4, 'Activo'),
(90, 'ghuancal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 90, 4, 'Activo'),
(91, 'rapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 91, 4, 'Activo'),
(92, 'nlauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 92, 4, 'Activo'),
(93, 'efloresm', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 93, 4, 'Activo'),
(94, 'vcondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 94, 4, 'Activo'),
(95, 'mquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 95, 4, 'Activo'),
(96, 'cmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 96, 4, 'Activo'),
(97, 'hticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 97, 4, 'Activo'),
(98, 'dapazah', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 98, 4, 'Activo'),
(99, 'glaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 99, 4, 'Activo'),
(100, 'mfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 100, 4, 'Activo'),
(101, 'acondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 101, 4, 'Activo'),
(102, 'rquispea1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 102, 4, 'Activo'),
(103, 'pmamanit', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 103, 4, 'Activo'),
(104, 'yhuancaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 104, 4, 'Activo'),
(105, 'cticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 105, 4, 'Activo'),
(106, 'sapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 106, 4, 'Activo'),
(107, 'olaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 107, 4, 'Activo'),
(108, 'mfloresq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 108, 4, 'Activo'),
(109, 'rcondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 109, 4, 'Activo'),
(110, 'jquispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 110, 4, 'Activo'),
(111, 'bmamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 111, 4, 'Activo'),
(112, 'tticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 112, 4, 'Activo'),
(113, 'ahuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 113, 4, 'Activo'),
(114, 'sapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 114, 4, 'Activo'),
(115, 'rlauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 115, 4, 'Activo'),
(116, 'efloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 116, 4, 'Activo'),
(117, 'vmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 117, 4, 'Activo'),
(118, 'amamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 118, 4, 'Activo'),
(119, 'fcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 119, 4, 'Activo'),
(120, 'nticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 120, 4, 'Activo'),
(121, 'áhuancap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 121, 4, 'Activo'),
(122, 'kapazaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 122, 4, 'Activo'),
(123, 'dmamanic', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 123, 4, 'Activo'),
(124, 'flauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 124, 4, 'Activo'),
(125, 'eflorest', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 125, 4, 'Activo'),
(126, 'ccondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 126, 4, 'Activo'),
(127, 'mquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 127, 4, 'Activo'),
(128, 'lticonaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 128, 4, 'Activo'),
(129, 'rmamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 129, 4, 'Activo'),
(130, 'phuancal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 130, 4, 'Activo'),
(131, 'sapazac1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 131, 4, 'Activo'),
(132, 'alauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 132, 4, 'Activo'),
(133, 'efloresm1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 133, 4, 'Activo'),
(134, 'dcondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 134, 4, 'Activo'),
(135, 'jquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 135, 4, 'Activo'),
(136, 'xmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 136, 4, 'Activo'),
(137, 'gticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 137, 4, 'Activo'),
(138, 'lapazah', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 138, 4, 'Activo'),
(139, 'rlaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 139, 4, 'Activo'),
(140, 'sfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 140, 4, 'Activo'),
(141, 'acondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 141, 4, 'Activo'),
(142, 'mquispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 142, 4, 'Activo'),
(143, 'hmamanit', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 143, 4, 'Activo'),
(144, 'ghuancaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 144, 4, 'Activo'),
(145, 'mticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 145, 4, 'Activo'),
(146, 'sapazam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 146, 4, 'Activo'),
(147, 'llaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 147, 4, 'Activo'),
(148, 'efloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 148, 4, 'Activo'),
(149, 'rcondorih1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 149, 4, 'Activo'),
(150, 'mquispea1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 150, 4, 'Activo'),
(151, 'omamanif1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 151, 4, 'Activo'),
(152, 'tticonal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 152, 4, 'Activo'),
(153, 'fhuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 153, 4, 'Activo'),
(154, 'rapazac1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 154, 4, 'Activo'),
(155, 'elauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 155, 4, 'Activo'),
(156, 'cfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 156, 4, 'Activo'),
(157, 'icondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 157, 4, 'Activo'),
(158, 'nquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 158, 4, 'Activo'),
(159, 'amamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 159, 4, 'Activo'),
(160, 'jticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 160, 4, 'Activo'),
(161, 'rhuancaq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 161, 4, 'Activo'),
(162, 'vapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 162, 4, 'Activo'),
(163, 'flauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 163, 4, 'Activo'),
(164, 'mcondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 164, 4, 'Activo'),
(165, 'cmamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 165, 4, 'Activo'),
(166, 'pquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 166, 4, 'Activo'),
(167, 'gfloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 167, 4, 'Activo'),
(168, 'eticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 168, 4, 'Activo'),
(169, 'mhuancaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 169, 4, 'Activo'),
(170, 'aapazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 170, 4, 'Activo'),
(171, 'jmamaniq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 171, 4, 'Activo'),
(172, 'rcondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 172, 4, 'Activo'),
(173, 'hlaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 173, 4, 'Activo'),
(174, 'mquispem1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 174, 4, 'Activo'),
(175, 'rfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 175, 4, 'Activo'),
(176, 'yticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 176, 4, 'Activo'),
(177, 'amamaniq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 178, 4, 'Activo'),
(178, 'nfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 179, 4, 'Activo'),
(179, 'lcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 180, 4, 'Activo'),
(180, 'hticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 181, 4, 'Activo'),
(181, 'mhuancap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 182, 4, 'Activo'),
(182, 'wapazaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 183, 4, 'Activo'),
(183, 'rmamanic1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 184, 4, 'Activo'),
(184, 'elauraq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 185, 4, 'Activo'),
(185, 'mflorest1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 186, 4, 'Activo'),
(186, 'ccondorih1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 187, 4, 'Activo'),
(187, 'dquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 188, 4, 'Activo'),
(188, 'sticonaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 189, 4, 'Activo'),
(189, 'vmamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 190, 4, 'Activo'),
(190, 'dhuancal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 191, 4, 'Activo'),
(191, 'fapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 192, 4, 'Activo'),
(192, 'ilauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 193, 4, 'Activo'),
(193, 'nfloresm', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 194, 4, 'Activo'),
(194, 'acondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 195, 4, 'Activo'),
(195, 'yquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 196, 4, 'Activo'),
(196, 'vmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 197, 4, 'Activo'),
(197, 'dticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 198, 4, 'Activo'),
(198, 'eapazah', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 199, 4, 'Activo'),
(199, 'mlaurac1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 200, 4, 'Activo'),
(200, 'ffloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 201, 4, 'Activo'),
(201, 'ncondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 202, 4, 'Activo'),
(202, 'gquispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 203, 4, 'Activo'),
(203, 'lmamanit', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 204, 4, 'Activo'),
(204, 'rhuancaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 205, 4, 'Activo'),
(205, 'bticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 206, 4, 'Activo'),
(206, 'eapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 207, 4, 'Activo'),
(207, 'elaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 208, 4, 'Activo'),
(208, 'wfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 209, 4, 'Activo'),
(209, 'gcondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 210, 4, 'Activo'),
(210, 'bquispea1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 211, 4, 'Activo'),
(211, 'fmamanif1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 212, 4, 'Activo'),
(212, 'aticonal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 213, 4, 'Activo'),
(213, 'jhuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 214, 4, 'Activo'),
(214, 'eapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 215, 4, 'Activo'),
(215, 'slauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 216, 4, 'Activo'),
(216, 'tfloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 217, 4, 'Activo'),
(217, 'ccondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 218, 4, 'Activo'),
(218, 'lquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 219, 4, 'Activo'),
(219, 'emamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 220, 4, 'Activo'),
(220, 'bticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 221, 4, 'Activo'),
(221, 'thuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 222, 4, 'Activo'),
(222, 'gapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 223, 4, 'Activo'),
(223, 'blauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 224, 4, 'Activo'),
(224, 'scondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 225, 4, 'Activo'),
(225, 'mmamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 226, 4, 'Activo'),
(226, 'dquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 227, 4, 'Activo'),
(227, 'efloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 228, 4, 'Activo'),
(228, 'sticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 229, 4, 'Activo'),
(229, 'ghuancaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 230, 4, 'Activo'),
(230, 'capazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 231, 4, 'Activo'),
(231, 'mmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 232, 4, 'Activo'),
(232, 'vcondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 233, 4, 'Activo'),
(233, 'plaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 234, 4, 'Activo'),
(234, 'aquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 235, 4, 'Activo'),
(235, 'ifloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 236, 4, 'Activo'),
(236, 'nticonal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 237, 4, 'Activo'),
(237, 'lhuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 238, 4, 'Activo'),
(238, 'capazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 239, 4, 'Activo'),
(239, 'elauraq2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 240, 4, 'Activo'),
(240, 'pfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 241, 4, 'Activo'),
(241, 'icondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 242, 4, 'Activo'),
(242, 'rquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 243, 4, 'Activo'),
(243, 'vmamanil1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 244, 4, 'Activo'),
(244, 'cticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 245, 4, 'Activo'),
(245, 'mhuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 246, 4, 'Activo'),
(246, 'fapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 247, 4, 'Activo'),
(247, 'amamaniq2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 248, 4, 'Activo'),
(248, 'dfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 249, 4, 'Activo'),
(249, 'rcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 250, 4, 'Activo'),
(250, 'nticonal2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 251, 4, 'Activo'),
(251, 'chuancap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 252, 4, 'Activo'),
(252, 'gapazaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 253, 4, 'Activo'),
(253, 'hmamanic', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 254, 4, 'Activo'),
(254, 'zlauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 255, 4, 'Activo'),
(255, 'pflorest', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 256, 4, 'Activo'),
(256, 'acondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 257, 4, 'Activo'),
(257, 'mquispem2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 258, 4, 'Activo'),
(258, 'cticonaa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 259, 4, 'Activo'),
(259, 'nmamanif1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 260, 4, 'Activo'),
(260, 'dhuancal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 261, 4, 'Activo'),
(261, 'eapazac1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 262, 4, 'Activo'),
(262, 'mlauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 263, 4, 'Activo'),
(263, 'lfloresm', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 264, 4, 'Activo'),
(264, 'scondoria1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 265, 4, 'Activo'),
(265, 'equispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 266, 4, 'Activo'),
(266, 'bmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 267, 4, 'Activo'),
(267, 'tticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 268, 4, 'Activo'),
(268, 'gapazah', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 269, 4, 'Activo'),
(269, 'tlaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 270, 4, 'Activo'),
(270, 'mfloresq2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 271, 4, 'Activo'),
(271, 'ccondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 272, 4, 'Activo'),
(272, 'rquispea2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 273, 4, 'Activo'),
(273, 'pmamanit1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 274, 4, 'Activo'),
(274, 'dhuancaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 275, 4, 'Activo'),
(275, 'aticonal2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 276, 4, 'Activo'),
(276, 'fapazam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 277, 4, 'Activo'),
(277, 'ilaurac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 278, 4, 'Activo'),
(278, 'pfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 279, 4, 'Activo'),
(279, 'dcondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 280, 4, 'Activo'),
(280, 'equispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 281, 4, 'Activo'),
(281, 'amamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 282, 4, 'Activo'),
(282, 'bticonal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 283, 4, 'Activo'),
(283, 'rhuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 284, 4, 'Activo'),
(284, 'aapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 285, 4, 'Activo'),
(285, 'slauraq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 286, 4, 'Activo'),
(286, 'sfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 287, 4, 'Activo'),
(287, 'zcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 288, 4, 'Activo'),
(288, 'hquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 289, 4, 'Activo'),
(289, 'vmamanil2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 290, 4, 'Activo'),
(290, 'fticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 291, 4, 'Activo'),
(291, 'lhuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 292, 4, 'Activo'),
(292, 'papazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 293, 4, 'Activo'),
(293, 'alauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 294, 4, 'Activo'),
(294, 'econdoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 295, 4, 'Activo'),
(295, 'bmamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 296, 4, 'Activo'),
(296, 'tquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 297, 4, 'Activo'),
(297, 'ffloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 298, 4, 'Activo'),
(298, 'eticonam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 299, 4, 'Activo'),
(299, 'shuancaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 300, 4, 'Activo'),
(300, 'gapazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 301, 4, 'Activo'),
(301, 'dmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 302, 4, 'Activo'),
(302, 'pcondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 303, 4, 'Activo'),
(303, 'nlaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 304, 4, 'Activo'),
(304, 'aquispem1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 305, 4, 'Activo'),
(305, 'cfloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 306, 4, 'Activo'),
(306, 'tticonal2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 307, 4, 'Activo'),
(307, 'ahuancam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 308, 4, 'Activo'),
(308, 'gapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 309, 4, 'Activo'),
(309, 'blauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 310, 4, 'Activo'),
(310, 'mfloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 311, 4, 'Activo'),
(311, 'hcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 312, 4, 'Activo'),
(312, 'bquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 313, 4, 'Activo'),
(313, 'amamanil1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 314, 4, 'Activo'),
(314, 'cticonaf1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 315, 4, 'Activo'),
(315, 'fhuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 316, 4, 'Activo'),
(316, 'eapazam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 317, 4, 'Activo'),
(317, 'rlauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 318, 4, 'Activo'),
(318, 'ccondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 319, 4, 'Activo'),
(319, 'omamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 320, 4, 'Activo'),
(320, 'cquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 321, 4, 'Activo'),
(321, 'mfloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 322, 4, 'Activo'),
(322, 'rticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 323, 4, 'Activo'),
(323, 'lhuancaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 324, 4, 'Activo'),
(324, 'aapazal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 325, 4, 'Activo'),
(325, 'emamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 326, 4, 'Activo'),
(326, 'dcondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 327, 4, 'Activo'),
(327, 'kmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 328, 4, 'Activo'),
(328, 'bfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 329, 4, 'Activo'),
(329, 'jcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 330, 4, 'Activo'),
(330, 'dticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 331, 4, 'Activo'),
(331, 'bhuancap', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 332, 4, 'Activo'),
(332, 'yapazaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 333, 4, 'Activo'),
(333, 'cmamanic1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 334, 4, 'Activo'),
(334, 'klauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 335, 4, 'Activo'),
(335, 'mflorest2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 336, 4, 'Activo'),
(336, 'ycondorih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 337, 4, 'Activo'),
(337, 'aquispem2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 338, 4, 'Activo'),
(338, 'sticonaa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 339, 4, 'Activo'),
(339, 'jmamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 340, 4, 'Activo'),
(340, 'ahuancal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 341, 4, 'Activo'),
(341, 'eapazac2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 342, 4, 'Activo'),
(342, 'elauraq3', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 343, 4, 'Activo'),
(343, 'jfloresm1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 344, 4, 'Activo'),
(344, 'ncondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 345, 4, 'Activo'),
(345, 'yquispet1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 346, 4, 'Activo'),
(346, 'mmamanil1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 347, 4, 'Activo'),
(347, 'jticonaf1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 348, 4, 'Activo'),
(348, 'aapazah', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 349, 4, 'Activo'),
(349, 'dlaurac1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 350, 4, 'Activo'),
(350, 'zfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 351, 4, 'Activo'),
(351, 'acondorim2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 352, 4, 'Activo'),
(352, 'bquispea2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 353, 4, 'Activo'),
(353, 'lmamanit1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 354, 4, 'Activo'),
(354, 'ahuancaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 355, 4, 'Activo'),
(355, 'tticonal3', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 356, 4, 'Activo'),
(356, 'sapazam2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 357, 4, 'Activo'),
(357, 'mlaurac2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 358, 4, 'Activo'),
(358, 'cfloresq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 359, 4, 'Activo'),
(359, 'scondorih1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 360, 4, 'Activo'),
(360, 'vquispea', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 361, 4, 'Activo'),
(361, 'smamanif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 362, 4, 'Activo'),
(362, 'iticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 363, 4, 'Activo'),
(363, 'nhuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 364, 4, 'Activo'),
(364, 'mapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 365, 4, 'Activo'),
(365, 'elauraq4', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 366, 4, 'Activo'),
(366, 'rfloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 367, 4, 'Activo'),
(367, 'gcondorim', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 368, 4, 'Activo'),
(368, 'rquispet1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 369, 4, 'Activo'),
(369, 'amamanil2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 370, 4, 'Activo'),
(370, 'lticonaf1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 371, 4, 'Activo'),
(371, 'mhuancaq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 372, 4, 'Activo'),
(372, 'xapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 373, 4, 'Activo'),
(373, 'dlauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 374, 4, 'Activo'),
(374, 'scondoria2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 375, 4, 'Activo'),
(375, 'jmamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 376, 4, 'Activo'),
(376, 'fquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 377, 4, 'Activo'),
(377, 'afloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 378, 4, 'Activo'),
(378, 'vticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 379, 4, 'Activo'),
(379, 'lhuancaa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 380, 4, 'Activo'),
(380, 'japazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 381, 4, 'Activo'),
(381, 'dmamaniq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 382, 4, 'Activo'),
(382, 'econdorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 383, 4, 'Activo'),
(383, 'jlaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 384, 4, 'Activo'),
(384, 'equispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 385, 4, 'Activo'),
(385, 'dfloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 386, 4, 'Activo'),
(386, 'mticonal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 387, 4, 'Activo'),
(387, 'ehuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 388, 4, 'Activo'),
(388, 'aapazac1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 389, 4, 'Activo'),
(389, 'ilauraq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 390, 4, 'Activo'),
(390, 'afloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 391, 4, 'Activo'),
(391, 'bcondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 392, 4, 'Activo'),
(392, 'lquispet1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 393, 4, 'Activo'),
(393, 'dmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 394, 4, 'Activo'),
(394, 'aticonaf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 395, 4, 'Activo'),
(395, 'ahuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 396, 4, 'Activo'),
(396, 'mapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 397, 4, 'Activo'),
(397, 'llauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 398, 4, 'Activo'),
(398, 'acondoria1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 399, 4, 'Activo'),
(399, 'bmamanih1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 400, 4, 'Activo'),
(400, 'jquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 401, 4, 'Activo'),
(401, 'ifloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 402, 4, 'Activo'),
(402, 'eticonam2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 403, 4, 'Activo'),
(403, 'thuancaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 404, 4, 'Activo'),
(404, 'capazal1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 405, 4, 'Activo'),
(405, 'pmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 406, 4, 'Activo'),
(406, 'ocondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 407, 4, 'Activo'),
(407, 'tlaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 408, 4, 'Activo'),
(408, 'jquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 409, 4, 'Activo'),
(409, 'afloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 410, 4, 'Activo'),
(410, 'pticonal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 411, 4, 'Activo'),
(411, 'mhuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 412, 4, 'Activo'),
(412, 'rapazac2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 413, 4, 'Activo'),
(413, 'slauraq2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 414, 4, 'Activo'),
(414, 'vfloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 415, 4, 'Activo'),
(415, 'fcondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 416, 4, 'Activo'),
(416, 'cquispet', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 417, 4, 'Activo'),
(417, 'emamanil1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 418, 4, 'Activo'),
(418, 'cticonaf2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 419, 4, 'Activo'),
(419, 'fhuancaq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 420, 4, 'Activo'),
(420, 'vapazam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 421, 4, 'Activo'),
(421, 'hlauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 422, 4, 'Activo'),
(422, 'dcondoria1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 423, 4, 'Activo'),
(423, 'mmamanih1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 424, 4, 'Activo'),
(424, 'equispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 425, 4, 'Activo'),
(425, 'pfloresc1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 426, 4, 'Activo'),
(426, 'lticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 427, 4, 'Activo'),
(427, 'áhuancaa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 428, 4, 'Activo'),
(428, 'iapazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 429, 4, 'Activo'),
(429, 'rmamaniq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 430, 4, 'Activo'),
(430, 'scondorif', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 431, 4, 'Activo'),
(431, 'mlaurat', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 432, 4, 'Activo'),
(432, 'aquispem3', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 433, 4, 'Activo'),
(433, 'vfloresa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 434, 4, 'Activo'),
(434, 'nticonal3', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 435, 4, 'Activo'),
(435, 'ghuancam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 436, 4, 'Activo'),
(436, 'aapazac2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 437, 4, 'Activo'),
(437, 'elauraq5', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 438, 4, 'Activo'),
(438, 'cfloresa2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 439, 4, 'Activo'),
(439, 'hcondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 440, 4, 'Activo'),
(440, 'nquispet1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 441, 4, 'Activo'),
(441, 'imamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 442, 4, 'Activo'),
(442, 'aticonaf1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 443, 4, 'Activo'),
(443, 'ahuancaq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 444, 4, 'Activo'),
(444, 'capazam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 445, 4, 'Activo'),
(445, 'jlauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 446, 4, 'Activo'),
(446, 'tcondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 447, 4, 'Activo'),
(447, 'umamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 448, 4, 'Activo'),
(448, 'lquispel', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 449, 4, 'Activo'),
(449, 'bfloresc', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 450, 4, 'Activo'),
(450, 'oticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 451, 4, 'Activo'),
(451, 'ahuancaa1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 452, 4, 'Activo'),
(452, 'mapazal', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 453, 4, 'Activo'),
(453, 'pmamaniq1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 454, 4, 'Activo'),
(454, 'econdorif1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 455, 4, 'Activo'),
(455, 'jlaurat1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 456, 4, 'Activo'),
(456, 'bquispem', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 457, 4, 'Activo'),
(457, 'ofloresa', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 458, 4, 'Activo'),
(458, 'nticonal4', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 459, 4, 'Activo'),
(459, 'ghuancam1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 460, 4, 'Activo'),
(460, 'iapazac', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 461, 4, 'Activo'),
(461, 'qlauraq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 462, 4, 'Activo'),
(462, 'tfloresa2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 463, 4, 'Activo'),
(463, 'ncondorim1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 464, 4, 'Activo'),
(464, 'bquispet1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 465, 4, 'Activo'),
(465, 'rmamanil', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 466, 4, 'Activo'),
(466, 'jticonaf2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 467, 4, 'Activo'),
(467, 'phuancaq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 468, 4, 'Activo'),
(468, 'lapazam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 469, 4, 'Activo'),
(469, 'mlauraf', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 470, 4, 'Activo'),
(470, 'icondoria', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 471, 4, 'Activo'),
(471, 'tmamanih', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 472, 4, 'Activo'),
(472, 'lquispel1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 473, 4, 'Activo'),
(473, 'efloresc1', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 474, 4, 'Activo'),
(474, 'cticonam', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 475, 4, 'Activo'),
(475, 'lhuancaa2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 476, 4, 'Activo'),
(476, 'aapazal2', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 477, 4, 'Activo'),
(477, 'lzeballosq', '$2b$10$v6C8y532/GcEPMtkWOGtaO/K0EkpFX44PX2ieO0xgr1A.yyePMydC', 478, 4, 'Activo');

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
DELIMITER $$
CREATE TRIGGER `trg_auto_username_usuario` BEFORE INSERT ON `usuario` FOR EACH ROW BEGIN
    DECLARE v_nombres VARCHAR(80);
    DECLARE v_apellidos VARCHAR(80);
    DECLARE v_ci VARCHAR(20);
    
    -- Obtener datos de persona
    SELECT nombres, apellidos, ci INTO v_nombres, v_apellidos, v_ci
    FROM persona WHERE id_persona = NEW.id_persona;
    
    -- ✅ Generar username si viene vacío
    IF NEW.username IS NULL OR NEW.username = '' THEN
        SET NEW.username = fn_generar_username(v_nombres, v_apellidos);
    END IF;
    
    -- ❌ ELIMINADO: NO generar contraseña automáticamente
    -- IF NEW.password_hash IS NULL OR NEW.password_hash = '' THEN
    --     SET NEW.password_hash = fn_extraer_numero_ci(v_ci);
    -- END IF;
    
    -- ✅ Validar que la contraseña NO esté vacía
    IF NEW.password_hash IS NULL OR NEW.password_hash = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La contraseña debe ser generada en el backend con BCrypt.';
    END IF;
    
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_validar_usuario_unico` BEFORE INSERT ON `usuario` FOR EACH ROW BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM usuario WHERE id_persona = NEW.id_persona AND estado = 'Activo';
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya existe un usuario activo para esta persona.';
    END IF;
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
  ADD PRIMARY KEY (`id_persona`,`id_carrera`,`gestion`),
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
  ADD PRIMARY KEY (`id_materia`,`id_paralelo`,`id_gestion`),
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
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2117;

--
-- AUTO_INCREMENT de la tabla `aula`
--
ALTER TABLE `aula`
  MODIFY `id_aula` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=64;

--
-- AUTO_INCREMENT de la tabla `carrera`
--
ALTER TABLE `carrera`
  MODIFY `id_carrera` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `criterio_evaluacion`
--
ALTER TABLE `criterio_evaluacion`
  MODIFY `id_criterio` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `detalle_inscripcion`
--
ALTER TABLE `detalle_inscripcion`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=516;

--
-- AUTO_INCREMENT de la tabla `gestion`
--
ALTER TABLE `gestion`
  MODIFY `id_gestion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT de la tabla `horario`
--
ALTER TABLE `horario`
  MODIFY `id_horario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT de la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  MODIFY `id_inscripcion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=104;

--
-- AUTO_INCREMENT de la tabla `materia`
--
ALTER TABLE `materia`
  MODIFY `id_materia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=310;

--
-- AUTO_INCREMENT de la tabla `nota`
--
ALTER TABLE `nota`
  MODIFY `id_nota` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1014;

--
-- AUTO_INCREMENT de la tabla `persona`
--
ALTER TABLE `persona`
  MODIFY `id_persona` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=479;

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
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=478;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `administrativo`
--
ALTER TABLE `administrativo`
  ADD CONSTRAINT `fk_admin_carrera` FOREIGN KEY (`id_carrera`) REFERENCES `carrera` (`id_carrera`),
  ADD CONSTRAINT `fk_admin_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`) ON DELETE CASCADE;

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
  ADD CONSTRAINT `fk_docente_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`) ON DELETE CASCADE;

--
-- Filtros para la tabla `estudiante`
--
ALTER TABLE `estudiante`
  ADD CONSTRAINT `fk_estudiante_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`) ON DELETE CASCADE,
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
  ADD CONSTRAINT `fk_usuario_persona` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id_persona`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_usuario_rol` FOREIGN KEY (`id_rol`) REFERENCES `rol` (`id_rol`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
