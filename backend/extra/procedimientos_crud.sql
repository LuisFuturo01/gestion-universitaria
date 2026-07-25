-- ==============================================================================
-- SCRIPT DE PROCEDIMIENTOS ALMACENADOS CRUD FALTANTES PARA LA BASE DE DATOS
-- Ejecutar este archivo SQL en MySQL / phpMyAdmin sobre la BD 'sistemaacademico'
-- ==============================================================================

USE sistemaacademico;

DELIMITER $$

-- 1. CARRERA
DROP PROCEDURE IF EXISTS sp_crear_carrera$$
CREATE PROCEDURE sp_crear_carrera(IN p_nombre VARCHAR(100))
BEGIN
    INSERT INTO carrera (nombre) VALUES (p_nombre);
    SELECT LAST_INSERT_ID() AS id_carrera;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_carreras$$
CREATE PROCEDURE sp_obtener_carreras()
BEGIN
    SELECT * FROM carrera;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_carrera_por_id$$
CREATE PROCEDURE sp_obtener_carrera_por_id(IN p_id_carrera INT)
BEGIN
    SELECT * FROM carrera WHERE id_carrera = p_id_carrera;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_carrera$$
CREATE PROCEDURE sp_actualizar_carrera(IN p_id_carrera INT, IN p_nombre VARCHAR(100))
BEGIN
    UPDATE carrera SET nombre = p_nombre WHERE id_carrera = p_id_carrera;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_carrera$$
CREATE PROCEDURE sp_eliminar_carrera(IN p_id_carrera INT)
BEGIN
    DELETE FROM carrera WHERE id_carrera = p_id_carrera;
END$$

-- 2. MATERIA
DROP PROCEDURE IF EXISTS sp_crear_materia$$
CREATE PROCEDURE sp_crear_materia(IN p_sigla VARCHAR(15), IN p_nombre VARCHAR(100), IN p_creditos INT)
BEGIN
    INSERT INTO materia (sigla, nombre, creditos) VALUES (p_sigla, p_nombre, p_creditos);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_materias$$
CREATE PROCEDURE sp_obtener_materias()
BEGIN
    SELECT * FROM materia;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_materia_por_id$$
CREATE PROCEDURE sp_obtener_materia_por_id(IN p_id INT)
BEGIN
    SELECT * FROM materia WHERE id_materia = p_id;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_materia$$
CREATE PROCEDURE sp_actualizar_materia(IN p_id INT, IN p_sigla VARCHAR(15), IN p_nombre VARCHAR(100), IN p_creditos INT)
BEGIN
    UPDATE materia SET sigla = p_sigla, nombre = p_nombre, creditos = p_creditos WHERE id_materia = p_id;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_materia$$
CREATE PROCEDURE sp_eliminar_materia(IN p_id INT)
BEGIN
    DELETE FROM materia WHERE id_materia = p_id;
END$$

-- 3. AULA
DROP PROCEDURE IF EXISTS sp_crear_aula$$
CREATE PROCEDURE sp_crear_aula(IN p_nombre VARCHAR(50), IN p_ubicacion VARCHAR(100), IN p_capacidad INT)
BEGIN
    INSERT INTO aula (nombre, ubicacion, capacidad) VALUES (p_nombre, p_ubicacion, p_capacidad);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_aulas$$
CREATE PROCEDURE sp_obtener_aulas()
BEGIN
    SELECT * FROM aula;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_aula_por_id$$
CREATE PROCEDURE sp_obtener_aula_por_id(IN p_id_aula INT)
BEGIN
    SELECT * FROM aula WHERE id_aula = p_id_aula;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_aula$$
CREATE PROCEDURE sp_actualizar_aula(IN p_id_aula INT, IN p_nombre VARCHAR(50), IN p_ubicacion VARCHAR(100), IN p_capacidad INT)
BEGIN
    UPDATE aula SET nombre = p_nombre, ubicacion = p_ubicacion, capacidad = p_capacidad WHERE id_aula = p_id_aula;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_aula$$
CREATE PROCEDURE sp_eliminar_aula(IN p_id_aula INT)
BEGIN
    DELETE FROM aula WHERE id_aula = p_id_aula;
END$$

-- 4. GESTION
DROP PROCEDURE IF EXISTS sp_crear_gestion$$
CREATE PROCEDURE sp_crear_gestion(IN p_periodo VARCHAR(20))
BEGIN
    INSERT INTO gestion (periodo) VALUES (p_periodo);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_gestiones$$
CREATE PROCEDURE sp_obtener_gestiones()
BEGIN
    SELECT * FROM gestion;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_gestion$$
CREATE PROCEDURE sp_actualizar_gestion(IN p_id_gestion INT, IN p_periodo VARCHAR(20))
BEGIN
    UPDATE gestion SET periodo = p_periodo WHERE id_gestion = p_id_gestion;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_gestion$$
CREATE PROCEDURE sp_eliminar_gestion(IN p_id_gestion INT)
BEGIN
    DELETE FROM gestion WHERE id_gestion = p_id_gestion;
END$$

-- 5. HORARIO
DROP PROCEDURE IF EXISTS sp_crear_horario$$
CREATE PROCEDURE sp_crear_horario(IN p_dia VARCHAR(15), IN p_hora_inicio TIME, IN p_hora_fin TIME)
BEGIN
    INSERT INTO horario (dia, hora_inicio, hora_fin) VALUES (p_dia, p_hora_inicio, p_hora_fin);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_horarios$$
CREATE PROCEDURE sp_obtener_horarios()
BEGIN
    SELECT * FROM horario;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_horario_por_id$$
CREATE PROCEDURE sp_obtener_horario_por_id(IN p_id_horario INT)
BEGIN
    SELECT * FROM horario WHERE id_horario = p_id_horario;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_horario$$
CREATE PROCEDURE sp_actualizar_horario(IN p_id_horario INT, IN p_dia VARCHAR(15), IN p_hora_inicio TIME, IN p_hora_fin TIME)
BEGIN
    UPDATE horario SET dia = p_dia, hora_inicio = p_hora_inicio, hora_fin = p_hora_fin WHERE id_horario = p_id_horario;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_horario$$
CREATE PROCEDURE sp_eliminar_horario(IN p_id_horario INT)
BEGIN
    DELETE FROM horario WHERE id_horario = p_id_horario;
END$$

-- 6. PARALELO
DROP PROCEDURE IF EXISTS sp_crear_paralelo$$
CREATE PROCEDURE sp_crear_paralelo(
    IN p_id_materia INT, IN p_id_paralelo INT, IN p_nombre VARCHAR(10),
    IN p_cupo_maximo INT, IN p_id_docente INT, IN p_id_gestion INT
)
BEGIN
    INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, id_docente, id_gestion)
    VALUES (p_id_materia, p_id_paralelo, p_nombre, p_cupo_maximo, p_id_docente, p_id_gestion);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_paralelos$$
CREATE PROCEDURE sp_obtener_paralelos()
BEGIN
    SELECT * FROM paralelo;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_paralelo$$
CREATE PROCEDURE sp_actualizar_paralelo(
    IN p_id_materia INT, IN p_id_paralelo INT, IN p_nombre VARCHAR(10),
    IN p_cupo_maximo INT, IN p_id_docente INT, IN p_id_gestion INT
)
BEGIN
    UPDATE paralelo
    SET nombre = p_nombre, cupo_maximo = p_cupo_maximo, id_docente = p_id_docente, id_gestion = p_id_gestion
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_paralelo$$
CREATE PROCEDURE sp_eliminar_paralelo(IN p_id_materia INT, IN p_id_paralelo INT)
BEGIN
    DELETE FROM paralelo WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

-- 7. PLAN ESTUDIO
DROP PROCEDURE IF EXISTS sp_crear_plan_estudio$$
CREATE PROCEDURE sp_crear_plan_estudio(IN p_nombre VARCHAR(100), IN p_id_carrera INT)
BEGIN
    INSERT INTO plan_estudio (nombre, id_carrera) VALUES (p_nombre, p_id_carrera);
    SELECT LAST_INSERT_ID() AS id_plan;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_planes_estudio$$
CREATE PROCEDURE sp_obtener_planes_estudio()
BEGIN
    SELECT * FROM plan_estudio;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_plan_estudio_por_id$$
CREATE PROCEDURE sp_obtener_plan_estudio_por_id(IN p_id_plan INT)
BEGIN
    SELECT * FROM plan_estudio WHERE id_plan = p_id_plan;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_plan_estudio$$
CREATE PROCEDURE sp_actualizar_plan_estudio(IN p_id_plan INT, IN p_nombre VARCHAR(100), IN p_id_carrera INT)
BEGIN
    UPDATE plan_estudio SET nombre = p_nombre, id_carrera = p_id_carrera WHERE id_plan = p_id_plan;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_plan_estudio$$
CREATE PROCEDURE sp_eliminar_plan_estudio(IN p_id_plan INT)
BEGIN
    DELETE FROM plan_estudio WHERE id_plan = p_id_plan;
END$$

-- 8. PLAN MATERIA & PREREQUISITO
DROP PROCEDURE IF EXISTS sp_crear_plan_materia$$
CREATE PROCEDURE sp_crear_plan_materia(IN p_id_plan INT, IN p_id_materia INT, IN p_semestre INT)
BEGIN
    INSERT INTO plan_materia (id_plan, id_materia, semestre) VALUES (p_id_plan, p_id_materia, p_semestre);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_plan_materias$$
CREATE PROCEDURE sp_obtener_plan_materias()
BEGIN
    SELECT * FROM plan_materia;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_materias_por_plan$$
CREATE PROCEDURE sp_obtener_materias_por_plan(IN p_id_plan INT)
BEGIN
    SELECT * FROM plan_materia WHERE id_plan = p_id_plan;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_plan_materia$$
CREATE PROCEDURE sp_actualizar_plan_materia(IN p_id_plan INT, IN p_id_materia INT, IN p_semestre INT)
BEGIN
    UPDATE plan_materia SET semestre = p_semestre WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_plan_materia$$
CREATE PROCEDURE sp_eliminar_plan_materia(IN p_id_plan INT, IN p_id_materia INT)
BEGIN
    DELETE FROM plan_materia WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

DROP PROCEDURE IF EXISTS sp_crear_prerequisito$$
CREATE PROCEDURE sp_crear_prerequisito(IN p_id_plan INT, IN p_id_materia INT, IN p_id_materia_req INT)
BEGIN
    INSERT INTO prerequisito (id_plan, id_materia, id_materia_req) VALUES (p_id_plan, p_id_materia, p_id_materia_req);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_prerequisitos$$
CREATE PROCEDURE sp_obtener_prerequisitos()
BEGIN
    SELECT * FROM prerequisito;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_prerequisitos_materia$$
CREATE PROCEDURE sp_obtener_prerequisitos_materia(IN p_id_plan INT, IN p_id_materia INT)
BEGIN
    SELECT * FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_prerequisito$$
CREATE PROCEDURE sp_actualizar_prerequisito(IN p_id_plan INT, IN p_id_materia INT, IN p_old_req INT, IN p_new_req INT)
BEGIN
    UPDATE prerequisito SET id_materia_req = p_new_req WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_old_req;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_prerequisito$$
CREATE PROCEDURE sp_eliminar_prerequisito(IN p_id_plan INT, IN p_id_materia INT, IN p_id_materia_req INT)
BEGIN
    DELETE FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_id_materia_req;
END$$

-- 9. SE CURSA
DROP PROCEDURE IF EXISTS sp_crear_se_cursa$$
CREATE PROCEDURE sp_crear_se_cursa(IN p_id_materia INT, IN p_id_paralelo INT, IN p_id_aula INT, IN p_id_horario INT)
BEGIN
    INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) VALUES (p_id_materia, p_id_paralelo, p_id_aula, p_id_horario);
END$$

DROP PROCEDURE IF EXISTS sp_obtener_se_cursa$$
CREATE PROCEDURE sp_obtener_se_cursa()
BEGIN
    SELECT * FROM se_cursa;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_se_cursa_por_paralelo$$
CREATE PROCEDURE sp_obtener_se_cursa_por_paralelo(IN p_id_materia INT, IN p_id_paralelo INT)
BEGIN
    SELECT * FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_se_cursa$$
CREATE PROCEDURE sp_actualizar_se_cursa(
    IN p_id_materia INT, IN p_id_paralelo INT, IN p_old_aula INT, IN p_old_horario INT,
    IN p_new_aula INT, IN p_new_horario INT
)
BEGIN
    UPDATE se_cursa SET id_aula = p_new_aula, id_horario = p_new_horario
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_old_aula AND id_horario = p_old_horario;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_se_cursa$$
CREATE PROCEDURE sp_eliminar_se_cursa(IN p_id_materia INT, IN p_id_paralelo INT, IN p_id_aula INT, IN p_id_horario INT)
BEGIN
    DELETE FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_id_aula AND id_horario = p_id_horario;
END$$

-- 10. CRITERIOS Y NOTAS
DROP PROCEDURE IF EXISTS sp_crear_criterio$$
CREATE PROCEDURE sp_crear_criterio(IN p_id_materia INT, IN p_id_paralelo INT, IN p_nombre VARCHAR(50), IN p_ponderacion FLOAT)
BEGIN
    INSERT INTO criterio_evaluacion (id_materia, id_paralelo, nombre, ponderacion) VALUES (p_id_materia, p_id_paralelo, p_nombre, p_ponderacion);
    SELECT LAST_INSERT_ID() AS id_criterio;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_criterios_paralelo$$
CREATE PROCEDURE sp_obtener_criterios_paralelo(IN p_id_materia INT, IN p_id_paralelo INT)
BEGIN
    SELECT * FROM criterio_evaluacion WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_criterio$$
CREATE PROCEDURE sp_actualizar_criterio(IN p_id_criterio INT, IN p_nombre VARCHAR(50), IN p_ponderacion FLOAT)
BEGIN
    UPDATE criterio_evaluacion SET nombre = p_nombre, ponderacion = p_ponderacion WHERE id_criterio = p_id_criterio;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_criterio$$
CREATE PROCEDURE sp_eliminar_criterio(IN p_id_criterio INT)
BEGIN
    DELETE FROM criterio_evaluacion WHERE id_criterio = p_id_criterio;
END$$

DROP PROCEDURE IF EXISTS sp_crear_nota$$
CREATE PROCEDURE sp_crear_nota(IN p_id_detalle INT, IN p_id_criterio INT, IN p_puntaje FLOAT)
BEGIN
    INSERT INTO nota (id_detalle, id_criterio, puntaje_obtenido) VALUES (p_id_detalle, p_id_criterio, p_puntaje);
    SELECT LAST_INSERT_ID() AS id_nota;
END$$

DROP PROCEDURE IF EXISTS sp_obtener_notas_detalle$$
CREATE PROCEDURE sp_obtener_notas_detalle(IN p_id_detalle INT)
BEGIN
    SELECT * FROM nota WHERE id_detalle = p_id_detalle;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_nota$$
CREATE PROCEDURE sp_actualizar_nota(IN p_id_nota INT, IN p_puntaje FLOAT)
BEGIN
    UPDATE nota SET puntaje_obtenido = p_puntaje WHERE id_nota = p_id_nota;
END$$

DROP PROCEDURE IF EXISTS sp_eliminar_nota$$
CREATE PROCEDURE sp_eliminar_nota(IN p_id_nota INT)
BEGIN
    DELETE FROM nota WHERE id_nota = p_id_nota;
END$$

DELIMITER ;
