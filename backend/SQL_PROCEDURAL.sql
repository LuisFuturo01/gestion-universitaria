-- Esta verificará que el estudiante exista.

DELIMITER $$

CREATE FUNCTION fn_existe_estudiante(
    p_id_estudiante INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM ESTUDIANTE
    WHERE id_persona = p_id_estudiante;

    RETURN v_existe > 0;

END $$

DELIMITER ;

SELECT fn_existe_estudiante(1); -- Devuelve 1

SELECT fn_existe_estudiante(100); -- Devuelve 0

-- Esta verificará que la gestión exista.

DELIMITER $$

CREATE FUNCTION fn_existe_gestion(
    p_id_gestion INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM GESTION
    WHERE id_gestion=p_id_gestion;

    RETURN v_existe>0;

END $$

DELIMITER ;

SELECT fn_existe_gestion(1); -- Devuelve 1  
SELECT fn_existe_gestion(100); -- Devuelve 0


-- Esta verificará que la materia exista.
DELIMITER $$
CREATE FUNCTION fn_existe_materia(
    p_id_materia INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM MATERIA
    WHERE id_materia=p_id_materia;

    RETURN v_existe>0;

END $$

DELIMITER ;

SELECT fn_existe_materia(1); -- Devuelve 1
SELECT fn_existe_materia(100); -- Devuelve 0

-- Esta verificará que el paralelo exista.

DELIMITER $$

CREATE FUNCTION fn_existe_paralelo(
    p_id_materia INT,
    p_id_paralelo INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM PARALELO
    WHERE id_materia=p_id_materia
    AND id_paralelo=p_id_paralelo;

    RETURN v_existe>0;

END $$

DELIMITER ;

SELECT fn_existe_paralelo(3,1);

SELECT fn_existe_paralelo(4,2);


-- Esta verificará que el cupo del paralelo esté disponible.
DELIMITER $$

CREATE FUNCTION fn_cupo_disponible(
    p_id_materia INT,
    p_id_paralelo INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_max INT;
    DECLARE v_actual INT;

    SELECT cupo_maximo, cupo_actual
    INTO v_max, v_actual
    FROM PARALELO
    WHERE id_materia = p_id_materia
    AND id_paralelo = p_id_paralelo;

    RETURN v_actual < v_max;

END $$

DELIMITER ;

SELECT fn_cupo_disponible(3,1);  


-- Esta verificará que el estudiante haya aprobado los prerrequisitos de la materia.    
DELIMITER $$

CREATE FUNCTION fn_tiene_prerrequisitos(
    p_id_estudiante INT,
    p_id_plan INT,
    p_id_materia INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_total INT DEFAULT 0;
    DECLARE v_aprobadas INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_total
    FROM PREREQUISITO
    WHERE id_plan = p_id_plan
    AND id_materia = p_id_materia;

    IF v_total = 0 THEN
        RETURN TRUE;
    END IF;

    SELECT COUNT(*)
    INTO v_aprobadas
    FROM PREREQUISITO pr
    INNER JOIN DETALLE_INSCRIPCION di
        ON pr.id_materia_req = di.id_materia
    INNER JOIN INSCRIPCION i
        ON di.id_inscripcion = i.id_inscripcion
    WHERE pr.id_plan = p_id_plan
    AND pr.id_materia = p_id_materia
    AND i.id_estudiante = p_id_estudiante
    AND di.nota_final >= 51;

    RETURN v_total = v_aprobadas;

END $$

DELIMITER ;

SELECT fn_tiene_prerrequisitos(1,1,4); -- Debe devolver 1

-- Evita Inscripciones duplicadas de un estudiante en una materia específica dentro de una gestión específica.  

DELIMITER $$

CREATE FUNCTION fn_ya_inscrito(
    p_id_estudiante INT,
    p_id_gestion INT,
    p_id_materia INT
)
RETURNS BOOLEAN
DETERMINISTIC

BEGIN

    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM INSCRIPCION i
    INNER JOIN DETALLE_INSCRIPCION d
        ON i.id_inscripcion=d.id_inscripcion
    WHERE i.id_estudiante=p_id_estudiante
    AND i.id_gestion=p_id_gestion
    AND d.id_materia=p_id_materia;

    RETURN v_existe>0;

END $$

DELIMITER ;

SELECT fn_ya_inscrito(1,1,3); --Debe devolver 1

--------------TRIGGERS-----------------


-- Cuando un estudiante se inscribe
DELIMITER $$

CREATE TRIGGER trg_aumentar_cupo

AFTER INSERT

ON DETALLE_INSCRIPCION

FOR EACH ROW

BEGIN

    UPDATE PARALELO

    SET cupo_actual=cupo_actual+1

    WHERE id_materia=NEW.id_materia

    AND id_paralelo=NEW.id_paralelo;

END $$

DELIMITER ;

--Cuando un estudiante se retira de una materia

DELIMITER $$

CREATE TRIGGER trg_disminuir_cupo

AFTER DELETE

ON DETALLE_INSCRIPCION

FOR EACH ROW

BEGIN

    UPDATE PARALELO

    SET cupo_actual=cupo_actual-1

    WHERE id_materia=OLD.id_materia

    AND id_paralelo=OLD.id_paralelo;

END $$

DELIMITER ;

-- Procedimiento: sp_realizar_inscripcion

-- Este procedimiento hará lo siguiente:

-- Inicia una transacción.
-- Verifica que exista el estudiante.
-- Verifica que exista la gestión.
-- Verifica que exista la materia.
-- Verifica que exista el paralelo.
-- Verifica que exista cupo.
-- Verifica que no esté inscrito.
-- Verifica los prerrequisitos.
-- Crea la cabecera de inscripción si no existe.
-- Inserta el detalle.
-- Hace COMMIT.
-- Si ocurre un error, hace ROLLBACK.

DELIMITER $$

CREATE PROCEDURE sp_realizar_inscripcion(

IN p_id_estudiante INT,
IN p_id_gestion INT,
IN p_id_plan INT,
IN p_id_materia INT,
IN p_id_paralelo INT

)

BEGIN

DECLARE v_id_inscripcion INT DEFAULT NULL;
DECLARE v_id_detalle INT;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
RESIGNAL;
END;

START TRANSACTION;

IF NOT fn_existe_estudiante(p_id_estudiante) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='El estudiante no existe.';
END IF;

IF NOT fn_existe_gestion(p_id_gestion) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='La gestión no existe.';
END IF;

IF NOT fn_existe_materia(p_id_materia) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='La materia no existe.';
END IF;

IF NOT fn_existe_paralelo(p_id_materia,p_id_paralelo) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='El paralelo no existe.';
END IF;

IF NOT fn_cupo_disponible(p_id_materia,p_id_paralelo) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='No existen cupos disponibles.';
END IF;

IF fn_ya_inscrito(p_id_estudiante,p_id_gestion,p_id_materia) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='El estudiante ya está inscrito en esa materia.';
END IF;

IF NOT fn_tiene_prerrequisitos(p_id_estudiante,p_id_plan,p_id_materia) THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='No cumple los prerrequisitos.';
END IF;

SELECT id_inscripcion
INTO v_id_inscripcion
FROM INSCRIPCION
WHERE id_estudiante=p_id_estudiante
AND id_gestion=p_id_gestion
LIMIT 1;

IF v_id_inscripcion IS NULL THEN

SELECT IFNULL(MAX(id_inscripcion),1000)+1
INTO v_id_inscripcion
FROM INSCRIPCION;

INSERT INTO INSCRIPCION(

id_inscripcion,
id_estudiante,
id_gestion,
fecha_registro

)

VALUES(

v_id_inscripcion,
p_id_estudiante,
p_id_gestion,
CURDATE()

);

END IF;

SELECT IFNULL(MAX(id_detalle),0)+1
INTO v_id_detalle
FROM DETALLE_INSCRIPCION;

INSERT INTO DETALLE_INSCRIPCION(

id_detalle,
id_inscripcion,
id_materia,
id_paralelo,
estado,
nota_final

)

VALUES(

v_id_detalle,
v_id_inscripcion,
p_id_materia,
p_id_paralelo,
'Inscrito',
0

);

COMMIT;

END$$

DELIMITER ;

-- Manera de probarlo
INSERT INTO MATERIA
VALUES
(
5,
'INF-450',
'Minería de Datos',
6
);

INSERT INTO PLAN_MATERIA
VALUES
(
1,
5,
6
);

INSERT INTO PARALELO
(
id_materia,
id_paralelo,
nombre,
cupo_maximo,
cupo_actual,
id_docente,
id_gestion
)
VALUES
(
5,
1,
'A',
40,
0,
3,
1
);

CALL sp_realizar_inscripcion(
1,
1,
1,
5,
1
);


-- Procedimiento para retirar una inscripción
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_retirar_inscripcion$$

CREATE PROCEDURE sp_retirar_inscripcion(

IN p_id_detalle INT

)

BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
RESIGNAL;
END;

START TRANSACTION;

IF NOT EXISTS(
SELECT 1
FROM DETALLE_INSCRIPCION
WHERE id_detalle=p_id_detalle
) THEN

SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='La inscripción no existe.';

END IF;

UPDATE DETALLE_INSCRIPCION
SET estado='Abandono'
WHERE id_detalle=p_id_detalle;

COMMIT;

END$$

DELIMITER ;

-- Para probar
CALL sp_retirar_inscripcion(2);

