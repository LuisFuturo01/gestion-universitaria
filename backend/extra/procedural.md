# Análisis de Objetos de Programación - Base de Datos sistemaacademico

## 1. FUNCIONES (13)

### 1.1 fn_cupo_disponible
Verifica si hay cupo disponible en un paralelo específico.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_cupo_disponible` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_max INT;
    DECLARE v_actual INT;
    SELECT cupo_maximo, cupo_actual INTO v_max, v_actual FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
    RETURN v_actual < v_max;
END$$
```

### 1.2 fn_existe_estudiante
Valida la existencia de un estudiante por su ID de persona.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_estudiante` (`p_id_estudiante` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM ESTUDIANTE WHERE id_persona = p_id_estudiante;
    RETURN v_existe > 0;
END$$
```

### 1.3 fn_existe_gestion
Valida la existencia de una gestión académica.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_gestion` (`p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM GESTION WHERE id_gestion = p_id_gestion;
    RETURN v_existe > 0;
END$$
```

### 1.4 fn_existe_materia
Valida la existencia de una materia.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_materia` (`p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM MATERIA WHERE id_materia = p_id_materia;
    RETURN v_existe > 0;
END$$
```

### 1.5 fn_existe_paralelo
Valida la existencia de un paralelo específico.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_paralelo` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
    RETURN v_existe > 0;
END$$
```

### 1.6 fn_tiene_prerrequisitos
Verifica si un estudiante cumple con todos los prerrequisitos de una materia (nota ≥ 51).

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_tiene_prerrequisitos` (`p_id_estudiante` INT, `p_id_plan` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_aprobadas INT DEFAULT 0;
    SELECT COUNT(*) INTO v_total FROM PREREQUISITO WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
    IF v_total = 0 THEN
        RETURN TRUE;
    END IF;
    SELECT COUNT(*) INTO v_aprobadas FROM PREREQUISITO pr 
    INNER JOIN DETALLE_INSCRIPCION di ON pr.id_materia_req = di.id_materia 
    INNER JOIN INSCRIPCION i ON di.id_inscripcion = i.id_inscripcion 
    WHERE pr.id_plan = p_id_plan AND pr.id_materia = p_id_materia AND i.id_estudiante = p_id_estudiante AND di.nota_final >= 51;
    RETURN v_total = v_aprobadas;
END$$
```

### 1.7 fn_ya_inscrito
Verifica si un estudiante ya está inscrito en una materia en una gestión específica.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_ya_inscrito` (`p_id_estudiante` INT, `p_id_gestion` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM INSCRIPCION i 
    INNER JOIN DETALLE_INSCRIPCION d ON i.id_inscripcion = d.id_inscripcion 
    WHERE i.id_estudiante = p_id_estudiante AND i.id_gestion = p_id_gestion AND d.id_materia = p_id_materia;
    RETURN v_existe > 0;
END$$
```

### 1.8 fn_aula_disponible
Verifica si un aula está disponible en un horario específico para una gestión.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_aula_disponible` (`p_id_aula` INT, `p_id_horario` INT, `p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    WHERE sc.id_aula = p_id_aula AND sc.id_horario = p_id_horario AND p.id_gestion = p_id_gestion;
    RETURN v_count = 0;
END$$
```

### 1.9 fn_calcular_nota_final
Calcula la nota final ponderada de un estudiante en un detalle de inscripción.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_calcular_nota_final` (`p_id_detalle` INT) RETURNS FLOAT DETERMINISTIC BEGIN
    DECLARE v_nota FLOAT;
    SELECT COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0)
    INTO v_nota
    FROM nota n
    JOIN criterio_evaluacion ce ON n.id_criterio = ce.id_criterio
    WHERE n.id_detalle = p_id_detalle;
    RETURN v_nota;
END$$
```

### 1.10 fn_extraer_numero_ci
Extrae solo los dígitos numéricos de un CI (elimina letras y caracteres especiales).

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_extraer_numero_ci` (`p_ci` VARCHAR(20)) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_numero VARCHAR(20) DEFAULT '';
    DECLARE v_char CHAR(1);
    DECLARE v_len INT;
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_done INT DEFAULT 0;
    
    SET v_len = CHAR_LENGTH(p_ci);
    
    WHILE v_i <= v_len AND v_done = 0 DO
        SET v_char = SUBSTRING(p_ci, v_i, 1);
        IF v_char REGEXP '[0-9]' THEN
            SET v_numero = CONCAT(v_numero, v_char);
        ELSE
            SET v_done = 1;
        END IF;
        SET v_i = v_i + 1;
    END WHILE;
    
    RETURN v_numero;
END$$
```

### 1.11 fn_generar_email
Genera un email único con formato username@fcpn.edu.bo (si existe, añade número).

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_generar_email` (`p_username` VARCHAR(50)) RETURNS VARCHAR(120) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_base VARCHAR(120);
    DECLARE v_final VARCHAR(120);
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_done INT DEFAULT 0;
    
    SET v_base = CONCAT(p_username, '@fcpn.edu.bo');
    SET v_final = v_base;
    
    WHILE v_done = 0 DO
        IF EXISTS (SELECT 1 FROM persona WHERE email = v_final) THEN
            SET v_contador = v_contador + 1;
            SET v_final = CONCAT(p_username, v_contador, '@fcpn.edu.bo');
        ELSE
            SET v_done = 1;
        END IF;
    END WHILE;
    
    RETURN v_final;
END$$
```

### 1.12 fn_generar_username
Genera username automático: [primera letra nombre] + [apellido paterno] + [primera letra apellido materno].

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_generar_username` (`p_nombres` VARCHAR(80), `p_apellidos` VARCHAR(80)) RETURNS VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_inicial_nombre CHAR(1);
    DECLARE v_apellido_paterno VARCHAR(40);
    DECLARE v_inicial_materno CHAR(1);
    DECLARE v_base VARCHAR(50);
    DECLARE v_final VARCHAR(50);
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_done INT DEFAULT 0;
    
    SET v_inicial_nombre = LOWER(LEFT(TRIM(p_nombres), 1));
    SET v_apellido_paterno = LOWER(SUBSTRING_INDEX(TRIM(p_apellidos), ' ', 1));
    
    IF LOCATE(' ', TRIM(p_apellidos)) > 0 THEN
        SET v_inicial_materno = LOWER(LEFT(SUBSTRING_INDEX(TRIM(p_apellidos), ' ', -1), 1));
        SET v_base = CONCAT(v_inicial_nombre, v_apellido_paterno, v_inicial_materno);
    ELSE
        SET v_base = CONCAT(v_inicial_nombre, v_apellido_paterno);
    END IF;
    
    SET v_final = v_base;
    
    WHILE v_done = 0 DO
        IF EXISTS (SELECT 1 FROM usuario WHERE username = v_final) THEN
            SET v_contador = v_contador + 1;
            SET v_final = CONCAT(v_base, v_contador);
        ELSE
            SET v_done = 1;
        END IF;
    END WHILE;
    
    RETURN v_final;
END$$
```

### 1.13 fn_nombre_completo
Concatena nombres y apellidos de una persona.

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_nombre_completo` (`p_id_persona` INT) RETURNS VARCHAR(200) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE v_nombre VARCHAR(200);
    SELECT CONCAT(nombres, ' ', apellidos) INTO v_nombre FROM persona WHERE id_persona = p_id_persona;
    RETURN v_nombre;
END$$
```

## 2. PROCEDIMIENTOS ALMACENADOS (65)

### 2.1 Procedimientos CRUD - Aula (5)
- `sp_crear_aula` - Crea un nuevo aula
- `sp_obtener_aulas` - Lista todas las aulas
- `sp_obtener_aula_por_id` - Obtiene un aula por ID
- `sp_actualizar_aula` - Actualiza datos de un aula
- `sp_eliminar_aula` - Elimina un aula

### 2.2 Procedimientos CRUD - Carrera (5)
- `sp_crear_carrera` - Crea una nueva carrera
- `sp_obtener_carreras` - Lista todas las carreras
- `sp_obtener_carrera_por_id` - Obtiene una carrera por ID
- `sp_actualizar_carrera` - Actualiza datos de una carrera
- `sp_eliminar_carrera` - Elimina una carrera

### 2.3 Procedimientos CRUD - Criterio Evaluación (4)
- `sp_crear_criterio` - Crea un nuevo criterio de evaluación
- `sp_obtener_criterios_paralelo` - Lista criterios de un paralelo
- `sp_actualizar_criterio` - Actualiza un criterio
- `sp_eliminar_criterio` - Elimina un criterio

### 2.4 Procedimientos CRUD - Gestión (4)
- `sp_crear_gestion` - Crea una nueva gestión
- `sp_obtener_gestiones` - Lista todas las gestiones
- `sp_actualizar_gestion` - Actualiza una gestión
- `sp_eliminar_gestion` - Elimina una gestión

### 2.5 Procedimientos CRUD - Horario (5)
- `sp_crear_horario` - Crea un nuevo horario
- `sp_obtener_horarios` - Lista todos los horarios
- `sp_obtener_horario_por_id` - Obtiene un horario por ID
- `sp_actualizar_horario` - Actualiza un horario
- `sp_eliminar_horario` - Elimina un horario

### 2.6 Procedimientos CRUD - Materia (5)
- `sp_crear_materia` - Crea una nueva materia
- `sp_obtener_materias` - Lista todas las materias
- `sp_obtener_materia_por_id` - Obtiene una materia por ID
- `sp_actualizar_materia` - Actualiza una materia
- `sp_eliminar_materia` - Elimina una materia

### 2.7 Procedimientos CRUD - Nota (4)
- `sp_crear_nota` - Crea una nueva nota
- `sp_obtener_notas_detalle` - Lista notas de un detalle de inscripción
- `sp_actualizar_nota` - Actualiza una nota
- `sp_eliminar_nota` - Elimina una nota

### 2.8 Procedimientos CRUD - Paralelo (4)
- `sp_crear_paralelo` - Crea un nuevo paralelo
- `sp_obtener_paralelos` - Lista todos los paralelos
- `sp_actualizar_paralelo` - Actualiza un paralelo
- `sp_eliminar_paralelo` - Elimina un paralelo

### 2.9 Procedimientos CRUD - Plan Estudio (5)
- `sp_crear_plan_estudio` - Crea un nuevo plan de estudio
- `sp_obtener_planes_estudio` - Lista todos los planes
- `sp_obtener_plan_estudio_por_id` - Obtiene un plan por ID
- `sp_actualizar_plan_estudio` - Actualiza un plan
- `sp_eliminar_plan_estudio` - Elimina un plan

### 2.10 Procedimientos CRUD - Plan Materia (5)
- `sp_crear_plan_materia` - Asigna una materia a un plan
- `sp_obtener_plan_materias` - Lista todas las asignaciones
- `sp_obtener_materias_por_plan` - Lista materias de un plan
- `sp_actualizar_plan_materia` - Actualiza una asignación
- `sp_eliminar_plan_materia` - Elimina una asignación

### 2.11 Procedimientos CRUD - Prerequisito (5)
- `sp_crear_prerequisito` - Crea un prerrequisito
- `sp_obtener_prerequisitos` - Lista todos los prerrequisitos
- `sp_obtener_prerequisitos_materia` - Lista prerrequisitos de una materia
- `sp_actualizar_prerequisito` - Actualiza un prerrequisito
- `sp_eliminar_prerequisito` - Elimina un prerrequisito

### 2.12 Procedimientos CRUD - Se Cursa (5)
- `sp_crear_se_cursa` - Asigna aula/horario a un paralelo
- `sp_obtener_se_cursa` - Lista todas las asignaciones
- `sp_obtener_se_cursa_por_paralelo` - Lista asignaciones de un paralelo
- `sp_actualizar_se_cursa` - Actualiza una asignación
- `sp_eliminar_se_cursa` - Elimina una asignación

### 2.13 Procedimientos de Inserción Especial (2)
- `sp_insertar_persona_usuario` - Inserta persona y usuario en una transacción
- `sp_insertar_estudiante_completo` - Inserta persona, estudiante y usuario en una transacción

### 2.14 Procedimientos de Negocio (2)
- `sp_realizar_inscripcion` - Inscribe a un estudiante con todas las validaciones (transacción)
- `sp_retirar_inscripcion` - Retira una inscripción cambiando estado a "Abandono" (transacción)

### 2.15 Procedimientos de Cierre de Gestión (2)
- `sp_preview_cierre_gestion` - Previsualización de resultados sin aplicar cambios
- `sp_cerrar_gestion` - Cierre definitivo con cálculo de notas y cambio de estado (transacción)

## 3. PROCEDIMIENTOS CON TRANSACCIONES (6)

### 3.1 sp_realizar_inscripcion

```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_realizar_inscripcion` (IN `p_id_estudiante` INT, IN `p_id_gestion` INT, IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    DECLARE v_id_inscripcion INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT fn_existe_estudiante(p_id_estudiante) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El estudiante no existe.';
    END IF;
    IF NOT fn_existe_gestion(p_id_gestion) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La gestion no existe.';
    END IF;
    IF NOT fn_existe_materia(p_id_materia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La materia no existe.';
    END IF;
    IF NOT fn_existe_paralelo(p_id_materia,p_id_paralelo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El paralelo no existe.';
    END IF;
    IF NOT fn_cupo_disponible(p_id_materia,p_id_paralelo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No existen cupos disponibles.';
    END IF;
    IF fn_ya_inscrito(p_id_estudiante,p_id_gestion,p_id_materia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El estudiante ya esta inscrito en esa materia.';
    END IF;
    IF NOT fn_tiene_prerrequisitos(p_id_estudiante,p_id_plan,p_id_materia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No cumple los prerrequisitos.';
    END IF;
    SELECT id_inscripcion INTO v_id_inscripcion FROM INSCRIPCION WHERE id_estudiante=p_id_estudiante AND id_gestion=p_id_gestion LIMIT 1;
    IF v_id_inscripcion IS NULL THEN
        INSERT INTO INSCRIPCION(id_estudiante, id_gestion, fecha_registro) VALUES(p_id_estudiante, p_id_gestion, CURDATE());
        SET v_id_inscripcion = LAST_INSERT_ID();
    END IF;
    INSERT INTO DETALLE_INSCRIPCION(id_inscripcion, id_materia, id_paralelo, estado, nota_final) VALUES(v_id_inscripcion, p_id_materia, p_id_paralelo, 'Inscrito', 0);
    COMMIT;
END$$
```

### 3.2 sp_retirar_inscripcion

```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_retirar_inscripcion` (IN `p_id_detalle` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS(SELECT 1 FROM DETALLE_INSCRIPCION WHERE id_detalle=p_id_detalle) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La inscripcion no existe.';
    END IF;
    UPDATE DETALLE_INSCRIPCION SET estado='Abandono' WHERE id_detalle=p_id_detalle;
    COMMIT;
END$$
```

### 3.3 sp_insertar_persona_usuario

```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertar_persona_usuario` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_rol` INT, IN `p_estado` VARCHAR(20))   BEGIN
    DECLARE v_id_persona INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_email VARCHAR(120);
    DECLARE v_password VARCHAR(20);
    DECLARE v_existe INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    
    SELECT COUNT(*) INTO v_existe FROM persona WHERE email = v_email;
    IF v_existe > 0 THEN
        SET v_email = CONCAT(v_username, '2@fcpn.edu.bo');
    END IF;
    
    SET v_password = fn_extraer_numero_ci(p_ci);
    
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
    VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, v_email, p_estado);
    
    SET v_id_persona = LAST_INSERT_ID();
    
    INSERT INTO usuario (username, password_hash, id_persona, id_rol, estado)
    VALUES (v_username, v_password, v_id_persona, p_id_rol, p_estado);
    
    COMMIT;
    
    SELECT v_id_persona AS id_persona, v_username AS username, v_email AS email, v_password AS password;
END$$
```

### 3.4 sp_insertar_estudiante_completo

```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertar_estudiante_completo` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_plan` INT, IN `p_anio_ingreso` VARCHAR(20))   BEGIN
    DECLARE v_id_persona INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_email VARCHAR(120);
    DECLARE v_password VARCHAR(20);
    DECLARE v_ru INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    SET v_password = fn_extraer_numero_ci(p_ci);
    
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
    VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, v_email, 'Activo');
    
    SET v_id_persona = LAST_INSERT_ID();
    
    INSERT INTO estudiante (id_persona, id_plan, anio_ingreso)
    VALUES (v_id_persona, p_id_plan, p_anio_ingreso);
    
    SELECT ru INTO v_ru FROM estudiante WHERE id_persona = v_id_persona;
    
    INSERT INTO usuario (username, password_hash, id_persona, id_rol, estado)
    VALUES (v_username, v_password, v_id_persona, 4, 'Activo');
    
    COMMIT;
    
    SELECT v_id_persona AS id_persona, v_ru AS ru, v_username AS username, v_email AS email;
END$$
```

### 3.5 sp_cerrar_gestion

```sql
CREATE PROCEDURE sp_cerrar_gestion(IN p_id_gestion INT)
BEGIN
    DECLARE v_estado_gestion VARCHAR(20);
    DECLARE v_total_afectados INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;
    DECLARE v_reprobados INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT estado INTO v_estado_gestion
    FROM gestion
    WHERE id_gestion = p_id_gestion;

    IF v_estado_gestion IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión no existe.';
    END IF;

    IF v_estado_gestion = 'Cerrada' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión ya está cerrada.';
    END IF;

    UPDATE detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    LEFT JOIN (
        SELECT 
            n.id_detalle,
            SUM(n.nota_obtenida * ce.ponderacion / 100) AS nota_calculada
        FROM nota n
        JOIN criterio_evaluacion ce ON n.id_criterio = ce.id_criterio
        GROUP BY n.id_detalle
    ) AS calculo ON di.id_detalle = calculo.id_detalle
    SET 
        di.nota_final = COALESCE(calculo.nota_calculada, 0),
        di.estado = CASE 
            WHEN COALESCE(calculo.nota_calculada, 0) >= 51 THEN 'Aprobado'
            ELSE 'Reprobado'
        END
    WHERE i.id_gestion = p_id_gestion
      AND di.estado = 'Inscrito';

    SELECT ROW_COUNT() INTO v_total_afectados;

    SELECT 
        COALESCE(SUM(CASE WHEN di.estado = 'Aprobado' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN di.estado = 'Reprobado' THEN 1 ELSE 0 END), 0)
    INTO v_aprobados, v_reprobados
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    WHERE i.id_gestion = p_id_gestion
      AND (di.estado = 'Aprobado' OR di.estado = 'Reprobado');

    UPDATE gestion 
    SET estado = 'Cerrada' 
    WHERE id_gestion = p_id_gestion;

    COMMIT;

    SELECT 
        g.periodo AS periodo,
        v_total_afectados AS total_procesados,
        v_aprobados AS aprobados,
        v_reprobados AS reprobados,
        'Cerrada' AS nuevo_estado
    FROM gestion g
    WHERE g.id_gestion = p_id_gestion;

END$$
```

### 3.6 sp_preview_cierre_gestion

```sql
CREATE PROCEDURE sp_preview_cierre_gestion(IN p_id_gestion INT)
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;
    DECLARE v_reprobados INT DEFAULT 0;
    DECLARE v_periodo VARCHAR(20);

    SELECT periodo INTO v_periodo
    FROM gestion
    WHERE id_gestion = p_id_gestion;

    IF v_periodo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión no existe.';
    END IF;

    SELECT COUNT(*),
           COALESCE(SUM(CASE WHEN nota_proyectada >= 51 THEN 1 ELSE 0 END), 0),
           COALESCE(SUM(CASE WHEN nota_proyectada < 51 THEN 1 ELSE 0 END), 0)
    INTO v_total, v_aprobados, v_reprobados
    FROM (
        SELECT 
            di.id_detalle,
            COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) AS nota_proyectada
        FROM detalle_inscripcion di
        JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
        JOIN gestion g ON i.id_gestion = g.id_gestion
        LEFT JOIN criterio_evaluacion ce 
            ON di.id_materia = ce.id_materia 
            AND di.id_paralelo = ce.id_paralelo
        LEFT JOIN nota n 
            ON di.id_detalle = n.id_detalle 
            AND ce.id_criterio = n.id_criterio
        WHERE i.id_gestion = p_id_gestion
          AND di.estado = 'Inscrito'
          AND g.estado = 'Activa'
        GROUP BY di.id_detalle
    ) AS t;

    SELECT 
        v_periodo AS periodo,
        v_total AS total,
        v_aprobados AS aprobados,
        v_reprobados AS reprobados;

    SELECT 
        CONCAT(p.nombres, ' ', p.apellidos) AS estudiante,
        e.ru AS ru,
        m.sigla AS sigla_materia,
        m.nombre AS materia,
        COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) AS nota_final_proyectada,
        CASE 
            WHEN COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) >= 51 THEN 'Aprobado'
            ELSE 'Reprobado'
        END AS estado_proyectado
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    JOIN gestion g ON i.id_gestion = g.id_gestion
    JOIN estudiante e ON i.id_estudiante = e.id_persona
    JOIN persona p ON e.id_persona = p.id_persona
    JOIN materia m ON di.id_materia = m.id_materia
    LEFT JOIN criterio_evaluacion ce 
        ON di.id_materia = ce.id_materia 
        AND di.id_paralelo = ce.id_paralelo
    LEFT JOIN nota n 
        ON di.id_detalle = n.id_detalle 
        AND ce.id_criterio = n.id_criterio
    WHERE i.id_gestion = p_id_gestion
      AND di.estado = 'Inscrito'
      AND g.estado = 'Activa'
    GROUP BY di.id_detalle, p.nombres, p.apellidos, e.ru, m.sigla, m.nombre
    ORDER BY p.apellidos, p.nombres, m.nombre;

END$$
```

## 4. CURSORES

No se encontraron cursores en la base de datos.

## 5. TRIGGERS (25)

### 5.1 Triggers de CRITERIO_EVALUACION (1)

#### 5.1.1 trg_validar_ponderacion_criterio (BEFORE INSERT)
Valida que la suma de ponderaciones no exceda 100%.

```sql
CREATE TRIGGER `trg_validar_ponderacion_criterio` BEFORE INSERT ON `criterio_evaluacion` FOR EACH ROW 
BEGIN
    DECLARE v_suma_actual FLOAT;
    SELECT COALESCE(SUM(ponderacion), 0) INTO v_suma_actual
    FROM criterio_evaluacion
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    IF (v_suma_actual + NEW.ponderacion) > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La suma de las ponderaciones no puede superar el 100%.';
    END IF;
END
```

### 5.2 Triggers de DETALLE_INSCRIPCION (6)

#### 5.2.1 trg_validar_inscripcion_paralelo_cupo (BEFORE INSERT)
Valida que el estudiante si pueda inscribirse por cupo, y que este el paralelo

```sql
CREATE TRIGGER `trg_validar_inscripcion_paralelo_cupo` 
BEFORE INSERT ON `detalle_inscripcion` 
FOR EACH ROW 
BEGIN
    DECLARE v_existe_paralelo INT DEFAULT 0;
    DECLARE v_cupo_maximo INT DEFAULT 0;
    DECLARE v_cupo_actual INT DEFAULT 0;
    
    -- Verificar que el paralelo existe
    SELECT COUNT(*) INTO v_existe_paralelo
    FROM paralelo
    WHERE id_materia = NEW.id_materia 
      AND id_paralelo = NEW.id_paralelo;
    
    IF v_existe_paralelo = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El paralelo especificado no existe para esta materia.';
    END IF;
    
    -- Verificar cupo disponible
    SELECT cupo_maximo, cupo_actual 
    INTO v_cupo_maximo, v_cupo_actual
    FROM paralelo
    WHERE id_materia = NEW.id_materia 
      AND id_paralelo = NEW.id_paralelo;
    
    IF v_cupo_actual >= v_cupo_maximo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No hay cupos disponibles en este paralelo.';
    END IF;
END
```

#### 5.2.2 trg_disminuir_cupo (AFTER DELETE)
Decrementa el cupo actual al eliminar una inscripción.

```sql
CREATE TRIGGER `trg_disminuir_cupo` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE PARALELO SET cupo_actual=cupo_actual-1 WHERE id_materia=OLD.id_materia AND id_paralelo=OLD.id_paralelo;
END
```

#### 5.2.3 trg_decrementar_cupo_actual (AFTER DELETE)
Versión mejorada con GREATEST para evitar valores negativos (duplicado).

```sql
CREATE TRIGGER `trg_decrementar_cupo_actual` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE paralelo SET cupo_actual = GREATEST(cupo_actual - 1, 0) WHERE id_materia = OLD.id_materia AND id_paralelo = OLD.id_paralelo;
END
```

#### 5.2.4 trg_liberar_cupo_abandono (AFTER UPDATE)
Libera el cupo cuando un estudiante abandona la materia.

```sql
CREATE TRIGGER `trg_liberar_cupo_abandono` AFTER UPDATE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    IF OLD.estado = 'Inscrito' AND NEW.estado = 'Abandono' THEN
        UPDATE PARALELO SET cupo_actual = cupo_actual - 1 WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    END IF;
END
```

#### 5.2.5 trg_validar_limite_inscripcion (BEFORE INSERT)
Limita el número de materias por gestión (6 en semestre regular, 2 en verano/invierno).

```sql
CREATE TRIGGER `trg_validar_limite_inscripcion` BEFORE INSERT ON `detalle_inscripcion` FOR EACH ROW BEGIN
    DECLARE v_periodo VARCHAR(20);
    DECLARE v_cantidad INT;
    DECLARE v_limite INT;
    
    SELECT g.periodo INTO v_periodo
    FROM inscripcion i
    JOIN gestion g ON i.id_gestion = g.id_gestion
    WHERE i.id_inscripcion = NEW.id_inscripcion;
    
    IF v_periodo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se encontró la gestión para esta inscripción.';
    END IF;
    
    SELECT COUNT(*) INTO v_cantidad
    FROM detalle_inscripcion
    WHERE id_inscripcion = NEW.id_inscripcion
      AND estado != 'Abandono';
    
    IF v_periodo LIKE 'Verano%' OR v_periodo LIKE 'Invierno%' THEN
        SET v_limite = 2;
    ELSE
        SET v_limite = 6;
    END IF;
    
    IF (v_cantidad + 1) > v_limite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Límite de inscripción excedido. Máximo materias permitidas.';
    END IF;
END
```

### 5.3 Triggers de DOCENTE (2)

#### 5.3.1 trg_auditoria_docente_insert (AFTER INSERT)
Registra en auditoría la creación de un docente.

```sql
CREATE TRIGGER `trg_auditoria_docente_insert` AFTER INSERT ON `docente` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nuevo docente Reg=', NEW.registro_docente, ' Grado=', NEW.grado_academico), CURDATE(), CURTIME());
END
```

#### 5.3.2 trg_auto_registro_docente (BEFORE INSERT)
Genera automáticamente el número de registro docente.

```sql
CREATE TRIGGER `trg_auto_registro_docente` BEFORE INSERT ON `docente` FOR EACH ROW BEGIN
    DECLARE v_max_reg INT;
    
    IF NEW.registro_docente IS NULL OR NEW.registro_docente = '' THEN
        SELECT COALESCE(MAX(CAST(registro_docente AS UNSIGNED)), 1015647) INTO v_max_reg FROM docente;
        SET NEW.registro_docente = v_max_reg + 1;
    END IF;
END
```

### 5.4 Triggers de ESTUDIANTE (2)

#### 5.4.1 trg_auditoria_estudiante_insert (AFTER INSERT)
Registra en auditoría la creación de un estudiante.

```sql
CREATE TRIGGER `trg_auditoria_estudiante_insert` AFTER INSERT ON `estudiante` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nuevo estudiante RU=', NEW.ru, ' Plan=', NEW.id_plan, ' Ingreso=', NEW.anio_ingreso), CURDATE(), CURTIME());
END
```

#### 5.4.2 trg_auto_ru_estudiante (BEFORE INSERT)
Genera automáticamente el número de Registro Universitario (RU).

```sql
CREATE TRIGGER `trg_auto_ru_estudiante` BEFORE INSERT ON `estudiante` FOR EACH ROW BEGIN
    DECLARE v_max_ru INT;
    
    IF NEW.ru IS NULL OR NEW.ru = '' THEN
        SELECT COALESCE(MAX(CAST(ru AS UNSIGNED)), 1005999) INTO v_max_ru FROM estudiante;
        SET NEW.ru = v_max_ru + 1;
    END IF;
END
```

### 5.5 Triggers de NOTA (4)

#### 5.5.1 trg_auditoria_nota_insert (AFTER INSERT)
Registra en auditoría la creación de una nota.

```sql
CREATE TRIGGER `trg_auditoria_nota_insert` AFTER INSERT ON `nota` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nueva nota ID=', NEW.id_nota, ' puntaje=', NEW.nota_obtenida, ' criterio=', NEW.id_criterio), CURDATE(), CURTIME());
END
```

#### 5.5.2 trg_auditoria_nota_update (AFTER UPDATE)
Registra en auditoría la actualización de una nota.

```sql
CREATE TRIGGER `trg_auditoria_nota_update` AFTER UPDATE ON `nota` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'UPDATE', CONCAT('Nota ID=', NEW.id_nota, ' actualizada de ', OLD.nota_obtenida, ' a ', NEW.nota_obtenida), CURDATE(), CURTIME());
END
```

#### 5.5.3 trg_validar_nota_max (BEFORE INSERT)
Valida que la nota no supere 100 puntos.

```sql
CREATE TRIGGER `trg_validar_nota_max` BEFORE INSERT ON `nota` FOR EACH ROW BEGIN
    IF NEW.nota_obtenida > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La nota no puede exceder 100 puntos.';
    END IF;
END
```

#### 5.5.4 trg_bloquear_notas_gestion_cerrada (BEFORE INSERT)
Bloquea el registro de notas si la gestión está cerrada.

```sql
CREATE TRIGGER `trg_bloquear_notas_gestion_cerrada` BEFORE INSERT ON `nota` FOR EACH ROW 
BEGIN
    DECLARE v_estado_gestion VARCHAR(20);
    SELECT g.estado INTO v_estado_gestion
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    JOIN gestion g ON i.id_gestion = g.id_gestion
    WHERE di.id_detalle = NEW.id_detalle;
    IF v_estado_gestion = 'Cerrada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operación denegada: La gestión académica ya está cerrada.';
    END IF;
END
```

### 5.6 Triggers de PERSONA (4)

#### 5.6.1 trg_auditoria_persona_insert (AFTER INSERT)
Registra en auditoría la creación de una persona.

```sql
CREATE TRIGGER `trg_auditoria_persona_insert` AFTER INSERT ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nueva persona: ', NEW.nombres, ' ', NEW.apellidos, ' (CI: ', NEW.ci, ')'), CURDATE(), CURTIME());
END
```

#### 5.6.2 trg_auditoria_persona_update (AFTER UPDATE)
Registra en auditoría la actualización de una persona.

```sql
CREATE TRIGGER `trg_auditoria_persona_update` AFTER UPDATE ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'UPDATE', CONCAT('Actualización persona ID=', NEW.id_persona, ' de ', OLD.nombres, ' a ', NEW.nombres), CURDATE(), CURTIME());
END
```

#### 5.6.3 trg_auditoria_persona_delete (AFTER DELETE)
Registra en auditoría la eliminación de una persona.

```sql
CREATE TRIGGER `trg_auditoria_persona_delete` AFTER DELETE ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'DELETE', CONCAT('Eliminada persona ID=', OLD.id_persona, ' (', OLD.nombres, ' ', OLD.apellidos, ')'), CURDATE(), CURTIME());
END
```

#### 5.6.4 trg_auto_email_persona (BEFORE INSERT)
Genera automáticamente el email si no se proporciona.

```sql
CREATE TRIGGER `trg_auto_email_persona` BEFORE INSERT ON `persona` FOR EACH ROW BEGIN
    DECLARE v_username_temp VARCHAR(50);
    
    IF NEW.email IS NULL OR NEW.email = '' THEN
        SET v_username_temp = fn_generar_username(NEW.nombres, NEW.apellidos);
        SET NEW.email = fn_generar_email(v_username_temp);
    ELSE
        IF NEW.email NOT LIKE '%@fcpn.edu.bo' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El email debe tener formato @fcpn.edu.bo';
        END IF;
    END IF;
END
```

### 5.7 Triggers de SE_CURSA (2)

#### 5.7.1 trg_validar_aula_horario (BEFORE INSERT)
Evita conflictos de aula en el mismo horario y gestión.

```sql
CREATE TRIGGER `trg_validar_aula_horario` BEFORE INSERT ON `se_cursa` FOR EACH ROW BEGIN
    DECLARE v_conflicto INT;
    
    SELECT COUNT(*) INTO v_conflicto
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    JOIN paralelo p2 ON NEW.id_materia = p2.id_materia AND NEW.id_paralelo = p2.id_paralelo
    WHERE sc.id_aula = NEW.id_aula 
      AND sc.id_horario = NEW.id_horario
      AND p.id_gestion = p2.id_gestion;
    
    IF v_conflicto > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflicto: Ya existe una materia asignada en esta aula y horario.';
    END IF;
END
```

#### 5.7.2 trg_validar_docente_horario (BEFORE INSERT)
Evita conflictos de docente en el mismo horario y gestión.

```sql
CREATE TRIGGER `trg_validar_docente_horario` BEFORE INSERT ON `se_cursa` FOR EACH ROW BEGIN
    DECLARE v_conflicto INT;
    
    SELECT COUNT(*) INTO v_conflicto
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    JOIN paralelo p_actual ON NEW.id_materia = p_actual.id_materia AND NEW.id_paralelo = p_actual.id_paralelo
    WHERE p.id_docente = p_actual.id_docente
      AND sc.id_horario = NEW.id_horario
      AND p.id_gestion = p_actual.id_gestion
      AND (sc.id_materia != NEW.id_materia OR sc.id_paralelo != NEW.id_paralelo);
    
    IF v_conflicto > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflicto: El docente ya tiene otra materia en este horario.';
    END IF;
END
```

### 5.8 Triggers de PARALELO (1)

#### 5.8.1 trg_validar_max_paralelos_docente (BEFORE UPDATE)
Valida que un docente no pueda dirigir más de 3 paralelos en la misma gestión. Este trigger se activa cuando un docente solicita dirigir una materia (asignación vía UPDATE).

```sql
CREATE TRIGGER trg_validar_max_paralelos_docente
BEFORE UPDATE ON paralelo
FOR EACH ROW
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    
    -- Solo validar cuando se asigna un docente (no cuando se quita)
    IF NEW.id_docente IS NOT NULL THEN
        SELECT COUNT(*) INTO v_cantidad
        FROM paralelo
        WHERE id_docente = NEW.id_docente
          AND id_gestion = NEW.id_gestion
          AND NOT (id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo);
        
        IF v_cantidad >= 3 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El docente ya dirige 3 paralelos en esta gestión. No puede tomar más.';
        END IF;
    END IF;
END
```

> **Nota:** La columna `id_docente` en la tabla `paralelo` fue modificada para aceptar NULL:
> ```sql
> ALTER TABLE paralelo MODIFY COLUMN id_docente INT(11) DEFAULT NULL;
> ```
> Esto permite que los paralelos se creen sin docente durante la apertura de gestión, y los docentes soliciten dirigirlos después.

### 5.9 Triggers de USUARIO (3)

#### 5.8.1 trg_auditoria_nuevo_usuario (AFTER INSERT)
Registra en auditoría la creación de un usuario.

```sql
CREATE TRIGGER `trg_auditoria_nuevo_usuario` AFTER INSERT ON `usuario` FOR EACH ROW 
BEGIN
    INSERT INTO auditoria (id_usuario, accion, fecha, hora) VALUES (NEW.id_usuario, CONCAT('Creación de usuario: ', NEW.username), CURDATE(), CURTIME());
END
```

#### 5.8.2 trg_auto_username_usuario (BEFORE INSERT)
Genera automáticamente el username si no se proporciona y valida la presencia obligatoria de la contraseña hasheada con BCrypt desde el backend.

```sql
CREATE TRIGGER trg_auto_username_usuario 
BEFORE INSERT ON usuario 
FOR EACH ROW 
BEGIN
    DECLARE v_nombres VARCHAR(80);
    DECLARE v_apellidos VARCHAR(80);
    DECLARE v_ci VARCHAR(20);
    
    -- Obtener datos de persona
    SELECT nombres, apellidos, ci INTO v_nombres, v_apellidos, v_ci
    FROM persona WHERE id_persona = NEW.id_persona;
    
    -- Generar username si viene vacío
    IF NEW.username IS NULL OR NEW.username = '' THEN
        SET NEW.username = fn_generar_username(v_nombres, v_apellidos);
    END IF;
    
    -- Validar que la contraseña hasheada no esté vacía (Generada con BCrypt en backend)
    IF NEW.password_hash IS NULL OR NEW.password_hash = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La contraseña debe ser generada en el backend con BCrypt.';
    END IF;
END
```

#### 5.8.3 trg_validar_usuario_unico (BEFORE INSERT)
Evita que una persona tenga más de un usuario activo.

```sql
CREATE TRIGGER `trg_validar_usuario_unico` BEFORE INSERT ON `usuario` FOR EACH ROW BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM usuario WHERE id_persona = NEW.id_persona AND estado = 'Activo';
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya existe un usuario activo para esta persona.';
    END IF;
END
```

## 6. RESTRICCIONES DE LLAVES FORÁNEAS (ON DELETE CASCADE)

Para evitar bloqueos al eliminar registros dependientes de una persona (estudiante, docente, usuario, administrativo), se configuraron las siguientes llaves foráneas en cascada:

```sql
ALTER TABLE usuario ADD CONSTRAINT fk_usuario_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE;
ALTER TABLE estudiante ADD CONSTRAINT fk_estudiante_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE;
ALTER TABLE docente ADD CONSTRAINT fk_docente_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE;
ALTER TABLE administrativo ADD CONSTRAINT fk_admin_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE;
```

## 7. RESUMEN COMPLETO DE OBJETOS DE BASE DE DATOS

| Tipo de Objeto | Cantidad | Descripción |
| --- | --- | --- |
| Funciones | 13 | Lógica de validación, formato y cupos |
| Procedimientos CRUD | 52 | Operaciones directas de creación, consulta y actualización |
| Procedimientos Especiales & Seguridad | 6 | `sp_insertar_estudiante_completo_seguro`, `sp_insertar_persona_usuario_seguro`, `sp_set_audit_user`, etc. |
| Procedimientos de Negocio y Paralelos | 3 | `sp_realizar_inscripcion`, `sp_retirar_inscripcion`, `sp_aperturar_paralelo_completo` |
| Procedimientos de Cierre | 2 | `sp_preview_cierre_gestion`, `sp_cerrar_gestion` |
| Procedimientos con Transacciones & Locks | 9 | Manejo de concurrencia con `GET_LOCK()` / `RELEASE_LOCK()` y `@current_user_id` |
| Triggers | 25 | Triggers de auditoría, cupos, límites, integridad y asignación docente |
| Restricciones Cascade | 4 | Llaves foráneas con `ON DELETE CASCADE` |
| Alteraciones de Columna | 1 | `paralelo.id_docente` → `DEFAULT NULL` |
| **TOTAL** | **115** | **Objetos totales activos en MariaDB / MySQL** |
