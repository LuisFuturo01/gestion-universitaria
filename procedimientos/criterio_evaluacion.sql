DELIMITER //

-- CREATE
CREATE PROCEDURE sp_crear_criterio(
    IN p_id_materia INT,
    IN p_id_paralelo INT,
    IN p_nombre VARCHAR(50),
    IN p_ponderacion FLOAT
)
BEGIN
    INSERT INTO CRITERIO_EVALUACION (id_materia, id_paralelo, nombre, ponderacion) 
    VALUES (p_id_materia, p_id_paralelo, p_nombre, p_ponderacion);
    SELECT LAST_INSERT_ID() AS id_criterio;
END //

-- READ (Obtener criterios de un paralelo específico)
CREATE PROCEDURE sp_obtener_criterios_paralelo(
    IN p_id_materia INT,
    IN p_id_paralelo INT
)
BEGIN
    SELECT id_criterio, nombre, ponderacion 
    FROM CRITERIO_EVALUACION
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END //

-- UPDATE
CREATE PROCEDURE sp_actualizar_criterio(
    IN p_id_criterio INT,
    IN p_nombre VARCHAR(50),
    IN p_ponderacion FLOAT
)
BEGIN
    UPDATE CRITERIO_EVALUACION 
    SET nombre = p_nombre, ponderacion = p_ponderacion 
    WHERE id_criterio = p_id_criterio;
END //

-- DELETE
CREATE PROCEDURE sp_eliminar_criterio(IN p_id_criterio INT)
BEGIN
    DELETE FROM CRITERIO_EVALUACION WHERE id_criterio = p_id_criterio;
END //

DELIMITER ;