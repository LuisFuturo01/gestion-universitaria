# Diccionario de Datos - Sistema Académico

A continuación, se detalla la estructura relacional basada exactamente en los nombres y definiciones de la base de datos sistemaacademico, en formato de texto.

## Entidades de Seguridad y Auditoría

### Tabla: rol

- **Atributos:** id_rol, nombre
- **Llave Primaria (PK):** id_rol
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: usuario

- **Atributos:** id_usuario, username, password_hash, id_persona, id_rol, estado
- **Llave Primaria (PK):** id_usuario
- **Llaves Foráneas (FK):** id_persona (refiere a persona), id_rol (refiere a rol)

### Tabla: auditoria

- **Atributos:** id_auditoria, id_usuario, accion, fecha, hora
- **Llave Primaria (PK):** id_auditoria
- **Llaves Foráneas (FK):** id_usuario (refiere a usuario)

## Entidades de Personas (Superclase y Subclases)

### Tabla: persona

- **Atributos:** id_persona, ci, nombres, apellidos, fecha_nac, sexo, email, estado
- **Llave Primaria (PK):** id_persona
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: administrativo

- **Atributos:** id_persona, item, id_carrera
- **Llave Primaria (PK):** id_persona
- **Llaves Foráneas (FK):** id_persona (refiere a persona), id_carrera (refiere a carrera)

### Tabla: docente

- **Atributos:** id_persona, registro_docente, grado_academico
- **Llave Primaria (PK):** id_persona
- **Llaves Foráneas (FK):** id_persona (refiere a persona)

### Tabla: director_carrera

- **Atributos:** id_persona
- **Llave Primaria (PK):** id_persona
- **Llaves Foráneas (FK):** id_persona (refiere a docente)

### Tabla: director_carrera_asignacion

- **Atributos:** id_persona, id_carrera, gestion
- **Llave Primaria (PK):** id_persona, id_carrera
- **Llaves Foráneas (FK):** id_persona (refiere a director_carrera), id_carrera (refiere a carrera)

### Tabla: estudiante

- **Atributos:** id_persona, ru, id_plan, anio_ingreso
- **Llave Primaria (PK):** id_persona
- **Llaves Foráneas (FK):** id_persona (refiere a persona), id_plan (refiere a plan_estudio)

## Entidades Académicas y Planes de Estudio

### Tabla: carrera

- **Atributos:** id_carrera, nombre
- **Llave Primaria (PK):** id_carrera
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: plan_estudio

- **Atributos:** id_plan, nombre, id_carrera
- **Llave Primaria (PK):** id_plan
- **Llaves Foráneas (FK):** id_carrera (refiere a carrera)

### Tabla: materia

- **Atributos:** id_materia, sigla, nombre, carga_horaria, estado
- **Llave Primaria (PK):** id_materia
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: plan_materia

- **Atributos:** id_plan, id_materia, semestre
- **Llave Primaria (PK):** id_plan, id_materia
- **Llaves Foráneas (FK):** id_plan (refiere a plan_estudio), id_materia (refiere a materia)

### Tabla: prerequisito

- **Atributos:** id_plan, id_materia, id_materia_req
- **Llave Primaria (PK):** id_plan, id_materia, id_materia_req
- **Llaves Foráneas (FK):** id_plan, id_materia (refiere a plan_materia), id_plan, id_materia_req (refiere a plan_materia)

## Entidades de Programación y Espacios

### Tabla: gestion

- **Atributos:** id_gestion, periodo, estado
- **Llave Primaria (PK):** id_gestion
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: paralelo

- **Atributos:** id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion
- **Llave Primaria (PK):** id_materia, id_paralelo
- **Llaves Foráneas (FK):** id_materia (refiere a materia), id_docente (refiere a docente), id_gestion (refiere a gestion)

### Tabla: aula

- **Atributos:** id_aula, nombre, piso, ubicacion, capacidad
- **Llave Primaria (PK):** id_aula
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: horario

- **Atributos:** id_horario, dia, hora_inicio, hora_fin
- **Llave Primaria (PK):** id_horario
- **Llaves Foráneas (FK):** (Ninguna)

### Tabla: se_cursa

- **Atributos:** id_materia, id_paralelo, id_aula, id_horario
- **Llave Primaria (PK):** id_materia, id_paralelo, id_aula, id_horario
- **Llaves Foráneas (FK):** id_materia, id_paralelo (refiere a paralelo), id_aula (refiere a aula), id_horario (refiere a horario)

## Entidades de Inscripción y Calificaciones

### Tabla: inscripcion

- **Atributos:** id_inscripcion, id_estudiante, id_gestion, fecha_registro
- **Llave Primaria (PK):** id_inscripcion
- **Llaves Foráneas (FK):** id_estudiante (refiere a estudiante), id_gestion (refiere a gestion)

### Tabla: detalle_inscripcion

- **Atributos:** id_detalle, id_inscripcion, id_materia, id_paralelo, estado, nota_final
- **Llave Primaria (PK):** id_detalle
- **Llaves Foráneas (FK):** id_inscripcion (refiere a inscripcion), id_materia, id_paralelo (refiere a paralelo)

### Tabla: criterio_evaluacion

- **Atributos:** id_criterio, id_materia, id_paralelo, nombre, ponderacion
- **Llave Primaria (PK):** id_criterio
- **Llaves Foráneas (FK):** id_materia, id_paralelo (refiere a paralelo)

### Tabla: nota

- **Atributos:** id_nota, id_detalle, id_criterio, nota_obtenida
- **Llave Primaria (PK):** id_nota
- **Llaves Foráneas (FK):** id_detalle (refiere a detalle_inscripcion), id_criterio (refiere a criterio_evaluacion)