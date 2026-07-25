DELIMITER //

-- CREATE
CREATE PROCEDURE sp_crear_plan_estudio(
    IN p_nombre VARCHAR(100),
    IN p_id_carrera INT
)
BEGIN
    INSERT INTO PLAN_ESTUDIO (nombre, id_carrera) VALUES (p_nombre, p_id_carrera);
    SELECT LAST_INSERT_ID() AS id_plan;
END //

-- READ
CREATE PROCEDURE sp_obtener_planes_estudio()
BEGIN
    SELECT p.id_plan, p.nombre, p.id_carrera, c.nombre AS carrera 
    FROM PLAN_ESTUDIO p
    JOIN CARRERA c ON p.id_carrera = c.id_carrera;
END //

-- READ ONE
CREATE PROCEDURE sp_obtener_plan_estudio_por_id(IN p_id_plan INT)
BEGIN
    SELECT id_plan, nombre, id_carrera FROM PLAN_ESTUDIO WHERE id_plan = p_id_plan;
END //

-- UPDATE
CREATE PROCEDURE sp_actualizar_plan_estudio(
    IN p_id_plan INT,
    IN p_nombre VARCHAR(100),
    IN p_id_carrera INT
)
BEGIN
    UPDATE PLAN_ESTUDIO 
    SET nombre = p_nombre, id_carrera = p_id_carrera 
    WHERE id_plan = p_id_plan;
END //

-- DELETE
CREATE PROCEDURE sp_eliminar_plan_estudio(IN p_id_plan INT)
BEGIN
    DELETE FROM PLAN_ESTUDIO WHERE id_plan = p_id_plan;
END //

DELIMITER ;