DELIMITER //

-- CREATE (Insertar Aula)
CREATE PROCEDURE sp_crear_aula(
    IN p_nombre VARCHAR(50),
    IN p_ubicacion VARCHAR(100),
    IN p_capacidad INT
)
BEGIN
    INSERT INTO AULA (nombre, ubicacion, capacidad) 
    VALUES (p_nombre, p_ubicacion, p_capacidad);
    SELECT LAST_INSERT_ID() AS id_aula;
END //

-- READ (Obtener todas las Aulas)
CREATE PROCEDURE sp_obtener_aulas()
BEGIN
    SELECT id_aula, nombre, ubicacion, capacidad 
    FROM AULA;
END //

-- READ ONE (Obtener un Aula por ID)
CREATE PROCEDURE sp_obtener_aula_por_id(
    IN p_id_aula INT
)
BEGIN
    SELECT id_aula, nombre, ubicacion, capacidad 
    FROM AULA 
    WHERE id_aula = p_id_aula;
END //

-- UPDATE (Actualizar Aula)
CREATE PROCEDURE sp_actualizar_aula(
    IN p_id_aula INT,
    IN p_nombre VARCHAR(50),
    IN p_ubicacion VARCHAR(100),
    IN p_capacidad INT
)
BEGIN
    UPDATE AULA 
    SET nombre = p_nombre, 
        ubicacion = p_ubicacion, 
        capacidad = p_capacidad 
    WHERE id_aula = p_id_aula;
END //

-- DELETE (Eliminar Aula)
CREATE PROCEDURE sp_eliminar_aula(
    IN p_id_aula INT
)
BEGIN
    DELETE FROM AULA 
    WHERE id_aula = p_id_aula;
END //

DELIMITER ;