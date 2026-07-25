DELIMITER //

-- CREATE
CREATE PROCEDURE sp_crear_prerequisito(
    IN p_id_plan INT,
    IN p_id_materia INT,
    IN p_id_materia_req INT
)
BEGIN
    INSERT INTO PREREQUISITO (id_plan, id_materia, id_materia_req) 
    VALUES (p_id_plan, p_id_materia, p_id_materia_req);
    SELECT p_id_plan AS id_plan, p_id_materia AS id_materia, p_id_materia_req AS id_materia_req;
END //

-- READ (Obtener los prerequisitos de una materia específica en un plan)
CREATE PROCEDURE sp_obtener_prerequisitos_materia(
    IN p_id_plan INT,
    IN p_id_materia INT
)
BEGIN
    SELECT pre.id_materia_req, m.sigla, m.nombre AS nombre_prerequisito
    FROM PREREQUISITO pre
    JOIN MATERIA m ON pre.id_materia_req = m.id_materia
    WHERE pre.id_plan = p_id_plan AND pre.id_materia = p_id_materia;
END //

-- UPDATE (Cambiar un prerequisito por otro)
CREATE PROCEDURE sp_actualizar_prerequisito(
    IN p_id_plan INT,
    IN p_id_materia INT,
    IN p_old_materia_req INT,
    IN p_new_materia_req INT
)
BEGIN
    UPDATE PREREQUISITO 
    SET id_materia_req = p_new_materia_req
    WHERE id_plan = p_id_plan 
      AND id_materia = p_id_materia 
      AND id_materia_req = p_old_materia_req;
END //

-- DELETE
CREATE PROCEDURE sp_eliminar_prerequisito(
    IN p_id_plan INT,
    IN p_id_materia INT,
    IN p_id_materia_req INT
)
BEGIN
    DELETE FROM PREREQUISITO 
    WHERE id_plan = p_id_plan 
      AND id_materia = p_id_materia 
      AND id_materia_req = p_id_materia_req;
END //

DELIMITER ;