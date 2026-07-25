DELIMITER //

-- CREATE (Insertar Horario)
CREATE PROCEDURE sp_crear_horario(
    IN p_dia VARCHAR(15),
    IN p_hora_inicio TIME,
    IN p_hora_fin TIME
)
BEGIN
    INSERT INTO HORARIO (dia, hora_inicio, hora_fin) 
    VALUES (p_dia, p_hora_inicio, p_hora_fin);
    SELECT LAST_INSERT_ID() AS id_horario;
END //

-- READ (Obtener todos los Horarios)
CREATE PROCEDURE sp_obtener_horarios()
BEGIN
    SELECT id_horario, dia, hora_inicio, hora_fin 
    FROM HORARIO;
END //

-- READ ONE (Obtener un Horario por ID)
CREATE PROCEDURE sp_obtener_horario_por_id(
    IN p_id_horario INT
)
BEGIN
    SELECT id_horario, dia, hora_inicio, hora_fin 
    FROM HORARIO 
    WHERE id_horario = p_id_horario;
END //

-- UPDATE (Actualizar Horario)
CREATE PROCEDURE sp_actualizar_horario(
    IN p_id_horario INT,
    IN p_dia VARCHAR(15),
    IN p_hora_inicio TIME,
    IN p_hora_fin TIME
)
BEGIN
    UPDATE HORARIO 
    SET dia = p_dia, 
        hora_inicio = p_hora_inicio, 
        hora_fin = p_hora_fin 
    WHERE id_horario = p_id_horario;
END //

-- DELETE (Eliminar Horario)
CREATE PROCEDURE sp_eliminar_horario(
    IN p_id_horario INT
)
BEGIN
    DELETE FROM HORARIO 
    WHERE id_horario = p_id_horario;
END //

DELIMITER ;