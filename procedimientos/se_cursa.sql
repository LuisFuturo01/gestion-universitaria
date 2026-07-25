DELIMITER //

-- CREATE (Asignar un aula y horario a un paralelo)
CREATE PROCEDURE sp_crear_se_cursa(
    IN p_id_materia INT,
    IN p_id_paralelo INT,
    IN p_id_aula INT,
    IN p_id_horario INT
)
BEGIN
    INSERT INTO SE_CURSA (id_materia, id_paralelo, id_aula, id_horario) 
    VALUES (p_id_materia, p_id_paralelo, p_id_aula, p_id_horario);
END //

-- READ (Obtener todas las asignaciones)
CREATE PROCEDURE sp_obtener_se_cursa()
BEGIN
    SELECT sc.id_materia, sc.id_paralelo, sc.id_aula, a.nombre AS nombre_aula, sc.id_horario, h.dia, h.hora_inicio, h.hora_fin
    FROM SE_CURSA sc
    JOIN AULA a ON sc.id_aula = a.id_aula
    JOIN HORARIO h ON sc.id_horario = h.id_horario;
END //

-- READ (Obtener asignaciones por materia y paralelo específico)
CREATE PROCEDURE sp_obtener_se_cursa_por_paralelo(
    IN p_id_materia INT,
    IN p_id_paralelo INT
)
BEGIN
    SELECT sc.id_aula, a.nombre AS nombre_aula, sc.id_horario, h.dia, h.hora_inicio, h.hora_fin
    FROM SE_CURSA sc
    JOIN AULA a ON sc.id_aula = a.id_aula
    JOIN HORARIO h ON sc.id_horario = h.id_horario
    WHERE sc.id_materia = p_id_materia AND sc.id_paralelo = p_id_paralelo;
END //

-- UPDATE (Cambiar de aula u horario a un paralelo existente)
CREATE PROCEDURE sp_actualizar_se_cursa(
    IN p_id_materia INT,
    IN p_id_paralelo INT,
    IN p_old_id_aula INT,
    IN p_old_id_horario INT,
    IN p_new_id_aula INT,
    IN p_new_id_horario INT
)
BEGIN
    UPDATE SE_CURSA 
    SET id_aula = p_new_id_aula, 
        id_horario = p_new_id_horario
    WHERE id_materia = p_id_materia 
      AND id_paralelo = p_id_paralelo 
      AND id_aula = p_old_id_aula 
      AND id_horario = p_old_id_horario;
END //

-- DELETE (Eliminar una asignación de horario/aula)
CREATE PROCEDURE sp_eliminar_se_cursa(
    IN p_id_materia INT,
    IN p_id_paralelo INT,
    IN p_id_aula INT,
    IN p_id_horario INT
)
BEGIN
    DELETE FROM SE_CURSA 
    WHERE id_materia = p_id_materia 
      AND id_paralelo = p_id_paralelo 
      AND id_aula = p_id_aula 
      AND id_horario = p_id_horario;
END //

DELIMITER ;