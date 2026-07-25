DELIMITER //

-- CREATE (Insertar Materia)
CREATE PROCEDURE sp_crear_materia(
    IN p_sigla VARCHAR(15),
    IN p_nombre VARCHAR(100),
    IN p_creditos INT
)
BEGIN
    INSERT INTO MATERIA (sigla, nombre, creditos) 
    VALUES (p_sigla, p_nombre, p_creditos);
    SELECT LAST_INSERT_ID() AS id_materia;
END //

-- READ (Obtener todas las Materias)
CREATE PROCEDURE sp_obtener_materias()
BEGIN
    SELECT id_materia, sigla, nombre, creditos 
    FROM MATERIA;
END //

-- READ ONE (Obtener una Materia por ID)
CREATE PROCEDURE sp_obtener_materia_por_id(
    IN p_id_materia INT
)
BEGIN
    SELECT id_materia, sigla, nombre, creditos 
    FROM MATERIA 
    WHERE id_materia = p_id_materia;
END //

-- UPDATE (Actualizar Materia)
CREATE PROCEDURE sp_actualizar_materia(
    IN p_id_materia INT,
    IN p_sigla VARCHAR(15),
    IN p_nombre VARCHAR(100),
    IN p_creditos INT
)
BEGIN
    UPDATE MATERIA 
    SET sigla = p_sigla, 
        nombre = p_nombre, 
        creditos = p_creditos 
    WHERE id_materia = p_id_materia;
END //

-- DELETE (Eliminar Materia)
CREATE PROCEDURE sp_eliminar_materia(
    IN p_id_materia INT
)
BEGIN
    DELETE FROM MATERIA 
    WHERE id_materia = p_id_materia;
END //

DELIMITER ;