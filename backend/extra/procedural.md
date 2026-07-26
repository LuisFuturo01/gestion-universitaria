# Análisis de Objetos de Programación - Base de Datos sistemaacademico

## 1. FUNCIONES (7)

### 1.1 fn_cupo_disponible

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_cupo_disponible` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_max INT;
    DECLARE v_actual INT;
    SELECT cupo_maximo, cupo_actual INTO v_max, v_actual FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
    RETURN v_actual < v_max;
END$$
```

### 1.2 fn_existe_estudiante

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_estudiante` (`p_id_estudiante` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM ESTUDIANTE WHERE id_persona = p_id_estudiante;
    RETURN v_existe > 0;
END$$
```

### 1.3 fn_existe_gestion

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_gestion` (`p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM GESTION WHERE id_gestion = p_id_gestion;
    RETURN v_existe > 0;
END$$
```

### 1.4 fn_existe_materia

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_materia` (`p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM MATERIA WHERE id_materia = p_id_materia;
    RETURN v_existe > 0;
END$$
```

### 1.5 fn_existe_paralelo

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_existe_paralelo` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
    RETURN v_existe > 0;
END$$
```

### 1.6 fn_tiene_prerrequisitos

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

```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_ya_inscrito` (`p_id_estudiante` INT, `p_id_gestion` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM INSCRIPCION i 
    INNER JOIN DETALLE_INSCRIPCION d ON i.id_inscripcion = d.id_inscripcion 
    WHERE i.id_estudiante = p_id_estudiante AND i.id_gestion = p_id_gestion AND d.id_materia = p_id_materia;
    RETURN v_existe > 0;
END$$
```

## 2. PROCEDIMIENTOS ALMACENADOS (60)

### 2.1 Procedimientos CRUD - Aula (5)

- `sp_crear_aula`
- `sp_obtener_aulas`
- `sp_obtener_aula_por_id`
- `sp_actualizar_aula`
- `sp_eliminar_aula`

### 2.2 Procedimientos CRUD - Carrera (5)

- `sp_crear_carrera`
- `sp_obtener_carreras`
- `sp_obtener_carrera_por_id`
- `sp_actualizar_carrera`
- `sp_eliminar_carrera`

### 2.3 Procedimientos CRUD - Criterio Evaluación (4)

- `sp_crear_criterio`
- `sp_obtener_criterios_paralelo`
- `sp_actualizar_criterio`
- `sp_eliminar_criterio`

### 2.4 Procedimientos CRUD - Gestión (4)

- `sp_crear_gestion`
- `sp_obtener_gestiones`
- `sp_actualizar_gestion`
- `sp_eliminar_gestion`

### 2.5 Procedimientos CRUD - Horario (5)

- `sp_crear_horario`
- `sp_obtener_horarios`
- `sp_obtener_horario_por_id`
- `sp_actualizar_horario`
- `sp_eliminar_horario`

### 2.6 Procedimientos CRUD - Materia (5)

- `sp_crear_materia`
- `sp_obtener_materias`
- `sp_obtener_materia_por_id`
- `sp_actualizar_materia`
- `sp_eliminar_materia`

### 2.7 Procedimientos CRUD - Nota (4)

- `sp_crear_nota`
- `sp_obtener_notas_detalle`
- `sp_actualizar_nota`
- `sp_eliminar_nota`

### 2.8 Procedimientos CRUD - Paralelo (4)

- `sp_crear_paralelo`
- `sp_obtener_paralelos`
- `sp_actualizar_paralelo`
- `sp_eliminar_paralelo`

### 2.9 Procedimientos CRUD - Plan Estudio (5)

- `sp_crear_plan_estudio`
- `sp_obtener_planes_estudio`
- `sp_obtener_plan_estudio_por_id`
- `sp_actualizar_plan_estudio`
- `sp_eliminar_plan_estudio`

### 2.10 Procedimientos CRUD - Plan Materia (5)

- `sp_crear_plan_materia`
- `sp_obtener_plan_materias`
- `sp_obtener_materias_por_plan`
- `sp_actualizar_plan_materia`
- `sp_eliminar_plan_materia`

### 2.11 Procedimientos CRUD - Prerequisito (5)

- `sp_crear_prerequisito`
- `sp_obtener_prerequisitos`
- `sp_obtener_prerequisitos_materia`
- `sp_actualizar_prerequisito`
- `sp_eliminar_prerequisito`

### 2.12 Procedimientos CRUD - Se Cursa (5)

- `sp_crear_se_cursa`
- `sp_obtener_se_cursa`
- `sp_obtener_se_cursa_por_paralelo`
- `sp_actualizar_se_cursa`
- `sp_eliminar_se_cursa`

### 2.13 Procedimientos de Negocio (2)

- `sp_realizar_inscripcion` (con transacción y validaciones)
- `sp_retirar_inscripcion` (con transacción)

### 2.14 Procedimientos de Cierre de Gestión (2)

- `sp_preview_cierre_gestion` (previsualización sin aplicar cambios)
- `sp_cerrar_gestion` (con transacción y cambios definitivos)

## 3. PROCEDIMIENTOS CON TRANSACCIONES (3)

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

### 3.3 sp_preview_cierre_gestion

```sql
CREATE PROCEDURE sp_preview_cierre_gestion(IN p_id_gestion INT)
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;
    DECLARE v_reprobados INT DEFAULT 0;
    DECLARE v_periodo VARCHAR(20);

    -- Verificar que la gestión existe
    SELECT periodo INTO v_periodo
    FROM gestion
    WHERE id_gestion = p_id_gestion;

    IF v_periodo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La gestión no existe.';
    END IF;

    -- Calcular totales
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

    -- Devolver resumen
    SELECT 
        v_periodo AS periodo,
        v_total AS total,
        v_aprobados AS aprobados,
        v_reprobados AS reprobados;

    -- Devolver detalle por estudiante
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

### 3.4 sp_cerrar_gestion

```sql
CREATE PROCEDURE sp_cerrar_gestion(IN p_id_gestion INT)
BEGIN
    DECLARE v_estado_gestion VARCHAR(20);
    DECLARE v_total_afectados INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;
    DECLARE v_reprobados INT DEFAULT 0;

    -- Manejador de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Verificar que la gestión existe y está activa
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

    -- Actualizar nota_final y estado en detalle_inscripcion
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

    -- Contar afectados
    SELECT ROW_COUNT() INTO v_total_afectados;

    -- Contar aprobados y reprobados
    SELECT 
        COALESCE(SUM(CASE WHEN di.estado = 'Aprobado' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN di.estado = 'Reprobado' THEN 1 ELSE 0 END), 0)
    INTO v_aprobados, v_reprobados
    FROM detalle_inscripcion di
    JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion
    WHERE i.id_gestion = p_id_gestion
      AND (di.estado = 'Aprobado' OR di.estado = 'Reprobado');

    -- Cambiar estado de la gestión a Cerrada
    UPDATE gestion 
    SET estado = 'Cerrada' 
    WHERE id_gestion = p_id_gestion;

    COMMIT;

    -- Devolver resumen final
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

## 4. CURSORES

No se encontraron cursores en la base de datos.

## 5. TRIGGERS (7)

### 5.1 trg_validar_ponderacion_criterio (Tabla: criterio_evaluacion, Evento: BEFORE INSERT)

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

### 5.2 trg_aumentar_cupo (Tabla: detalle_inscripcion, Evento: AFTER INSERT)

```sql
CREATE TRIGGER `trg_aumentar_cupo` AFTER INSERT ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE PARALELO SET cupo_actual=cupo_actual+1 WHERE id_materia=NEW.id_materia AND id_paralelo=NEW.id_paralelo;
END
```

### 5.3 trg_incrementar_cupo_actual (Tabla: detalle_inscripcion, Evento: AFTER INSERT)

```sql
CREATE TRIGGER `trg_incrementar_cupo_actual` AFTER INSERT ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE paralelo SET cupo_actual = cupo_actual + 1 WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
END
```

### 5.4 trg_disminuir_cupo (Tabla: detalle_inscripcion, Evento: AFTER DELETE)

```sql
CREATE TRIGGER `trg_disminuir_cupo` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE PARALELO SET cupo_actual=cupo_actual-1 WHERE id_materia=OLD.id_materia AND id_paralelo=OLD.id_paralelo;
END
```

### 5.5 trg_decrementar_cupo_actual (Tabla: detalle_inscripcion, Evento: AFTER DELETE)

```sql
CREATE TRIGGER `trg_decrementar_cupo_actual` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE paralelo SET cupo_actual = GREATEST(cupo_actual - 1, 0) WHERE id_materia = OLD.id_materia AND id_paralelo = OLD.id_paralelo;
END
```

### 5.6 trg_liberar_cupo_abandono (Tabla: detalle_inscripcion, Evento: AFTER UPDATE)

```sql
CREATE TRIGGER `trg_liberar_cupo_abandono` AFTER UPDATE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    IF OLD.estado = 'Inscrito' AND NEW.estado = 'Abandono' THEN
        UPDATE PARALELO SET cupo_actual = cupo_actual - 1 WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    END IF;
END
```

### 5.7 trg_bloquear_notas_gestion_cerrada (Tabla: nota, Evento: BEFORE INSERT)

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

### 5.8 trg_auditoria_nuevo_usuario (Tabla: usuario, Evento: AFTER INSERT)

```sql
CREATE TRIGGER `trg_auditoria_nuevo_usuario` AFTER INSERT ON `usuario` FOR EACH ROW 
BEGIN
    INSERT INTO auditoria (id_usuario, accion, fecha, hora) VALUES (NEW.id_usuario, CONCAT('Creación de usuario: ', NEW.username), CURDATE(), CURTIME());
END
```

## RESUMEN

| Tipo de Objeto | Cantidad |
| --- | --- |
| Funciones | 7 |
| Procedimientos | 60 |
| Procedimientos con Transacciones | 3 |
| Cursores | 0 |
| Triggers | 8 |