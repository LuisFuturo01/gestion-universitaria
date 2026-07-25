DELIMITER //

-- CREATE (Insertar Gestion)
CREATE PROCEDURE sp_crear_gestion(
    IN p_periodo VARCHAR(20)
)
BEGIN
    INSERT INTO GESTION (periodo) 
    VALUES (p_periodo);
    SELECT LAST_INSERT_ID() AS id_gestion;
END //

-- READ (Obtener todas las Gestiones)
CREATE PROCEDURE sp_obtener_gestiones()
BEGIN
    SELECT id_gestion, periodo 
    FROM GESTION;
END //

-- UPDATE (Actualizar Gestion)
CREATE PROCEDURE sp_actualizar_gestion(
    IN p_id_gestion INT,
    IN p_periodo VARCHAR(20)
)
BEGIN
    UPDATE GESTION 
    SET periodo = p_periodo
    WHERE id_gestion = p_id_gestion;
END //

-- DELETE (Eliminar Gestion)
CREATE PROCEDURE sp_eliminar_gestion(
    IN p_id_gestion INT
)
BEGIN
    DELETE FROM GESTION 
    WHERE id_gestion = p_id_gestion;
END //

DELIMITER ;