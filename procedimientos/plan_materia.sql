DELIMITER //

-- CREATE
CREATE PROCEDURE sp_crear_plan_materia(
    IN p_id_plan INT,
    IN p_id_materia INT,
    IN p_semestre INT
)
BEGIN
    INSERT INTO PLAN_MATERIA (id_plan, id_materia, semestre) 
    VALUES (p_id_plan, p_id_materia, p_semestre);
    SELECT p_id_plan AS id_plan, p_id_materia AS id_materia;
END //

-- READ (Obtener todas las materias de un plan específico)
CREATE PROCEDURE sp_obtener_materias_por_plan(IN p_id_plan INT)
BEGIN
    SELECT pm.id_plan, pm.id_materia, m.sigla, m.nombre AS materia, pm.semestre
    FROM PLAN_MATERIA pm
    JOIN MATERIA m ON pm.id_materia = m.id_materia
    WHERE pm.id_plan = p_id_plan
    ORDER BY pm.semestre ASC;
END //

-- UPDATE (Solo se actualiza el semestre)
CREATE PROCEDURE sp_actualizar_plan_materia(
    IN p_id_plan INT,
    IN p_id_materia INT,
    IN p_semestre INT
)
BEGIN
    UPDATE PLAN_MATERIA 
    SET semestre = p_semestre 
    WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END //

-- DELETE
CREATE PROCEDURE sp_eliminar_plan_materia(
    IN p_id_plan INT,
    IN p_id_materia INT
)
BEGIN
    DELETE FROM PLAN_MATERIA 
    WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END //

DELIMITER ;