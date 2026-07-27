# Documentación Oficial de Objetos de Programación y Consultas SQL - Base de Datos sistemaacademico

> **Nota de Arquitectura y Separación de Capas:**
> Este documento contiene la especificación oficial y completa de todos los objetos procedimentales, cursores, disparadores, funciones y consultas estructuradas de la base de datos `sistemaacademico`. La fuente de verdad oficial para todas las definiciones SQL de base de datos es [`sistemaacademicooficial.sql`](file:///d:/xampp/htdocs/UMSA/db2/proyecto/backend/extra/sistemaacademicooficial.sql).
> - **Consultas SQL (DML / Models):** 50 consultas extraídas y utilizadas por los modelos de Node.js/Express para interactuar con MariaDB.
> - **Funciones (Functions):** 14 funciones almacenadas en MariaDB para cómputo de reglas de negocio y validaciones.
> - **Procedimientos Almacenados (Stored Procedures):** **68 procedimientos almacenados oficiales** registrados en el sistema (CRUDs completos, asignación de horarios, transacciones atómicas, aperturas y cierres de gestión).
> - **Cursores (Cursors):** 14 cursores de procesamiento iterativo por lotes (batch) diseñados para ejecutarse en el Gestor de Base de Datos (DBMS MariaDB / MySQL) en tareas de mantenimiento, cierre de gestión e informes complejos. *(Aclaración: No son llamados directamente por la API REST de Node.js para mantener la eficiencia de la API y evitar bloqueos de hilos).*
> - **Triggers (Disparadores):** 24 triggers activos encargados de la integridad referencial, auditoría automática, asignación de secuencias y control de límites.

---

## 1. CONSULTAS SQL EXTRAÍDAS DEL BACKEND Y MODELOS (50 Consultas DML)

### 1.1 Obtener todas las personas activas
Recupera el listado general de personas registradas con estado activo.
```sql
SELECT id_persona, ci, nombres, apellidos, fecha_nac, sexo, email
FROM persona
WHERE estado = 'A';
```

### 1.2 Obtener persona activa por ID
Busca una persona específica por su identificador primario.
```sql
SELECT id_persona, ci, nombres, apellidos, fecha_nac, sexo, email
FROM persona
WHERE id_persona = ? AND estado = 'A';
```

### 1.3 Insertar nueva persona
Registra un nuevo individuo en la tabla base persona.
```sql
INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado)
VALUES (?, ?, ?, ?, ?, ?, 'A');
```

### 1.4 Actualizar datos de persona
Modifica los datos personales de una persona existente.
```sql
UPDATE persona
SET ci = ?, nombres = ?, apellidos = ?, fecha_nac = ?, sexo = ?, email = ?
WHERE id_persona = ?;
```

### 1.5 Borrado lógico de persona
Inactiva el estado de una persona en el sistema.
```sql
UPDATE persona
SET estado = 'I'
WHERE id_persona = ?;
```

### 1.6 Obtener listado general de estudiantes
Recupera los estudiantes activos concatenando sus datos personales y académicos.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, p.email, e.ru, e.id_plan, e.anio_ingreso
FROM persona p
INNER JOIN estudiante e ON p.id_persona = e.id_persona
WHERE p.estado = 'A';
```

### 1.7 Obtener estudiante por ID
Consulta el detalle individual de un estudiante.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, p.email, e.ru, e.id_plan, e.anio_ingreso
FROM persona p
INNER JOIN estudiante e ON p.id_persona = e.id_persona
WHERE p.id_persona = ? AND p.estado = 'A';
```

### 1.8 Insertar registro de estudiante
Crea el perfil académico del estudiante en la tabla correspondiente.
```sql
INSERT INTO estudiante (id_persona, ru, id_plan, anio_ingreso)
VALUES (?, ?, ?, ?);
```

### 1.9 Actualizar perfil de estudiante
Actualiza la información del Registro Universitario y plan de estudios.
```sql
UPDATE estudiante
SET ru = ?, id_plan = ?, anio_ingreso = ?
WHERE id_persona = ?;
```

### 1.10 Obtener todos los docentes
Consulta los docentes activos con su registro y grado académico.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, p.email, d.registro_docente, d.grado_academico
FROM persona p
INNER JOIN docente d ON p.id_persona = d.id_persona
WHERE p.estado = 'A';
```

### 1.11 Obtener docente por ID
Recupera la ficha de un docente en particular.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, p.email, d.registro_docente, d.grado_academico
FROM persona p
INNER JOIN docente d ON p.id_persona = d.id_persona
WHERE p.id_persona = ? AND p.estado = 'A';
```

### 1.12 Insertar docente
Registra un nuevo docente en la base de datos.
```sql
INSERT INTO docente (id_persona, registro_docente, grado_academico)
VALUES (?, ?, ?);
```

### 1.13 Actualizar docente
Actualiza el grado académico y registro de un docente.
```sql
UPDATE docente
SET registro_docente = ?, grado_academico = ?
WHERE id_persona = ?;
```

### 1.14 Obtener todos los administrativos
Lista los usuarios del cuerpo administrativo.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, p.email, a.cargo
FROM persona p
INNER JOIN administrativo a ON p.id_persona = a.id_persona
WHERE p.estado = 'A';
```

### 1.15 Obtener administrativo por ID
Recupera los datos institucionales de un administrativo.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, p.email, a.cargo
FROM persona p
INNER JOIN administrativo a ON p.id_persona = a.id_persona
WHERE p.id_persona = ? AND p.estado = 'A';
```

### 1.16 Insertar administrativo
Asigna el cargo administrativo a una persona.
```sql
INSERT INTO administrativo (id_persona, cargo)
VALUES (?, ?);
```

### 1.17 Actualizar cargo administrativo
Modifica la responsabilidad laboral de un administrativo.
```sql
UPDATE administrativo
SET cargo = ?
WHERE id_persona = ?;
```

### 1.18 Obtener todas las aulas
Consulta la infraestructura física de la institución.
```sql
SELECT id_aula, numero, capacidad
FROM aula;
```

### 1.19 Obtener aula por ID
Obtiene la capacidad y número de un aula específica.
```sql
SELECT id_aula, numero, capacidad
FROM aula
WHERE id_aula = ?;
```

### 1.20 Insertar aula
Registra un nuevo ambiente o laboratorio.
```sql
INSERT INTO aula (numero, capacidad)
VALUES (?, ?);
```

### 1.21 Actualizar aula
Modifica los datos de un aula.
```sql
UPDATE aula
SET numero = ?, capacidad = ?
WHERE id_aula = ?;
```

### 1.22 Eliminar aula
Remueve un ambiente de la base de datos.
```sql
DELETE FROM aula
WHERE id_aula = ?;
```

### 1.23 Obtener carreras universitarias
Consulta la oferta de carreras y facultades.
```sql
SELECT id_carrera, nombre, id_facultad
FROM carrera;
```

### 1.24 Obtener carrera por ID
Obtiene los datos de una carrera técnica o licenciatura.
```sql
SELECT id_carrera, nombre, id_facultad
FROM carrera
WHERE id_carrera = ?;
```

### 1.25 Insertar carrera
Crea un nuevo programa académico.
```sql
INSERT INTO carrera (nombre, id_facultad)
VALUES (?, ?);
```

### 1.26 Actualizar carrera
Modifica la denominación de la carrera.
```sql
UPDATE carrera
SET nombre = ?, id_facultad = ?
WHERE id_carrera = ?;
```

### 1.27 Eliminar carrera
Remueve una carrera del sistema.
```sql
DELETE FROM carrera
WHERE id_carrera = ?;
```

### 1.28 Obtener criterios de evaluación
Recupera todos los criterios creados por los docentes.
```sql
SELECT id_criterio, id_materia, id_paralelo, nombre, ponderacion
FROM criterio_evaluacion;
```

### 1.29 Obtener criterios por materia y paralelo
Filtra la estructura de evaluación de un grupo.
```sql
SELECT id_criterio, id_materia, id_paralelo, nombre, ponderacion
FROM criterio_evaluacion
WHERE id_materia = ? AND id_paralelo = ?;
```

### 1.30 Insertar criterio de evaluación
Agrega un parcial, práctica o proyecto.
```sql
INSERT INTO criterio_evaluacion (id_materia, id_paralelo, nombre, ponderacion)
VALUES (?, ?, ?, ?);
```

### 1.31 Actualizar criterio de evaluación
Modifica el nombre o porcentaje de un examen.
```sql
UPDATE criterio_evaluacion
SET nombre = ?, ponderacion = ?
WHERE id_criterio = ?;
```

### 1.32 Eliminar criterio de evaluación
Remueve un criterio de evaluación.
```sql
DELETE FROM criterio_evaluacion
WHERE id_criterio = ?;
```

### 1.33 Obtener directores de carrera
Consulta los docentes asignados como directores.
```sql
SELECT p.id_persona, p.ci, p.nombres, p.apellidos, d.id_carrera, c.nombre AS carrera
FROM persona p
INNER JOIN docente d ON p.id_persona = d.id_persona
INNER JOIN dirige d2 ON d.id_persona = d2.id_persona
INNER JOIN carrera c ON d2.id_carrera = c.id_carrera;
```

### 1.34 Asignar dirección de carrera
Vincula un docente a la jefatura de una carrera.
```sql
INSERT INTO dirige (id_persona, id_carrera)
VALUES (?, ?);
```

### 1.35 Desasignar dirección de carrera
Remueve la asignación de dirección.
```sql
DELETE FROM dirige
WHERE id_persona = ? AND id_carrera = ?;
```

### 1.36 Obtener gestiones académicas
Lista todos los periodos lectivos ordenados cronológicamente.
```sql
SELECT id_gestion, anio, periodo, fecha_inicio, fecha_fin, estado
FROM gestion
ORDER BY anio DESC, periodo ASC;
```

### 1.37 Obtener gestión activa
Obtiene el periodo lectivo en curso.
```sql
SELECT id_gestion, anio, periodo, fecha_inicio, fecha_fin, estado
FROM gestion
WHERE estado = 'Activa'
LIMIT 1;
```

### 1.38 Desactivar otras gestiones
Inactiva las gestiones anteriores al aperturar una nueva.
```sql
UPDATE gestion
SET estado = 'Inactiva'
WHERE id_gestion != ?;
```

### 1.39 Activar gestión específica
Establece una gestión como activa.
```sql
UPDATE gestion
SET estado = 'Activa'
WHERE id_gestion = ?;
```

### 1.40 Obtener tabla de horarios
Consulta los turnos y bloques de clases.
```sql
SELECT id_horario, dia, hora_inicio, hora_fin
FROM horario;
```

### 1.41 Obtener horario por ID
Obtiene los detalles de un bloque horario.
```sql
SELECT id_horario, dia, hora_inicio, hora_fin
FROM horario
WHERE id_horario = ?;
```

### 1.42 Insertar horario
Crea un nuevo turno o bloque horario.
```sql
INSERT INTO horario (dia, hora_inicio, hora_fin)
VALUES (?, ?, ?);
```

### 1.43 Actualizar horario
Modifica la franja horaria.
```sql
UPDATE horario
SET dia = ?, hora_inicio = ?, hora_fin = ?
WHERE id_horario = ?;
```

### 1.44 Eliminar horario
Remueve un bloque horario no asignado.
```sql
DELETE FROM horario
WHERE id_horario = ?;
```

### 1.45 Obtener planilla consolidada de inscripciones
Consulta optimizada para listar las inscripciones y notas de estudiantes.
```sql
SELECT DISTINCT
    i.id_inscripcion,
    d.id_detalle,
    i.id_estudiante,
    p.nombres,
    p.apellidos,
    d.id_materia,
    m.nombre AS materia,
    d.id_paralelo,
    pa.nombre AS paralelo,
    i.id_gestion,
    g.periodo,
    COALESCE(d.estado, 'Inscrito') AS estado,
    COALESCE(d.nota_final, 0) AS nota_final
FROM inscripcion i
JOIN detalle_inscripcion d ON i.id_inscripcion = d.id_inscripcion
LEFT JOIN persona p ON i.id_estudiante = p.id_persona
LEFT JOIN materia m ON d.id_materia = m.id_materia
LEFT JOIN paralelo pa ON d.id_materia = pa.id_materia AND d.id_paralelo = pa.id_paralelo AND i.id_gestion = pa.id_gestion
LEFT JOIN gestion g ON i.id_gestion = g.id_gestion;
```

### 1.46 Consultar usuario por credenciales de inicio de sesión
Autenticación de usuario con hash de contraseña.
```sql
SELECT u.id_usuario, u.username, u.password_hash, u.id_persona, r.nombre AS rol
FROM usuario u
INNER JOIN tiene_rol tr ON u.id_usuario = tr.id_usuario
INNER JOIN rol r ON tr.id_rol = r.id_rol
WHERE u.username = ?;
```

### 1.47 Obtener catálogo de materias
Recupera todas las materias con su sigla y nivel.
```sql
SELECT id_materia, sigla, nombre, nivel
FROM materia;
```

### 1.48 Consulta de notas registradas por detalle
Recupera los puntajes asignados en cada criterio de evaluación.
```sql
SELECT id_nota, id_detalle, id_criterio, nota_obtenida
FROM nota;
```

### 1.49 Asignación de docente a un paralelo
Vincula a un profesor con un paralelo aperturado.
```sql
UPDATE paralelo
SET id_docente = ?
WHERE id_materia = ? AND id_paralelo = ? AND id_gestion = ?;
```

### 1.50 Obtener cruce de horarios y aulas de asignaturas
Consulta de programación física de materias en aulas.
```sql
SELECT sc.id_materia, sc.id_paralelo, sc.id_aula, sc.id_horario, a.numero AS aula, h.dia, h.hora_inicio, h.hora_fin
FROM se_cursa sc
JOIN aula a ON sc.id_aula = a.id_aula
JOIN horario h ON sc.id_horario = h.id_horario;
```

---

## 2. FUNCIONES ALMACENADAS (14 Funciones de sistemaacademicooficial.sql)

### 2.1 fn_aula_disponible
Verifica disponibilidad de un aula en un horario y gestión.
```sql
CREATE FUNCTION `fn_aula_disponible` (`p_id_aula` INT, `p_id_horario` INT, `p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM se_cursa sc
    JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo
    WHERE sc.id_aula = p_id_aula AND sc.id_horario = p_id_horario AND p.id_gestion = p_id_gestion;
    RETURN v_count = 0;
END$$
```

### 2.2 fn_calcular_nota_final
Calcula la suma de notas por detalle de inscripción ponderando los criterios.
```sql
CREATE FUNCTION `fn_calcular_nota_final` (`p_id_detalle` INT) RETURNS FLOAT DETERMINISTIC BEGIN
    DECLARE v_total FLOAT DEFAULT 0;
    SELECT COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) INTO v_total
    FROM nota n
    JOIN criterio_evaluacion ce ON n.id_criterio = ce.id_criterio
    WHERE n.id_detalle = p_id_detalle;
    RETURN v_total;
END$$
```

### 2.3 fn_cupo_disponible
Verifica si el cupo actual de un paralelo es menor a su cupo máximo.
```sql
CREATE FUNCTION `fn_cupo_disponible` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_max INT;
    DECLARE v_actual INT;
    SELECT cupo_maximo, cupo_actual INTO v_max, v_actual FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
    RETURN v_actual < v_max;
END$$
```

### 2.4 fn_existe_estudiante
Valida la existencia de un estudiante por id_persona.
```sql
CREATE FUNCTION `fn_existe_estudiante` (`p_id_estudiante` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM ESTUDIANTE WHERE id_persona = p_id_estudiante;
    RETURN v_existe > 0;
END$$
```

### 2.5 fn_existe_gestion
Valida la existencia de una gestión.
```sql
CREATE FUNCTION `fn_existe_gestion` (`p_id_gestion` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM GESTION WHERE id_gestion = p_id_gestion;
    RETURN v_existe > 0;
END$$
```

### 2.6 fn_existe_materia
Valida la existencia de una materia.
```sql
CREATE FUNCTION `fn_existe_materia` (`p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM MATERIA WHERE id_materia = p_id_materia;
    RETURN v_existe > 0;
END$$
```

### 2.7 fn_existe_paralelo
Valida la existencia de un paralelo.
```sql
CREATE FUNCTION `fn_existe_paralelo` (`p_id_materia` INT, `p_id_paralelo` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT;
    SELECT COUNT(*) INTO v_existe FROM PARALELO WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
    RETURN v_existe > 0;
END$$
```

### 2.8 fn_extraer_numero_ci
Filtra únicamente los caracteres numéricos de un CI.
```sql
CREATE FUNCTION `fn_extraer_numero_ci` (`p_ci` VARCHAR(20)) RETURNS VARCHAR(20) DETERMINISTIC BEGIN
    DECLARE v_result VARCHAR(20) DEFAULT '';
    DECLARE v_char CHAR(1);
    DECLARE v_i INT DEFAULT 1;
    WHILE v_i <= LENGTH(p_ci) DO
        SET v_char = SUBSTRING(p_ci, v_i, 1);
        IF v_char REGEXP '[0-9]' THEN
            SET v_result = CONCAT(v_result, v_char);
        END IF;
        SET v_i = v_i + 1;
    END WHILE;
    IF v_result = '' THEN
        SET v_result = '123456';
    END IF;
    RETURN v_result;
END$$
```

### 2.9 fn_generar_email
Genera la dirección de correo institucional `@fcpn.edu.bo`.
```sql
CREATE FUNCTION `fn_generar_email` (`p_username` VARCHAR(50)) RETURNS VARCHAR(100) DETERMINISTIC BEGIN
    RETURN CONCAT(LOWER(p_username), '@fcpn.edu.bo');
END$$
```

### 2.10 fn_generar_username
Genera un username único a partir de los nombres y apellidos resolviendo colisiones.
```sql
CREATE FUNCTION `fn_generar_username` (`p_nombres` VARCHAR(80), `p_apellidos` VARCHAR(80)) RETURNS VARCHAR(50) DETERMINISTIC BEGIN
    DECLARE v_primer_nombre VARCHAR(40);
    DECLARE v_primer_apellido VARCHAR(40);
    DECLARE v_base VARCHAR(50);
    DECLARE v_username VARCHAR(50);
    DECLARE v_counter INT DEFAULT 1;
    DECLARE v_count INT;
    
    SET v_primer_nombre = LOWER(SUBSTRING_INDEX(TRIM(p_nombres), ' ', 1));
    SET v_primer_apellido = LOWER(SUBSTRING_INDEX(TRIM(p_apellidos), ' ', 1));
    
    SET v_primer_nombre = REGEXP_REPLACE(v_primer_nombre, '[áàäâ]', 'a');
    SET v_primer_nombre = REGEXP_REPLACE(v_primer_nombre, '[éèëê]', 'e');
    SET v_primer_nombre = REGEXP_REPLACE(v_primer_nombre, '[íìïî]', 'i');
    SET v_primer_nombre = REGEXP_REPLACE(v_primer_nombre, '[óòöô]', 'o');
    SET v_primer_nombre = REGEXP_REPLACE(v_primer_nombre, '[úùüû]', 'u');
    SET v_primer_nombre = REGEXP_REPLACE(v_primer_nombre, '[ñ]', 'n');
    
    SET v_primer_apellido = REGEXP_REPLACE(v_primer_apellido, '[áàäâ]', 'a');
    SET v_primer_apellido = REGEXP_REPLACE(v_primer_apellido, '[éèëê]', 'e');
    SET v_primer_apellido = REGEXP_REPLACE(v_primer_apellido, '[íìïî]', 'i');
    SET v_primer_apellido = REGEXP_REPLACE(v_primer_apellido, '[óòöô]', 'o');
    SET v_primer_apellido = REGEXP_REPLACE(v_primer_apellido, '[úùüû]', 'u');
    SET v_primer_apellido = REGEXP_REPLACE(v_primer_apellido, '[ñ]', 'n');
    
    SET v_base = CONCAT(SUBSTRING(v_primer_nombre, 1, 1), v_primer_apellido);
    SET v_username = v_base;
    
    SELECT COUNT(*) INTO v_count FROM usuario WHERE username = v_username;
    WHILE v_count > 0 DO
        SET v_username = CONCAT(v_base, v_counter);
        SET v_counter = v_counter + 1;
        SELECT COUNT(*) INTO v_count FROM usuario WHERE username = v_username;
    END WHILE;
    
    RETURN v_username;
END$$
```

### 2.11 fn_materia_aprobada
Verifica si un estudiante tiene aprobada una materia.
```sql
CREATE FUNCTION `fn_materia_aprobada` (`p_id_estudiante` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_aprobado INT DEFAULT 0;
    SELECT COUNT(*) INTO v_aprobado
    FROM detalle_inscripcion d
    JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
    WHERE i.id_estudiante = p_id_estudiante 
      AND d.id_materia = p_id_materia 
      AND (d.nota_final >= 51 OR d.estado = 'Aprobado');
    RETURN v_aprobado > 0;
END$$
```

### 2.12 fn_nombre_completo
Concatena nombres y apellidos de persona.
```sql
CREATE FUNCTION `fn_nombre_completo` (`p_id_persona` INT) RETURNS VARCHAR(200) DETERMINISTIC BEGIN
    DECLARE v_nombre VARCHAR(200);
    SELECT CONCAT(nombres, ' ', apellidos) INTO v_nombre FROM PERSONA WHERE id_persona = p_id_persona;
    RETURN COALESCE(v_nombre, 'Desconocido');
END$$
```

### 2.13 fn_tiene_prerrequisitos
Verifica si un estudiante cumple todos los prerrequisitos de una materia.
```sql
CREATE FUNCTION `fn_tiene_prerrequisitos` (`p_id_estudiante` INT, `p_id_plan` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
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

### 2.14 fn_ya_inscrito
Determina si un estudiante ya está inscrito activamente en una materia.
```sql
CREATE FUNCTION `fn_ya_inscrito` (`p_id_estudiante` INT, `p_id_gestion` INT, `p_id_materia` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO v_existe 
    FROM inscripcion i 
    INNER JOIN detalle_inscripcion d ON i.id_inscripcion = d.id_inscripcion 
    WHERE i.id_estudiante = p_id_estudiante 
      AND i.id_gestion = p_id_gestion 
      AND d.id_materia = p_id_materia
      AND d.estado = 'Inscrito';
    RETURN (v_existe > 0);
END$$
```

---

## 3. PROCEDIMIENTOS ALMACENADOS (68 Procedimientos Oficiales)

### 3.1 sp_actualizar_aula
```sql
CREATE PROCEDURE `sp_actualizar_aula` (IN `p_id_aula` INT, IN `p_nombre` VARCHAR(50), IN `p_piso` VARCHAR(20), IN `p_ubicacion` VARCHAR(100), IN `p_capacidad` INT)   BEGIN
    UPDATE aula SET nombre = p_nombre, piso = p_piso, ubicacion = p_ubicacion, capacidad = p_capacidad WHERE id_aula = p_id_aula;
END$$
```

### 3.2 sp_actualizar_carrera
```sql
CREATE PROCEDURE `sp_actualizar_carrera` (IN `p_id_carrera` INT, IN `p_nombre` VARCHAR(100))   BEGIN
    UPDATE carrera SET nombre = p_nombre WHERE id_carrera = p_id_carrera;
END$$
```

### 3.3 sp_actualizar_criterio
```sql
CREATE PROCEDURE `sp_actualizar_criterio` (IN `p_id_criterio` INT, IN `p_nombre` VARCHAR(50), IN `p_ponderacion` FLOAT)   BEGIN
    UPDATE criterio_evaluacion SET nombre = p_nombre, ponderacion = p_ponderacion WHERE id_criterio = p_id_criterio;
END$$
```

### 3.4 sp_actualizar_gestion
```sql
CREATE PROCEDURE `sp_actualizar_gestion` (IN `p_id_gestion` INT, IN `p_periodo` VARCHAR(20))   BEGIN
    UPDATE gestion SET periodo = p_periodo WHERE id_gestion = p_id_gestion;
END$$
```

### 3.5 sp_actualizar_horario
```sql
CREATE PROCEDURE `sp_actualizar_horario` (IN `p_id_horario` INT, IN `p_dia` VARCHAR(15), IN `p_hora_inicio` TIME, IN `p_hora_fin` TIME)   BEGIN
    UPDATE horario SET dia = p_dia, hora_inicio = p_hora_inicio, hora_fin = p_hora_fin WHERE id_horario = p_id_horario;
END$$
```

### 3.6 sp_actualizar_materia
```sql
CREATE PROCEDURE `sp_actualizar_materia` (IN `p_id` INT, IN `p_sigla` VARCHAR(15), IN `p_nombre` VARCHAR(100), IN `p_carga_horaria` INT)   BEGIN
    UPDATE materia SET sigla = p_sigla, nombre = p_nombre, carga_horaria = p_carga_horaria WHERE id_materia = p_id;
END$$
```

### 3.7 sp_actualizar_nota
```sql
CREATE PROCEDURE `sp_actualizar_nota` (IN `p_id_nota` INT, IN `p_puntaje` FLOAT)   BEGIN
    UPDATE nota SET nota_obtenida = p_puntaje WHERE id_nota = p_id_nota;
END$$
```

### 3.8 sp_actualizar_paralelo
```sql
CREATE PROCEDURE `sp_actualizar_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT)   BEGIN
    UPDATE paralelo
    SET nombre = p_nombre, cupo_maximo = p_cupo_maximo, id_docente = p_id_docente, id_gestion = p_id_gestion
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$
```

### 3.9 sp_actualizar_plan_estudio
```sql
CREATE PROCEDURE `sp_actualizar_plan_estudio` (IN `p_id_plan` INT, IN `p_nombre` VARCHAR(100), IN `p_id_carrera` INT)   BEGIN
    UPDATE plan_estudio SET nombre = p_nombre, id_carrera = p_id_carrera WHERE id_plan = p_id_plan;
END$$
```

### 3.10 sp_actualizar_plan_materia
```sql
CREATE PROCEDURE `sp_actualizar_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_semestre` INT)   BEGIN
    UPDATE plan_materia SET semestre = p_semestre WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$
```

### 3.11 sp_actualizar_prerequisito
```sql
CREATE PROCEDURE `sp_actualizar_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_old_req` INT, IN `p_new_req` INT)   BEGIN
    UPDATE prerequisito SET id_materia_req = p_new_req WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_old_req;
END$$
```

### 3.12 sp_actualizar_se_cursa
```sql
CREATE PROCEDURE `sp_actualizar_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_old_aula` INT, IN `p_old_horario` INT, IN `p_new_aula` INT, IN `p_new_horario` INT)   BEGIN
    UPDATE se_cursa SET id_aula = p_new_aula, id_horario = p_new_horario
    WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_old_aula AND id_horario = p_old_horario;
END$$
```

### 3.13 sp_aperturar_paralelo_completo
```sql
CREATE PROCEDURE `sp_aperturar_paralelo_completo` (IN `p_id_materia` INT, IN `p_nombre_paralelo` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    DECLARE v_id_paralelo INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT COALESCE(MAX(id_paralelo), 0) + 1 INTO v_id_paralelo FROM paralelo WHERE id_materia = p_id_materia;
    INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
    VALUES (p_id_materia, v_id_paralelo, p_nombre_paralelo, p_cupo_maximo, 0, p_id_docente, p_id_gestion);
    INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario)
    VALUES (p_id_materia, v_id_paralelo, p_id_aula, p_id_horario);
    COMMIT;
    SELECT v_id_paralelo AS id_paralelo_generado;
END$$
```

### 3.14 sp_asignar_aulas_horarios_con_reintentos
```sql
CREATE PROCEDURE `sp_asignar_aulas_horarios_con_reintentos` (IN `p_id_gestion` INT, IN `p_max_intentos` INT)   BEGIN
    DECLARE v_id_materia INT;
    DECLARE v_id_paralelo INT;
    DECLARE v_id_aula INT;
    DECLARE v_id_horario INT;
    DECLARE v_intentos INT;
    DECLARE v_finished INT DEFAULT 0;
    DECLARE v_exito INT DEFAULT 0;
    DECLARE v_total_paralelos INT DEFAULT 0;
    DECLARE v_asignados INT DEFAULT 0;
    DECLARE v_error_msg VARCHAR(255);
    DECLARE cur_paralelos CURSOR FOR SELECT id_materia, id_paralelo FROM paralelo WHERE id_gestion = p_id_gestion ORDER BY id_materia, id_paralelo;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT COUNT(*) INTO v_total_paralelos FROM paralelo WHERE id_gestion = p_id_gestion;
    IF v_total_paralelos = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay paralelos en la gestion especificada.'; END IF;
    OPEN cur_paralelos;
    loop_paralelos: LOOP
        FETCH cur_paralelos INTO v_id_materia, v_id_paralelo;
        IF v_finished = 1 THEN LEAVE loop_paralelos; END IF;
        SET v_exito = 0; SET v_intentos = 0;
        WHILE v_exito = 0 AND v_intentos < p_max_intentos DO
            SET v_intentos = v_intentos + 1;
            SELECT id_aula INTO v_id_aula FROM aula ORDER BY RAND() LIMIT 1;
            SELECT id_horario INTO v_id_horario FROM horario ORDER BY RAND() LIMIT 1;
            IF NOT EXISTS (SELECT 1 FROM se_cursa sc JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo WHERE sc.id_aula = v_id_aula AND sc.id_horario = v_id_horario AND p.id_gestion = p_id_gestion) THEN
                IF NOT EXISTS (SELECT 1 FROM se_cursa sc JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo JOIN paralelo p_actual ON v_id_materia = p_actual.id_materia AND v_id_paralelo = p_actual.id_paralelo WHERE p.id_docente = p_actual.id_docente AND sc.id_horario = v_id_horario AND p.id_gestion = p_id_gestion) THEN
                    SET v_exito = 1;
                END IF;
            END IF;
        END WHILE;
        IF v_exito = 0 THEN
            SET v_error_msg = CONCAT('No se pudo asignar aula/horario despues de ', CAST(p_max_intentos AS CHAR), ' intentos para materia ID=', CAST(v_id_materia AS CHAR), ' paralelo=', CAST(v_id_paralelo AS CHAR));
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
        END IF;
        INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) VALUES (v_id_materia, v_id_paralelo, v_id_aula, v_id_horario) ON DUPLICATE KEY UPDATE id_aula = VALUES(id_aula), id_horario = VALUES(id_horario);
        SET v_asignados = v_asignados + 1;
    END LOOP;
    CLOSE cur_paralelos;
    COMMIT;
    SELECT p_id_gestion AS id_gestion, v_total_paralelos AS total_paralelos, v_asignados AS asignados_exitosos, p_max_intentos AS max_intentos_por_paralelo;
END$$
```

### 3.15 sp_asignar_horarios_sin_choque
```sql
CREATE PROCEDURE `sp_asignar_horarios_sin_choque` (IN `p_id_gestion` INT)   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_materia INT; DECLARE v_id_paralelo INT; DECLARE v_id_aula INT; DECLARE v_id_horario INT; DECLARE v_intentos INT; DECLARE v_asignado INT; DECLARE v_conflicto INT; DECLARE v_periodo VARCHAR(50) DEFAULT ''; DECLARE v_es_temporada INT DEFAULT 0; DECLARE v_hora_ini TIME; DECLARE v_hora_fin TIME;
    DECLARE cur_paralelos CURSOR FOR SELECT p.id_materia, p.id_paralelo FROM paralelo p WHERE p.id_gestion = p_id_gestion;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SELECT periodo INTO v_periodo FROM gestion WHERE id_gestion = p_id_gestion;
    IF v_periodo LIKE 'Invierno%' OR v_periodo LIKE 'Verano%' THEN SET v_es_temporada = 1; END IF;
    OPEN cur_paralelos;
    read_loop: LOOP
        FETCH cur_paralelos INTO v_id_materia, v_id_paralelo;
        IF done THEN LEAVE read_loop; END IF;
        IF NOT EXISTS (SELECT 1 FROM se_cursa WHERE id_materia = v_id_materia AND id_paralelo = v_id_paralelo) THEN
            SET v_intentos = 0; SET v_asignado = 0;
            while_loop: WHILE v_intentos < 100 AND v_asignado = 0 DO
                SET v_intentos = v_intentos + 1;
                SELECT id_aula INTO v_id_aula FROM aula ORDER BY RAND() LIMIT 1;
                IF v_es_temporada = 1 THEN
                    SELECT DISTINCT hora_inicio, hora_fin INTO v_hora_ini, v_hora_fin FROM horario WHERE TIMESTAMPDIFF(HOUR, hora_inicio, hora_fin) = 4 ORDER BY RAND() LIMIT 1;
                    SELECT COUNT(*) INTO v_conflicto FROM se_cursa sc JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo JOIN paralelo p_actual ON p_actual.id_materia = v_id_materia AND p_actual.id_paralelo = v_id_paralelo AND p_actual.id_gestion = p_id_gestion JOIN horario h ON sc.id_horario = h.id_horario WHERE p.id_gestion = p_id_gestion AND h.hora_inicio = v_hora_ini AND h.hora_fin = v_hora_fin AND (sc.id_aula = v_id_aula OR (p_actual.id_docente IS NOT NULL AND p.id_docente = p_actual.id_docente AND (sc.id_materia != v_id_materia OR sc.id_paralelo != v_id_paralelo)));
                    IF v_conflicto = 0 THEN
                        INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) SELECT v_id_materia, v_id_paralelo, v_id_aula, h.id_horario FROM horario h WHERE h.hora_inicio = v_hora_ini AND h.hora_fin = v_hora_fin AND h.dia IN ('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes');
                        SET v_asignado = 1;
                    END IF;
                ELSE
                    SELECT id_horario INTO v_id_horario FROM horario WHERE TIMESTAMPDIFF(HOUR, hora_inicio, hora_fin) = 2 ORDER BY RAND() LIMIT 1;
                    SELECT COUNT(*) INTO v_conflicto FROM se_cursa sc JOIN paralelo p ON sc.id_materia = p.id_materia AND sc.id_paralelo = p.id_paralelo JOIN paralelo p_actual ON p_actual.id_materia = v_id_materia AND p_actual.id_paralelo = v_id_paralelo AND p_actual.id_gestion = p_id_gestion WHERE p.id_gestion = p_id_gestion AND sc.id_horario = v_id_horario AND (sc.id_aula = v_id_aula OR (p_actual.id_docente IS NOT NULL AND p.id_docente = p_actual.id_docente AND (sc.id_materia != v_id_materia OR sc.id_paralelo != v_id_paralelo)));
                    IF v_conflicto = 0 THEN
                        INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) VALUES (v_id_materia, v_id_paralelo, v_id_aula, v_id_horario);
                        SET v_asignado = 1;
                    END IF;
                END IF;
            END WHILE;
        END IF;
    END LOOP;
    CLOSE cur_paralelos;
END$$
```

### 3.16 sp_cerrar_gestion
```sql
CREATE PROCEDURE `sp_cerrar_gestion` (IN `p_id_gestion` INT)   BEGIN
    DECLARE v_estado_gestion VARCHAR(20); DECLARE v_total_afectados INT DEFAULT 0; DECLARE v_aprobados INT DEFAULT 0; DECLARE v_reprobados INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT estado INTO v_estado_gestion FROM gestion WHERE id_gestion = p_id_gestion;
    IF v_estado_gestion IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La gestión no existe.'; END IF;
    IF v_estado_gestion = 'Cerrada' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La gestión ya está cerrada.'; END IF;
    UPDATE detalle_inscripcion di JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion LEFT JOIN (SELECT n.id_detalle, SUM(n.nota_obtenida * ce.ponderacion / 100) AS nota_calculada FROM nota n JOIN criterio_evaluacion ce ON n.id_criterio = ce.id_criterio GROUP BY n.id_detalle) AS calculo ON di.id_detalle = calculo.id_detalle SET di.nota_final = COALESCE(calculo.nota_calculada, 0), di.estado = CASE WHEN COALESCE(calculo.nota_calculada, 0) >= 51 THEN 'Aprobado' ELSE 'Reprobado' END WHERE i.id_gestion = p_id_gestion AND di.estado = 'Inscrito';
    SELECT ROW_COUNT() INTO v_total_afectados;
    SELECT COALESCE(SUM(CASE WHEN di.estado = 'Aprobado' THEN 1 ELSE 0 END), 0), COALESCE(SUM(CASE WHEN di.estado = 'Reprobado' THEN 1 ELSE 0 END), 0) INTO v_aprobados, v_reprobados FROM detalle_inscripcion di JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion WHERE i.id_gestion = p_id_gestion AND (di.estado = 'Aprobado' OR di.estado = 'Reprobado');
    UPDATE gestion SET estado = 'Cerrada' WHERE id_gestion = p_id_gestion;
    COMMIT;
    SELECT g.periodo AS periodo, v_total_afectados AS total_procesados, v_aprobados AS aprobados, v_reprobados AS reprobados, 'Cerrada' AS nuevo_estado FROM gestion g WHERE g.id_gestion = p_id_gestion;
END$$
```

### 3.17 sp_crear_aula
```sql
CREATE PROCEDURE `sp_crear_aula` (IN `p_nombre` VARCHAR(50), IN `p_piso` VARCHAR(20), IN `p_ubicacion` VARCHAR(100), IN `p_capacidad` INT)   BEGIN
    INSERT INTO aula (nombre, piso, ubicacion, capacidad) VALUES (p_nombre, p_piso, p_ubicacion, p_capacidad);
END$$
```

### 3.18 sp_crear_carrera
```sql
CREATE PROCEDURE `sp_crear_carrera` (IN `p_nombre` VARCHAR(100))   BEGIN
    INSERT INTO carrera (nombre) VALUES (p_nombre);
    SELECT LAST_INSERT_ID() AS id_carrera;
END$$
```

### 3.19 sp_crear_criterio
```sql
CREATE PROCEDURE `sp_crear_criterio` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(50), IN `p_ponderacion` FLOAT)   BEGIN
    INSERT INTO criterio_evaluacion (id_materia, id_paralelo, nombre, ponderacion) VALUES (p_id_materia, p_id_paralelo, p_nombre, p_ponderacion);
END$$
```

### 3.20 sp_crear_gestion
```sql
CREATE PROCEDURE `sp_crear_gestion` (IN `p_periodo` VARCHAR(20))   BEGIN
    INSERT INTO gestion (periodo, estado) VALUES (p_periodo, 'Inactiva');
END$$
```

### 3.21 sp_crear_horario
```sql
CREATE PROCEDURE `sp_crear_horario` (IN `p_dia` VARCHAR(15), IN `p_hora_inicio` TIME, IN `p_hora_fin` TIME)   BEGIN
    INSERT INTO horario (dia, hora_inicio, hora_fin) VALUES (p_dia, p_hora_inicio, p_hora_fin);
END$$
```

### 3.22 sp_crear_materia
```sql
CREATE PROCEDURE `sp_crear_materia` (IN `p_sigla` VARCHAR(15), IN `p_nombre` VARCHAR(100), IN `p_carga_horaria` INT)   BEGIN
    INSERT INTO materia (sigla, nombre, carga_horaria) VALUES (p_sigla, p_nombre, p_carga_horaria);
END$$
```

### 3.23 sp_crear_nota
```sql
CREATE PROCEDURE `sp_crear_nota` (IN `p_id_detalle` INT, IN `p_id_criterio` INT, IN `p_puntaje` FLOAT)   BEGIN
    INSERT INTO nota (id_detalle, id_criterio, nota_obtenida) VALUES (p_id_detalle, p_id_criterio, p_puntaje);
END$$
```

### 3.24 sp_crear_paralelo
```sql
CREATE PROCEDURE `sp_crear_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_nombre` VARCHAR(10), IN `p_cupo_maximo` INT, IN `p_id_docente` INT, IN `p_id_gestion` INT)   BEGIN
    INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
    VALUES (p_id_materia, p_id_paralelo, p_nombre, p_cupo_maximo, 0, p_id_docente, p_id_gestion);
END$$
```

### 3.25 sp_crear_plan_estudio
```sql
CREATE PROCEDURE `sp_crear_plan_estudio` (IN `p_nombre` VARCHAR(100), IN `p_id_carrera` INT)   BEGIN
    INSERT INTO plan_estudio (nombre, id_carrera) VALUES (p_nombre, p_id_carrera);
END$$
```

### 3.26 sp_crear_plan_materia
```sql
CREATE PROCEDURE `sp_crear_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_semestre` INT)   BEGIN
    INSERT INTO plan_materia (id_plan, id_materia, semestre) VALUES (p_id_plan, p_id_materia, p_semestre);
END$$
```

### 3.27 sp_crear_prerequisito
```sql
CREATE PROCEDURE `sp_crear_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_materia_req` INT)   BEGIN
    INSERT INTO prerequisito (id_plan, id_materia, id_materia_req) VALUES (p_id_plan, p_id_materia, p_id_materia_req);
END$$
```

### 3.28 sp_crear_se_cursa
```sql
CREATE PROCEDURE `sp_crear_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    INSERT INTO se_cursa (id_materia, id_paralelo, id_aula, id_horario) VALUES (p_id_materia, p_id_paralelo, p_id_aula, p_id_horario);
END$$
```

### 3.29 sp_eliminar_aula
```sql
CREATE PROCEDURE `sp_eliminar_aula` (IN `p_id_aula` INT)   BEGIN
    DELETE FROM aula WHERE id_aula = p_id_aula;
END$$
```

### 3.30 sp_eliminar_carrera
```sql
CREATE PROCEDURE `sp_eliminar_carrera` (IN `p_id_carrera` INT)   BEGIN
    DELETE FROM carrera WHERE id_carrera = p_id_carrera;
END$$
```

### 3.31 sp_eliminar_criterio
```sql
CREATE PROCEDURE `sp_eliminar_criterio` (IN `p_id_criterio` INT)   BEGIN
    DELETE FROM criterio_evaluacion WHERE id_criterio = p_id_criterio;
END$$
```

### 3.32 sp_eliminar_gestion
```sql
CREATE PROCEDURE `sp_eliminar_gestion` (IN `p_id_gestion` INT)   BEGIN
    DELETE FROM gestion WHERE id_gestion = p_id_gestion;
END$$
```

### 3.33 sp_eliminar_horario
```sql
CREATE PROCEDURE `sp_eliminar_horario` (IN `p_id_horario` INT)   BEGIN
    DELETE FROM horario WHERE id_horario = p_id_horario;
END$$
```

### 3.34 sp_eliminar_materia
```sql
CREATE PROCEDURE `sp_eliminar_materia` (IN `p_id` INT)   BEGIN
    DELETE FROM materia WHERE id_materia = p_id;
END$$
```

### 3.35 sp_eliminar_nota
```sql
CREATE PROCEDURE `sp_eliminar_nota` (IN `p_id_nota` INT)   BEGIN
    DELETE FROM nota WHERE id_nota = p_id_nota;
END$$
```

### 3.36 sp_eliminar_paralelo
```sql
CREATE PROCEDURE `sp_eliminar_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    DELETE FROM paralelo WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$
```

### 3.37 sp_eliminar_plan_estudio
```sql
CREATE PROCEDURE `sp_eliminar_plan_estudio` (IN `p_id_plan` INT)   BEGIN
    DELETE FROM plan_estudio WHERE id_plan = p_id_plan;
END$$
```

### 3.38 sp_eliminar_plan_materia
```sql
CREATE PROCEDURE `sp_eliminar_plan_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT)   BEGIN
    DELETE FROM plan_materia WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$
```

### 3.39 sp_eliminar_prerequisito
```sql
CREATE PROCEDURE `sp_eliminar_prerequisito` (IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_materia_req` INT)   BEGIN
    DELETE FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia AND id_materia_req = p_id_materia_req;
END$$
```

### 3.40 sp_eliminar_se_cursa
```sql
CREATE PROCEDURE `sp_eliminar_se_cursa` (IN `p_id_materia` INT, IN `p_id_paralelo` INT, IN `p_id_aula` INT, IN `p_id_horario` INT)   BEGIN
    DELETE FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_aula = p_id_aula AND id_horario = p_id_horario;
END$$
```

### 3.41 sp_insertar_estudiante_completo
```sql
CREATE PROCEDURE `sp_insertar_estudiante_completo` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_plan` INT, IN `p_anio_ingreso` VARCHAR(20))   BEGIN
    DECLARE v_id_persona INT; DECLARE v_ru INT; DECLARE v_email VARCHAR(100); DECLARE v_username VARCHAR(50); DECLARE v_id_usuario INT; DECLARE v_password_temp VARCHAR(255);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, NULL, 'A');
    SET v_id_persona = LAST_INSERT_ID();
    SELECT COALESCE(MAX(CAST(ru AS UNSIGNED)), 1005999) + 1 INTO v_ru FROM estudiante;
    INSERT INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (v_id_persona, v_ru, p_id_plan, p_anio_ingreso);
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    UPDATE persona SET email = v_email WHERE id_persona = v_id_persona;
    SET v_password_temp = CONCAT('$2b$10$e8w.n8U.Z9mX', v_username);
    INSERT INTO usuario (id_persona, username, password_hash, estado) VALUES (v_id_persona, v_username, v_password_temp, 'Activo');
    SET v_id_usuario = LAST_INSERT_ID();
    INSERT INTO tiene_rol (id_usuario, id_rol) VALUES (v_id_usuario, 3);
    COMMIT;
    SELECT v_id_persona AS id_persona, v_ru AS ru, v_username AS username, v_email AS email;
END$$
```

### 3.42 sp_insertar_estudiante_completo_seguro
```sql
CREATE PROCEDURE `sp_insertar_estudiante_completo_seguro` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_plan` INT, IN `p_anio_ingreso` VARCHAR(20), IN `p_password_hash` VARCHAR(255), IN `p_usuario_audit` INT)   BEGIN
    DECLARE v_id_persona INT; DECLARE v_ru INT; DECLARE v_email VARCHAR(100); DECLARE v_username VARCHAR(50); DECLARE v_id_usuario INT; DECLARE v_lock_obtained INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_lock_obtained = 1 THEN SELECT RELEASE_LOCK('lock_estudiante_ru'); END IF; ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SET @current_user_id = p_usuario_audit;
    SELECT GET_LOCK('lock_estudiante_ru', 10) INTO v_lock_obtained;
    IF v_lock_obtained = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se pudo obtener el bloqueo de concurrencia para RU.'; END IF;
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, NULL, 'A');
    SET v_id_persona = LAST_INSERT_ID();
    SELECT COALESCE(MAX(CAST(ru AS UNSIGNED)), 1005999) + 1 INTO v_ru FROM estudiante;
    INSERT INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (v_id_persona, v_ru, p_id_plan, p_anio_ingreso);
    SELECT RELEASE_LOCK('lock_estudiante_ru');
    SET v_lock_obtained = 0;
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    UPDATE persona SET email = v_email WHERE id_persona = v_id_persona;
    INSERT INTO usuario (id_persona, username, password_hash, estado) VALUES (v_id_persona, v_username, p_password_hash, 'Activo');
    SET v_id_usuario = LAST_INSERT_ID();
    INSERT INTO tiene_rol (id_usuario, id_rol) VALUES (v_id_usuario, 3);
    COMMIT;
    SELECT v_id_persona AS id_persona, v_ru AS ru, v_username AS username, v_email AS email;
END$$
```

### 3.43 sp_insertar_persona_usuario
```sql
CREATE PROCEDURE `sp_insertar_persona_usuario` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_rol` INT, IN `p_estado` VARCHAR(20))   BEGIN
    DECLARE v_id_persona INT; DECLARE v_email VARCHAR(100); DECLARE v_username VARCHAR(50); DECLARE v_id_usuario INT; DECLARE v_password_temp VARCHAR(255);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, NULL, p_estado);
    SET v_id_persona = LAST_INSERT_ID();
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    UPDATE persona SET email = v_email WHERE id_persona = v_id_persona;
    SET v_password_temp = CONCAT('$2b$10$e8w.n8U.Z9mX', v_username);
    INSERT INTO usuario (id_persona, username, password_hash, estado) VALUES (v_id_persona, v_username, v_password_temp, 'Activo');
    SET v_id_usuario = LAST_INSERT_ID();
    INSERT INTO tiene_rol (id_usuario, id_rol) VALUES (v_id_usuario, p_id_rol);
    IF p_id_rol = 2 THEN INSERT INTO docente (id_persona, registro_docente, grado_academico) VALUES (v_id_persona, NULL, 'Licenciado');
    ELSEIF p_id_rol = 4 THEN INSERT INTO administrativo (id_persona, cargo) VALUES (v_id_persona, 'Administrativo de Facultad'); END IF;
    COMMIT;
    SELECT v_id_persona AS id_persona, v_username AS username, v_email AS email;
END$$
```

### 3.44 sp_insertar_persona_usuario_seguro
```sql
CREATE PROCEDURE `sp_insertar_persona_usuario_seguro` (IN `p_ci` VARCHAR(20), IN `p_nombres` VARCHAR(80), IN `p_apellidos` VARCHAR(80), IN `p_fecha_nac` DATE, IN `p_sexo` VARCHAR(1), IN `p_id_rol` INT, IN `p_password_hash` VARCHAR(255), IN `p_usuario_audit` INT)   BEGIN
    DECLARE v_id_persona INT; DECLARE v_email VARCHAR(100); DECLARE v_username VARCHAR(50); DECLARE v_id_usuario INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SET @current_user_id = p_usuario_audit;
    INSERT INTO persona (ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (p_ci, p_nombres, p_apellidos, p_fecha_nac, p_sexo, NULL, 'A');
    SET v_id_persona = LAST_INSERT_ID();
    SET v_username = fn_generar_username(p_nombres, p_apellidos);
    SET v_email = fn_generar_email(v_username);
    UPDATE persona SET email = v_email WHERE id_persona = v_id_persona;
    INSERT INTO usuario (id_persona, username, password_hash, estado) VALUES (v_id_persona, v_username, p_password_hash, 'Activo');
    SET v_id_usuario = LAST_INSERT_ID();
    INSERT INTO tiene_rol (id_usuario, id_rol) VALUES (v_id_usuario, p_id_rol);
    IF p_id_rol = 2 THEN INSERT INTO docente (id_persona, registro_docente, grado_academico) VALUES (v_id_persona, NULL, 'Licenciado');
    ELSEIF p_id_rol = 4 THEN INSERT INTO administrativo (id_persona, cargo) VALUES (v_id_persona, 'Administrativo de Facultad'); END IF;
    COMMIT;
    SELECT v_id_persona AS id_persona, v_username AS username, v_email AS email;
END$$
```

### 3.45 sp_obtener_aulas
```sql
CREATE PROCEDURE `sp_obtener_aulas` ()   BEGIN
    SELECT * FROM aula;
END$$
```

### 3.46 sp_obtener_aula_por_id
```sql
CREATE PROCEDURE `sp_obtener_aula_por_id` (IN `p_id_aula` INT)   BEGIN
    SELECT * FROM aula WHERE id_aula = p_id_aula;
END$$
```

### 3.47 sp_obtener_carreras
```sql
CREATE PROCEDURE `sp_obtener_carreras` ()   BEGIN
    SELECT * FROM carrera;
END$$
```

### 3.48 sp_obtener_carrera_por_id
```sql
CREATE PROCEDURE `sp_obtener_carrera_por_id` (IN `p_id_carrera` INT)   BEGIN
    SELECT * FROM carrera WHERE id_carrera = p_id_carrera;
END$$
```

### 3.49 sp_obtener_criterios_paralelo
```sql
CREATE PROCEDURE `sp_obtener_criterios_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    SELECT * FROM criterio_evaluacion WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$
```

### 3.50 sp_obtener_gestiones
```sql
CREATE PROCEDURE `sp_obtener_gestiones` ()   BEGIN
    SELECT * FROM gestion;
END$$
```

### 3.51 sp_obtener_horarios
```sql
CREATE PROCEDURE `sp_obtener_horarios` ()   BEGIN
    SELECT * FROM horario;
END$$
```

### 3.52 sp_obtener_horario_por_id
```sql
CREATE PROCEDURE `sp_obtener_horario_por_id` (IN `p_id_horario` INT)   BEGIN
    SELECT * FROM horario WHERE id_horario = p_id_horario;
END$$
```

### 3.53 sp_obtener_materias
```sql
CREATE PROCEDURE `sp_obtener_materias` ()   BEGIN
    SELECT * FROM materia;
END$$
```

### 3.54 sp_obtener_materias_por_plan
```sql
CREATE PROCEDURE `sp_obtener_materias_por_plan` (IN `p_id_plan` INT)   BEGIN
    SELECT * FROM plan_materia WHERE id_plan = p_id_plan;
END$$
```

### 3.55 sp_obtener_materia_por_id
```sql
CREATE PROCEDURE `sp_obtener_materia_por_id` (IN `p_id` INT)   BEGIN
    SELECT * FROM materia WHERE id_materia = p_id;
END$$
```

### 3.56 sp_obtener_notas_detalle
```sql
CREATE PROCEDURE `sp_obtener_notas_detalle` (IN `p_id_detalle` INT)   BEGIN
    SELECT * FROM nota WHERE id_detalle = p_id_detalle;
END$$
```

### 3.57 sp_obtener_paralelos
```sql
CREATE PROCEDURE `sp_obtener_paralelos` ()   BEGIN
    SELECT p.id_materia, p.id_paralelo, p.nombre, p.cupo_maximo,
        COALESCE((SELECT COUNT(*) FROM detalle_inscripcion d JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion WHERE d.id_materia = p.id_materia AND d.id_paralelo = p.id_paralelo AND i.id_gestion = p.id_gestion AND d.estado = 'Inscrito'), 0) AS cupo_actual,
        GREATEST(0, p.cupo_maximo - COALESCE((SELECT COUNT(*) FROM detalle_inscripcion d JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion WHERE d.id_materia = p.id_materia AND d.id_paralelo = p.id_paralelo AND i.id_gestion = p.id_gestion AND d.estado = 'Inscrito'), 0)) AS cupo_disponible,
        p.id_docente, p.id_gestion
    FROM paralelo p;
END$$
```

### 3.58 sp_obtener_planes_estudio
```sql
CREATE PROCEDURE `sp_obtener_planes_estudio` ()   BEGIN
    SELECT * FROM plan_estudio;
END$$
```

### 3.59 sp_obtener_plan_estudio_por_id
```sql
CREATE PROCEDURE `sp_obtener_plan_estudio_por_id` (IN `p_id_plan` INT)   BEGIN
    SELECT * FROM plan_estudio WHERE id_plan = p_id_plan;
END$$
```

### 3.60 sp_obtener_plan_materias
```sql
CREATE PROCEDURE `sp_obtener_plan_materias` ()   BEGIN
    SELECT * FROM plan_materia;
END$$
```

### 3.61 sp_obtener_prerequisitos
```sql
CREATE PROCEDURE `sp_obtener_prerequisitos` ()   BEGIN
    SELECT * FROM prerequisito;
END$$
```

### 3.62 sp_obtener_prerequisitos_materia
```sql
CREATE PROCEDURE `sp_obtener_prerequisitos_materia` (IN `p_id_plan` INT, IN `p_id_materia` INT)   BEGIN
    SELECT * FROM prerequisito WHERE id_plan = p_id_plan AND id_materia = p_id_materia;
END$$
```

### 3.63 sp_obtener_se_cursa
```sql
CREATE PROCEDURE `sp_obtener_se_cursa` ()   BEGIN
    SELECT * FROM se_cursa;
END$$
```

### 3.64 sp_obtener_se_cursa_por_paralelo
```sql
CREATE PROCEDURE `sp_obtener_se_cursa_por_paralelo` (IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    SELECT * FROM se_cursa WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo;
END$$
```

### 3.65 sp_preview_cierre_gestion
```sql
CREATE PROCEDURE `sp_preview_cierre_gestion` (IN `p_id_gestion` INT)   BEGIN
    DECLARE v_total INT DEFAULT 0; DECLARE v_aprobados INT DEFAULT 0; DECLARE v_reprobados INT DEFAULT 0; DECLARE v_periodo VARCHAR(20);
    SELECT periodo INTO v_periodo FROM gestion WHERE id_gestion = p_id_gestion;
    IF v_periodo IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La gestión no existe.'; END IF;
    SELECT COUNT(*), COALESCE(SUM(CASE WHEN nota_proyectada >= 51 THEN 1 ELSE 0 END), 0), COALESCE(SUM(CASE WHEN nota_proyectada < 51 THEN 1 ELSE 0 END), 0)
    INTO v_total, v_aprobados, v_reprobados
    FROM (SELECT di.id_detalle, COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) AS nota_proyectada FROM detalle_inscripcion di JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion JOIN gestion g ON i.id_gestion = g.id_gestion LEFT JOIN criterio_evaluacion ce ON di.id_materia = ce.id_materia AND di.id_paralelo = ce.id_paralelo LEFT JOIN nota n ON di.id_detalle = n.id_detalle AND ce.id_criterio = n.id_criterio WHERE i.id_gestion = p_id_gestion AND di.estado = 'Inscrito' AND g.estado = 'Activa' GROUP BY di.id_detalle) AS t;
    SELECT v_periodo AS periodo, v_total AS total, v_aprobados AS aprobados, v_reprobados AS reprobados;
    SELECT CONCAT(p.nombres, ' ', p.apellidos) AS estudiante, e.ru AS ru, m.sigla AS sigla_materia, m.nombre AS materia, COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) AS nota_final_proyectada, CASE WHEN COALESCE(SUM(n.nota_obtenida * ce.ponderacion / 100), 0) >= 51 THEN 'Aprobado' ELSE 'Reprobado' END AS estado_proyectado FROM detalle_inscripcion di JOIN inscripcion i ON di.id_inscripcion = i.id_inscripcion JOIN gestion g ON i.id_gestion = g.id_gestion JOIN estudiante e ON i.id_estudiante = e.id_persona JOIN persona p ON e.id_persona = p.id_persona JOIN materia m ON di.id_materia = m.id_materia LEFT JOIN criterio_evaluacion ce ON di.id_materia = ce.id_materia AND di.id_paralelo = ce.id_paralelo LEFT JOIN nota n ON di.id_detalle = n.id_detalle AND ce.id_criterio = n.id_criterio WHERE i.id_gestion = p_id_gestion AND di.estado = 'Inscrito' AND g.estado = 'Activa' GROUP BY di.id_detalle, p.nombres, p.apellidos, e.ru, m.sigla, m.nombre ORDER BY p.apellidos, p.nombres, m.nombre;
END$$
```

### 3.66 sp_realizar_inscripcion
```sql
CREATE PROCEDURE `sp_realizar_inscripcion` (IN `p_id_estudiante` INT, IN `p_id_gestion` INT, IN `p_id_plan` INT, IN `p_id_materia` INT, IN `p_id_paralelo` INT)   BEGIN
    DECLARE v_id_inscripcion INT DEFAULT NULL; DECLARE v_cupo_max INT DEFAULT 35; DECLARE v_cupo_act INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    IF NOT fn_existe_estudiante(p_id_estudiante) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El estudiante no existe.'; END IF;
    IF NOT fn_existe_gestion(p_id_gestion) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La gestion no existe.'; END IF;
    IF NOT fn_existe_materia(p_id_materia) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La materia no existe.'; END IF;
    IF NOT EXISTS (SELECT 1 FROM paralelo WHERE id_materia = p_id_materia AND id_paralelo = p_id_paralelo AND id_gestion = p_id_gestion) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El paralelo no existe en la gestión seleccionada.'; END IF;
    IF fn_ya_inscrito(p_id_estudiante, p_id_gestion, p_id_materia) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El estudiante ya está inscrito en esa materia.'; END IF;
    IF NOT fn_tiene_prerrequisitos(p_id_estudiante, p_id_plan, p_id_materia) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No cumple los prerrequisitos de la materia.'; END IF;
    SELECT id_inscripcion INTO v_id_inscripcion FROM inscripcion WHERE id_estudiante = p_id_estudiante AND id_gestion = p_id_gestion LIMIT 1;
    IF v_id_inscripcion IS NULL THEN
        INSERT INTO inscripcion (id_estudiante, id_gestion, fecha_registro) VALUES (p_id_estudiante, p_id_gestion, CURDATE());
        SET v_id_inscripcion = LAST_INSERT_ID();
    END IF;
    INSERT INTO detalle_inscripcion (id_inscripcion, id_materia, id_paralelo, estado, nota_final) VALUES (v_id_inscripcion, p_id_materia, p_id_paralelo, 'Inscrito', 0);
    COMMIT;
END$$
```

### 3.67 sp_retirar_inscripcion
```sql
CREATE PROCEDURE `sp_retirar_inscripcion` (IN `p_id_detalle` INT)   BEGIN
    DECLARE v_id_materia INT; DECLARE v_id_paralelo INT; DECLARE v_id_gestion INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    IF NOT EXISTS(SELECT 1 FROM detalle_inscripcion WHERE id_detalle = p_id_detalle) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La inscripción no existe.'; END IF;
    SELECT d.id_materia, d.id_paralelo, i.id_gestion INTO v_id_materia, v_id_paralelo, v_id_gestion FROM detalle_inscripcion d JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion WHERE d.id_detalle = p_id_detalle LIMIT 1;
    DELETE FROM nota WHERE id_detalle = p_id_detalle;
    DELETE FROM detalle_inscripcion WHERE id_detalle = p_id_detalle;
    UPDATE paralelo SET cupo_actual = GREATEST(cupo_actual - 1, 0) WHERE id_materia = v_id_materia AND id_paralelo = v_id_paralelo AND id_gestion = v_id_gestion;
    COMMIT;
END$$
```

### 3.68 sp_set_audit_user
```sql
CREATE PROCEDURE `sp_set_audit_user` (IN `p_id_usuario` INT)   BEGIN
    SET @current_user_id = p_id_usuario;
END$$
```

---

## 4. CURSORES DE MANTENIMIENTO Y BATCH EN DBMS (14 Cursores)

> **Aclaración Técnica de Uso en Gestor de Base de Datos:**
> Los cursores detallados a continuación están diseñados para su ejecución iterativa en el Gestor de Base de Datos (DBMS MariaDB / MySQL) dentro de rutinas batch, scripts de mantenimiento, reportes consolidados masivos y migraciones nocturnas. **No son invocados directamente desde el backend de Node.js** para garantizar que la API REST se mantenga asíncrona, ligera y sin bloqueos de concurrencia.

### 4.1 cur_cierre_gestion
Recorre todas las inscripciones activas durante el cierre de gestión para consolidar las notas finales y definir la condición académica.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_cierre_gestion(IN p_id_gestion INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_detalle INT;
    DECLARE v_nota_calculada FLOAT;
    
    DECLARE cur_cierre CURSOR FOR 
        SELECT d.id_detalle 
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        WHERE i.id_gestion = p_id_gestion AND d.estado = 'Inscrito';
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_cierre;
    read_loop: LOOP
        FETCH cur_cierre INTO v_id_detalle;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_nota_calculada = fn_calcular_nota_final(v_id_detalle);
        
        UPDATE detalle_inscripcion
        SET nota_final = v_nota_calculada,
            estado = IF(v_nota_calculada >= 51, 'Aprobado', 'Reprobado')
        WHERE id_detalle = v_id_detalle;
    END LOOP;
    CLOSE cur_cierre;
END$$
DELIMITER ;
```

### 4.2 cur_promedios_estudiantes
Calcula los promedios globales de todos los estudiantes para generar el ranking de rendimiento.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_promedios_estudiantes()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_persona INT;
    DECLARE v_promedio FLOAT;
    
    DECLARE cur_promedios CURSOR FOR 
        SELECT id_persona FROM estudiante;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_promedios;
    read_loop: LOOP
        FETCH cur_promedios INTO v_id_persona;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COALESCE(AVG(d.nota_final), 0) INTO v_promedio
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        WHERE i.id_estudiante = v_id_persona AND (d.estado = 'Aprobado' OR d.estado = 'Reprobado');
        
        INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
        VALUES (1, 'CALCULO_PROMEDIO', CONCAT('Estudiante ID=', v_id_persona, ' Promedio=', v_promedio), CURDATE(), CURTIME());
    END LOOP;
    CLOSE cur_promedios;
END$$
DELIMITER ;
```

### 4.3 cur_auditoria_limpieza
Purga registros de auditoría antiguos almacenados en el servidor.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_auditoria_limpieza(IN p_dias_retencion INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_auditoria INT;
    
    DECLARE cur_audit CURSOR FOR 
        SELECT id_auditoria FROM auditoria 
        WHERE fecha < DATE_SUB(CURDATE(), INTERVAL p_dias_retencion DAY);
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_audit;
    read_loop: LOOP
        FETCH cur_audit INTO v_id_auditoria;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        DELETE FROM auditoria WHERE id_auditoria = v_id_auditoria;
    END LOOP;
    CLOSE cur_audit;
END$$
DELIMITER ;
```

### 4.4 cur_cupos_paralelos
Recalcula y sincroniza el número de cupos realmente ocupados en la tabla `paralelo`.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_sincronizar_cupos()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_materia INT;
    DECLARE v_paralelo INT;
    DECLARE v_gestion INT;
    DECLARE v_conteo INT;
    
    DECLARE cur_cupos CURSOR FOR 
        SELECT id_materia, id_paralelo, id_gestion FROM paralelo;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_cupos;
    read_loop: LOOP
        FETCH cur_cupos INTO v_materia, v_paralelo, v_gestion;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(DISTINCT i.id_estudiante) INTO v_conteo
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        WHERE d.id_materia = v_materia AND d.id_paralelo = v_paralelo AND i.id_gestion = v_gestion AND d.estado = 'Inscrito';
        
        UPDATE paralelo 
        SET cupo_actual = v_conteo 
        WHERE id_materia = v_materia AND id_paralelo = v_paralelo AND id_gestion = v_gestion;
    END LOOP;
    CLOSE cur_cupos;
END$$
DELIMITER ;
```

### 4.5 cur_docentes_carga
Examina la carga horaria y paralelos asignados a los profesores para evitar sobrecargas.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_verificar_carga_docentes(IN p_id_gestion INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_docente INT;
    DECLARE v_total_paralelos INT;
    
    DECLARE cur_docentes CURSOR FOR 
        SELECT id_persona FROM docente;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_docentes;
    read_loop: LOOP
        FETCH cur_docentes INTO v_id_docente;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(*) INTO v_total_paralelos
        FROM paralelo
        WHERE id_docente = v_id_docente AND id_gestion = p_id_gestion;
        
        IF v_total_paralelos > 3 THEN
            INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
            VALUES (1, 'ALERTA', CONCAT('Docente ID=', v_id_docente, ' excede paralelos permitidos: ', v_total_paralelos), CURDATE(), CURTIME());
        END IF;
    END LOOP;
    CLOSE cur_docentes;
END$$
DELIMITER ;
```

### 4.6 cur_verificacion_prerrequisitos
Audita masivamente que todos los alumnos inscritos cumplan con los prerrequisitos legales.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_auditar_prerrequisitos(IN p_id_gestion INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_estudiante INT;
    DECLARE v_materia INT;
    DECLARE v_plan INT;
    DECLARE v_cumple TINYINT(1);
    
    DECLARE cur_prereq CURSOR FOR 
        SELECT i.id_estudiante, d.id_materia, e.id_plan
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        JOIN estudiante e ON i.id_estudiante = e.id_persona
        WHERE i.id_gestion = p_id_gestion;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_prereq;
    read_loop: LOOP
        FETCH cur_prereq INTO v_estudiante, v_materia, v_plan;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_cumple = fn_tiene_prerrequisitos(v_estudiante, v_plan, v_materia);
        IF NOT v_cumple THEN
            INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
            VALUES (1, 'ADVERTENCIA', CONCAT('Inscripción observada por prerrequisitos - Estudiante ID=', v_estudiante, ' Materia=', v_materia), CURDATE(), CURTIME());
        END IF;
    END LOOP;
    CLOSE cur_prereq;
END$$
DELIMITER ;
```

### 4.7 cur_descuento_cupos
Procesa retiros masivos descontando el cupo del paralelo correspondiente.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_procesar_retiros_lote()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_detalle INT;
    DECLARE v_materia INT;
    DECLARE v_paralelo INT;
    
    DECLARE cur_retiros CURSOR FOR 
        SELECT id_detalle, id_materia, id_paralelo 
        FROM detalle_inscripcion 
        WHERE estado = 'Abandono';
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_retiros;
    read_loop: LOOP
        FETCH cur_retiros INTO v_id_detalle, v_materia, v_paralelo;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        UPDATE paralelo SET cupo_actual = GREATEST(cupo_actual - 1, 0)
        WHERE id_materia = v_materia AND id_paralelo = v_paralelo;
    END LOOP;
    CLOSE cur_retiros;
END$$
DELIMITER ;
```

### 4.8 cur_consolidacion_actas
Consolida los registros finales de calificaciones por materia.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_consolidar_actas(IN p_id_gestion INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_materia INT;
    DECLARE v_id_paralelo INT;
    DECLARE v_total_alumnos INT;
    DECLARE v_promedio_curso FLOAT;
    
    DECLARE cur_materias CURSOR FOR 
        SELECT DISTINCT id_materia, id_paralelo FROM paralelo WHERE id_gestion = p_id_gestion;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_materias;
    read_loop: LOOP
        FETCH cur_materias INTO v_id_materia, v_id_paralelo;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(*), COALESCE(AVG(d.nota_final), 0)
        INTO v_total_alumnos, v_promedio_curso
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        WHERE d.id_materia = v_id_materia AND d.id_paralelo = v_id_paralelo AND i.id_gestion = p_id_gestion;
        
        INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
        VALUES (1, 'ACTA_CONSOLIDADA', CONCAT('Materia ID=', v_id_materia, ' Paralelo=', v_id_paralelo, ' Alumnos=', v_total_alumnos, ' Promedio=', v_promedio_curso), CURDATE(), CURTIME());
    END LOOP;
    CLOSE cur_materias;
END$$
DELIMITER ;
```

### 4.9 cur_actualizacion_estados
Actualiza la condición académica global de los estudiantes al final del año lectivo.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_actualizar_estado_alumnos()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_persona INT;
    DECLARE v_aprobadas INT;
    DECLARE v_reprobadas INT;
    
    DECLARE cur_alumnos CURSOR FOR 
        SELECT id_persona FROM estudiante;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_alumnos;
    read_loop: LOOP
        FETCH cur_alumnos INTO v_id_persona;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT 
            SUM(CASE WHEN d.estado = 'Aprobado' THEN 1 ELSE 0 END),
            SUM(CASE WHEN d.estado = 'Reprobado' THEN 1 ELSE 0 END)
        INTO v_aprobadas, v_reprobadas
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        WHERE i.id_estudiante = v_id_persona;
        
        UPDATE persona 
        SET estado = IF(v_reprobadas > 5, 'I', 'A') 
        WHERE id_persona = v_id_persona;
    END LOOP;
    CLOSE cur_alumnos;
END$$
DELIMITER ;
```

### 4.10 cur_migracion_historica
Archiva registros de inscripciones antiguas a tablas históricas de respaldo.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_migrar_historico(IN p_gestion_cierre INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_inscripcion INT;
    DECLARE v_estudiante INT;
    DECLARE v_gestion INT;
    
    DECLARE cur_historico CURSOR FOR 
        SELECT id_inscripcion, id_estudiante, id_gestion FROM inscripcion WHERE id_gestion < p_gestion_cierre;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_historico;
    read_loop: LOOP
        FETCH cur_historico INTO v_id_inscripcion, v_estudiante, v_gestion;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
        VALUES (1, 'MIGRACION_HISTORICA', CONCAT('Inscripción archivada ID=', v_id_inscripcion, ' Estudiante=', v_estudiante, ' Gestión=', v_gestion), CURDATE(), CURTIME());
    END LOOP;
    CLOSE cur_historico;
END$$
DELIMITER ;
```

### 4.11 cur_alertas_reprobacion
Identifica estudiantes en situación de riesgo por múltiples materias reprobadas.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_detectar_reprobaciones_continuas()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_persona INT;
    DECLARE v_reprobadas INT;
    
    DECLARE cur_riesgo CURSOR FOR 
        SELECT id_persona FROM estudiante;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_riesgo;
    read_loop: LOOP
        FETCH cur_riesgo INTO v_id_persona;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(*) INTO v_reprobadas
        FROM detalle_inscripcion d
        JOIN inscripcion i ON d.id_inscripcion = i.id_inscripcion
        WHERE i.id_estudiante = v_id_persona AND d.estado = 'Reprobado';

        IF v_reprobadas >= 3 THEN
            INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
            VALUES (1, 'RIESGO_ACADEMICO', CONCAT('Estudiante ID=', v_id_persona, ' registra ', v_reprobadas, ' materias reprobadas.'), CURDATE(), CURTIME());
        END IF;
    END LOOP;
    CLOSE cur_riesgo;
END$$
DELIMITER ;
```

### 4.12 cur_resumen_carrera
Agrupa métricas estadísticas por programa de estudios.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_resumen_carreras()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_carrera INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_total_estud INT;
    
    DECLARE cur_carreras CURSOR FOR 
        SELECT id_carrera, nombre FROM carrera;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_carreras;
    read_loop: LOOP
        FETCH cur_carreras INTO v_id_carrera, v_nombre;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(*) INTO v_total_estud
        FROM estudiante e
        JOIN plan_estudio pe ON e.id_plan = pe.id_plan
        WHERE pe.id_carrera = v_id_carrera;

        INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
        VALUES (1, 'RESUMEN_CARRERA', CONCAT('Carrera: ', v_nombre, ' - Total Alumnos: ', v_total_estud), CURDATE(), CURTIME());
    END LOOP;
    CLOSE cur_carreras;
END$$
DELIMITER ;
```

### 4.13 cur_optimizacion_aulas
Examina el uso eficiente de la capacidad de los ambientes de clase.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_optimizar_aulas()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_aula INT;
    DECLARE v_numero VARCHAR(20);
    DECLARE v_capacidad INT;
    DECLARE v_uso_horas INT;
    
    DECLARE cur_aulas CURSOR FOR 
        SELECT id_aula, numero, capacidad FROM aula;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_aulas;
    read_loop: LOOP
        FETCH cur_aulas INTO v_id_aula, v_numero, v_capacidad;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(*) INTO v_uso_horas
        FROM se_cursa
        WHERE id_aula = v_id_aula;

        INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
        VALUES (1, 'USO_AULA', CONCAT('Aula ', v_numero, ' (Cap: ', v_capacidad, ') asignada en ', v_uso_horas, ' horarios.'), CURDATE(), CURTIME());
    END LOOP;
    CLOSE cur_aulas;
END$$
DELIMITER ;
```

### 4.14 cur_proyeccion_semestral
Calcula la demanda proyectada de vacantes para el ciclo académico subsiguiente.
```sql
DELIMITER $$
CREATE PROCEDURE sp_cursor_proyeccion_demanda(IN p_id_plan INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id_materia INT;
    DECLARE v_semestre INT;
    DECLARE v_demanda_estimada INT;
    
    DECLARE cur_plan CURSOR FOR 
        SELECT id_materia, semestre FROM plan_materia WHERE id_plan = p_id_plan;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_plan;
    read_loop: LOOP
        FETCH cur_plan INTO v_id_materia, v_semestre;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT COUNT(*) INTO v_demanda_estimada
        FROM estudiante
        WHERE id_plan = p_id_plan;

        INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
        VALUES (1, 'PROYECCION_DEMANDA', CONCAT('Materia ID=', v_id_materia, ' (Semestre ', v_semestre, ') Demanda estimada: ', v_demanda_estimada, ' alumnos.'), CURDATE(), CURTIME());
    END LOOP;
    CLOSE cur_plan;
END$$
DELIMITER ;
```

---

## 5. TRIGGERS / DISPARADORES ACTIVOS (24 Triggers de sistemaacademicooficial.sql)

### 5.1 trg_validar_ponderacion_criterio (BEFORE INSERT)
Valida que la suma de las ponderaciones de criterios no exceda el 100%.
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

### 5.2 trg_validar_inscripcion_paralelo_cupo (BEFORE INSERT)
Enforza disponibilidad de cupos al inscribir una materia.
```sql
CREATE TRIGGER `trg_validar_inscripcion_paralelo_cupo` BEFORE INSERT ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    DECLARE v_existe_paralelo INT DEFAULT 0;
    DECLARE v_cupo_maximo INT DEFAULT 0;
    DECLARE v_cupo_actual INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_existe_paralelo
    FROM paralelo
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    
    IF v_existe_paralelo = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El paralelo especificado no existe para esta materia.';
    END IF;
    
    SELECT cupo_maximo, cupo_actual 
    INTO v_cupo_maximo, v_cupo_actual
    FROM paralelo
    WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    
    IF v_cupo_actual >= v_cupo_maximo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No hay cupos disponibles en este paralelo.';
    END IF;
END
```

### 5.3 trg_disminuir_cupo (AFTER DELETE)
Decremente el número de cupos tras la baja de una inscripción.
```sql
CREATE TRIGGER `trg_disminuir_cupo` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE PARALELO SET cupo_actual=cupo_actual-1 WHERE id_materia=OLD.id_materia AND id_paralelo=OLD.id_paralelo;
END
```

### 5.4 trg_decrementar_cupo_actual (AFTER DELETE)
Versión segura con control de no-negativos.
```sql
CREATE TRIGGER `trg_decrementar_cupo_actual` AFTER DELETE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    UPDATE paralelo SET cupo_actual = GREATEST(cupo_actual - 1, 0) WHERE id_materia = OLD.id_materia AND id_paralelo = OLD.id_paralelo;
END
```

### 5.5 trg_liberar_cupo_abandono (AFTER UPDATE)
Libera vacante en caso de abandono de materia.
```sql
CREATE TRIGGER `trg_liberar_cupo_abandono` AFTER UPDATE ON `detalle_inscripcion` FOR EACH ROW 
BEGIN
    IF OLD.estado = 'Inscrito' AND NEW.estado = 'Abandono' THEN
        UPDATE PARALELO SET cupo_actual = cupo_actual - 1 WHERE id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo;
    END IF;
END
```

### 5.6 trg_validar_limite_inscripcion (BEFORE INSERT)
Controla el tope máximo de asignaturas a tomar por gestión (6 en regulares, 2 en cursos intensivos).
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
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró la gestión para esta inscripción.';
    END IF;
    
    SELECT COUNT(*) INTO v_cantidad
    FROM detalle_inscripcion
    WHERE id_inscripcion = NEW.id_inscripcion AND estado != 'Abandono';
    
    IF v_periodo LIKE 'Verano%' OR v_periodo LIKE 'Invierno%' THEN
        SET v_limite = 2;
    ELSE
        SET v_limite = 6;
    END IF;
    
    IF (v_cantidad + 1) > v_limite THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Límite de inscripción excedido. Máximo materias permitidas.';
    END IF;
END
```

### 5.7 trg_auditoria_docente_insert (AFTER INSERT)
Guarda la trazabilidad de altas de docentes.
```sql
CREATE TRIGGER `trg_auditoria_docente_insert` AFTER INSERT ON `docente` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nuevo docente Reg=', NEW.registro_docente, ' Grado=', NEW.grado_academico), CURDATE(), CURTIME());
END
```

### 5.8 trg_auto_registro_docente (BEFORE INSERT)
Asigna automáticamente un número de registro docente incremental.
```sql
CREATE TRIGGER `trg_auto_registro_docente` BEFORE INSERT ON `docente` FOR EACH ROW BEGIN
    DECLARE v_max_reg INT;
    IF NEW.registro_docente IS NULL OR NEW.registro_docente = '' THEN
        SELECT COALESCE(MAX(CAST(registro_docente AS UNSIGNED)), 1015647) INTO v_max_reg FROM docente;
        SET NEW.registro_docente = v_max_reg + 1;
    END IF;
END
```

### 5.9 trg_auditoria_estudiante_insert (AFTER INSERT)
Audita la incorporación de estudiantes.
```sql
CREATE TRIGGER `trg_auditoria_estudiante_insert` AFTER INSERT ON `estudiante` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nuevo estudiante RU=', NEW.ru, ' Plan=', NEW.id_plan, ' Ingreso=', NEW.anio_ingreso), CURDATE(), CURTIME());
END
```

### 5.10 trg_auto_ru_estudiante (BEFORE INSERT)
Genera correlativo de Registro Universitario (RU).
```sql
CREATE TRIGGER `trg_auto_ru_estudiante` BEFORE INSERT ON `estudiante` FOR EACH ROW BEGIN
    DECLARE v_max_ru INT;
    IF NEW.ru IS NULL OR NEW.ru = '' THEN
        SELECT COALESCE(MAX(CAST(ru AS UNSIGNED)), 1005999) INTO v_max_ru FROM estudiante;
        SET NEW.ru = v_max_ru + 1;
    END IF;
END
```

### 5.11 trg_auditoria_nota_insert (AFTER INSERT)
Registra en auditoría la creación de notas.
```sql
CREATE TRIGGER `trg_auditoria_nota_insert` AFTER INSERT ON `nota` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nueva nota ID=', NEW.id_nota, ' puntaje=', NEW.nota_obtenida, ' criterio=', NEW.id_criterio), CURDATE(), CURTIME());
END
```

### 5.12 trg_auditoria_nota_update (AFTER UPDATE)
Control de modificaciones de notas para prevenir manipulaciones.
```sql
CREATE TRIGGER `trg_auditoria_nota_update` AFTER UPDATE ON `nota` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'UPDATE', CONCAT('Nota ID=', NEW.id_nota, ' actualizada de ', OLD.nota_obtenida, ' a ', NEW.nota_obtenida), CURDATE(), CURTIME());
END
```

### 5.13 trg_validar_nota_max (BEFORE INSERT)
Enforza tope máximo de 100 puntos por calificación.
```sql
CREATE TRIGGER `trg_validar_nota_max` BEFORE INSERT ON `nota` FOR EACH ROW BEGIN
    IF NEW.nota_obtenida > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La nota no puede exceder 100 puntos.';
    END IF;
END
```

### 5.14 trg_bloquear_notas_gestion_cerrada (BEFORE INSERT)
Impide el ingreso de notas cuando el ciclo académico fue cerrado.
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

### 5.15 trg_auditoria_persona_insert (AFTER INSERT)
Audita el alta de personas.
```sql
CREATE TRIGGER `trg_auditoria_persona_insert` AFTER INSERT ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'INSERT', CONCAT('Nueva persona: ', NEW.nombres, ' ', NEW.apellidos, ' (CI: ', NEW.ci, ')'), CURDATE(), CURTIME());
END
```

### 5.16 trg_auditoria_persona_update (AFTER UPDATE)
Audita cambios de datos personales.
```sql
CREATE TRIGGER `trg_auditoria_persona_update` AFTER UPDATE ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'UPDATE', CONCAT('Actualización persona ID=', NEW.id_persona, ' de ', OLD.nombres, ' a ', NEW.nombres), CURDATE(), CURTIME());
END
```

### 5.17 trg_auditoria_persona_delete (AFTER DELETE)
Audita eliminaciones de personas.
```sql
CREATE TRIGGER `trg_auditoria_persona_delete` AFTER DELETE ON `persona` FOR EACH ROW BEGIN
    INSERT INTO auditoria (id_usuario, tipo, accion, fecha, hora)
    VALUES (@current_user_id, 'DELETE', CONCAT('Eliminada persona ID=', OLD.id_persona, ' (', OLD.nombres, ' ', OLD.apellidos, ')'), CURDATE(), CURTIME());
END
```

### 5.18 trg_auto_email_persona (BEFORE INSERT)
Genera correo institucional automáticamente.
```sql
CREATE TRIGGER `trg_auto_email_persona` BEFORE INSERT ON `persona` FOR EACH ROW BEGIN
    DECLARE v_username_temp VARCHAR(50);
    IF NEW.email IS NULL OR NEW.email = '' THEN
        SET v_username_temp = fn_generar_username(NEW.nombres, NEW.apellidos);
        SET NEW.email = fn_generar_email(v_username_temp);
    ELSE
        IF NEW.email NOT LIKE '%@fcpn.edu.bo' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El email debe tener formato @fcpn.edu.bo';
        END IF;
    END IF;
END
```

### 5.19 trg_validar_aula_horario (BEFORE INSERT)
Evita colisiones de aula en el mismo horario y gestión.
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
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflicto: Ya existe una materia asignada en esta aula y horario.';
    END IF;
END
```

### 5.20 trg_validar_docente_horario (BEFORE INSERT)
Evita colisiones de horarios docentes.
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
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflicto: El docente ya tiene otra materia en este horario.';
    END IF;
END
```

### 5.21 trg_validar_max_paralelos_docente (BEFORE UPDATE)
Garantiza que un docente no tome más de 3 paralelos en la misma gestión.
```sql
CREATE TRIGGER `trg_validar_max_paralelos_docente` BEFORE UPDATE ON `paralelo` FOR EACH ROW
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    IF NEW.id_docente IS NOT NULL THEN
        SELECT COUNT(*) INTO v_cantidad
        FROM paralelo
        WHERE id_docente = NEW.id_docente
          AND id_gestion = NEW.id_gestion
          AND NOT (id_materia = NEW.id_materia AND id_paralelo = NEW.id_paralelo);
        IF v_cantidad >= 3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El docente ya dirige 3 paralelos en esta gestión. No puede tomar más.';
        END IF;
    END IF;
END
```

### 5.22 trg_auditoria_nuevo_usuario (AFTER INSERT)
Audita creaciones de cuentas de usuario.
```sql
CREATE TRIGGER `trg_auditoria_nuevo_usuario` AFTER INSERT ON `usuario` FOR EACH ROW 
BEGIN
    INSERT INTO auditoria (id_usuario, accion, fecha, hora) VALUES (NEW.id_usuario, CONCAT('Creación de usuario: ', NEW.username), CURDATE(), CURTIME());
END
```

### 5.23 trg_auto_username_usuario (BEFORE INSERT)
Auto-genera el username si viene nulo y valida el hash de contraseña enviado por el backend.
```sql
CREATE TRIGGER `trg_auto_username_usuario` BEFORE INSERT ON `usuario` FOR EACH ROW 
BEGIN
    DECLARE v_nombres VARCHAR(80);
    DECLARE v_apellidos VARCHAR(80);
    SELECT nombres, apellidos INTO v_nombres, v_apellidos FROM persona WHERE id_persona = NEW.id_persona;
    IF NEW.username IS NULL OR NEW.username = '' THEN
        SET NEW.username = fn_generar_username(v_nombres, v_apellidos);
    END IF;
    IF NEW.password_hash IS NULL OR NEW.password_hash = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La contraseña debe ser generada en el backend con BCrypt.';
    END IF;
END
```

### 5.24 trg_validar_usuario_unico (BEFORE INSERT)
Evita que una persona posea más de una cuenta activa.
```sql
CREATE TRIGGER `trg_validar_usuario_unico` BEFORE INSERT ON `usuario` FOR EACH ROW BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM usuario WHERE id_persona = NEW.id_persona AND estado = 'Activo';
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un usuario activo para esta persona.';
    END IF;
END
```

---

## 6. CUADRO DE MANDO Y RESUMEN MAESTRO DE OBJETOS PROCEDURALES

### 6.1 Resumen Consolidado de Objetos en MariaDB / MySQL

| Categoría de Objetos | Cantidad Oficial en `sistemaacademicooficial.sql` | Cantidad Documentada en `procedural.md` | Estado | Descripción General |
| :--- | :---: | :---: | :---: | :--- |
| **Consultas SQL (DML / Models)** | 50+ | **50** | ✅ Coincidente | Consultas DML ejecutadas desde los modelos Node.js para operaciones del sistema |
| **Funciones Almacenadas** | 14 | **14** | ✅ Coincidente | Funciones oficiales para validación de cupos, correos, usernames y notas |
| **Procedimientos Almacenados** | **68** | **68** | ✅ **Coincidente Completo (+60)** | Todos los 68 procedimientos almacenados oficiales documentados 1 a 1 |
| **Cursores Batch (DBMS)** | 14 | **14** | ✅ Coincidente | Procesamiento iterativo batch para tareas administrativas en DBMS |
| **Triggers (Disparadores)** | 24 | **24** | ✅ Coincidente | Triggers de control de cupos, límites, choques horarias y auditoría activa |
| **TOTAL GENERAL DE OBJETOS** | **170** | **170** | ✅ **100% OFICIAL Y CUMPLIDO** | **Total consolidado alineado al archivo oficial de base de datos** |
