DELIMITER //

-- CREATE (Insertar Paralelo)
CREATE PROCEDURE sp_crear_paralelo(
    IN p_id_materia INT,
    IN p_nombre VARCHAR(10),
    IN p_cupo_maximo INT,
    IN p_id_docente INT,
    IN p_id_gestion INT
)
BEGIN
    -- No insertamos cupo_actual porque la tabla lo define como 0 por defecto
    INSERT INTO PARALELO (id_materia, nombre, cupo_maximo, id_docente, id_gestion) 
    VALUES (p_id_materia, p_nombre, p_cupo_maximo, p_id_docente, p_id_gestion);
    SELECT p_id_materia AS id_materia, LAST_INSERT_ID() AS id_paralelo;
END //

-- READ (Obtener todos los Paralelos con el nombre de la materia)
CREATE PROCEDURE sp_obtener_paralelos()
BEGIN
    SELECT p.id_materia, m.nombre AS nombre_materia, p.id_paralelo, p.nombre AS paralelo, 
           p.cupo_maximo, p.cupo_actual, p.id_docente, p.id_gestion
    FROM PARALELO p
    JOIN MATERIA m ON p.id_materia = m.id_materia;
END //

-- UPDATE (Actualizar Paralelo)
CREATE PROCEDURE sp_actualizar_paralelo(
    IN p_id_materia INT,
    IN p_id_paralelo INT,
    IN p_nuevo_nombre VARCHAR(10),
    IN p_nuevo_cupo_max INT,
    IN p_id_docente INT,
    IN p_id_gestion INT
)
BEGIN
    UPDATE PARALELO 
    SET nombre = p_nuevo_nombre, 
        cupo_maximo = p_nuevo_cupo_max, 
        id_docente = p_id_docente, 
        id_gestion = p_id_gestion
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END //

-- DELETE (Eliminar Paralelo)
CREATE PROCEDURE sp_eliminar_paralelo(
    IN p_id_materia INT,
    IN p_id_paralelo INT
)
BEGIN
    DELETE FROM PARALELO 
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END //

DELIMITER ;