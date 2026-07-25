DELIMITER //

-- CREATE
CREATE PROCEDURE sp_crear_nota(
    IN p_id_detalle INT,
    IN p_id_criterio INT,
    IN p_puntaje_obtenido FLOAT
)
BEGIN
    INSERT INTO NOTA (id_detalle, id_criterio, puntaje_obtenido) 
    VALUES (p_id_detalle, p_id_criterio, p_puntaje_obtenido);
    SELECT LAST_INSERT_ID() AS id_nota;
END //

-- READ (Obtener todas las notas de una inscripción específica)
CREATE PROCEDURE sp_obtener_notas_detalle(
    IN p_id_detalle INT
)
BEGIN
    SELECT n.id_nota, c.nombre AS criterio, c.ponderacion, n.puntaje_obtenido
    FROM NOTA n
    JOIN CRITERIO_EVALUACION c ON n.id_criterio = c.id_criterio
    WHERE n.id_detalle = p_id_detalle;
END //

-- UPDATE
CREATE PROCEDURE sp_actualizar_nota(
    IN p_id_nota INT,
    IN p_puntaje_obtenido FLOAT
)
BEGIN
    UPDATE NOTA 
    SET puntaje_obtenido = p_puntaje_obtenido 
    WHERE id_nota = p_id_nota;
END //

-- DELETE
CREATE PROCEDURE sp_eliminar_nota(IN p_id_nota INT)
BEGIN
    DELETE FROM NOTA WHERE id_nota = p_id_nota;
END //

DELIMITER ;