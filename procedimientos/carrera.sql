DELIMITER //

-- CREATE
CREATE PROCEDURE sp_crear_carrera(
    IN p_nombre VARCHAR(100)
)
BEGIN
    INSERT INTO CARRERA (nombre) VALUES (p_nombre);
    SELECT LAST_INSERT_ID() AS id_carrera;
END //

-- READ
CREATE PROCEDURE sp_obtener_carreras()
BEGIN
    SELECT id_carrera, nombre FROM CARRERA;
END //

-- READ ONE
CREATE PROCEDURE sp_obtener_carrera_por_id(IN p_id_carrera INT)
BEGIN
    SELECT id_carrera, nombre FROM CARRERA WHERE id_carrera = p_id_carrera;
END //

-- UPDATE
CREATE PROCEDURE sp_actualizar_carrera(
    IN p_id_carrera INT,
    IN p_nombre VARCHAR(100)
)
BEGIN
    UPDATE CARRERA SET nombre = p_nombre WHERE id_carrera = p_id_carrera;
END //

-- DELETE
CREATE PROCEDURE sp_eliminar_carrera(IN p_id_carrera INT)
BEGIN
    DELETE FROM CARRERA WHERE id_carrera = p_id_carrera;
END //

DELIMITER ;