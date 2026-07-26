# Diccionario de Datos - Sistema Académico

A continuación, se presenta la estructura relacional detallada de la base de datos **sistemaacademico** en formato de tablas estructuradas.

---

## 1. Resumen General de Tablas (20)

| Tabla | Módulo | Descripción / Rol en el Sistema |
| :--- | :--- | :--- |
| `persona` | Personas | Superclase base para todos los actores (estudiantes, docentes, admin) |
| `estudiante` | Personas | Subclase de persona con registro universitario y plan de estudios |
| `docente` | Personas | Subclase de persona con registro docente y grado académico |
| `administrativo` | Personas | Subclase de persona con número de ítem e institución |
| `director_carrera` | Personas | Subclase de docente asignada a la dirección de carrera |
| `director_carrera_asignacion` | Personas | Tabla puente de asignación de director por gestión y carrera |
| `usuario` | Seguridad | Cuentas de acceso con contraseñas encriptadas en BCrypt |
| `rol` | Seguridad | Catálogo de roles de sistema (Admin, Director, Docente, Estudiante) |
| `auditoria` | Seguridad | Trazabilidad de operaciones ejecutadas por `@current_user_id` |
| `carrera` | Oferta / Estructura | Carreras universitarias de la facultad |
| `plan_estudio` | Oferta / Estructura | Menciones y planes de estudio por carrera |
| `materia` | Oferta / Estructura | Catálogo general de asignaturas |
| `plan_materia` | Oferta / Estructura | Malla curricular (asignación de materia y semestre a un plan) |
| `prerequisitos` | Oferta / Estructura | Prerrequisitos requeridos entre asignaturas de un plan |
| `gestion` | Programación | Periodos lectivos (I/2026, II/2026, Invierno/2026, Verano/2026) |
| `paralelo` | Programación | Secciones/grupos aperturados por materia y gestión |
| `aula` | Programación | Aulas y laboratorios con su capacidad máxima |
| `horario` | Programación | Bloques de días y horas asignables a paralelos |
| `se_cursa` | Programación | Asignación tridimensional de paralelo, aula y horario |
| `inscripcion` | Inscripciones | Cabecera de matriculación de estudiante por gestión |
| `detalle_inscripcion` | Inscripciones | Detalle de asignaturas inscritas por el estudiante |
| `criterio_evaluacion` | Calificaciones | Ponderaciones (exámenes, prácticas) configuradas por el docente |
| `nota` | Calificaciones | Registro individual de calificaciones asignadas por criterio |

---

## 2. Definición Detallada por Módulo

### 2.1 Módulo de Seguridad y Auditoría

#### Tabla: `rol`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_rol` | `INT(11)` | NO | **PK** | Identificador único del rol |
| `nombre` | `VARCHAR(50)` | NO | | Nombre del rol (Administrador, Director, Docente, Estudiante) |

#### Tabla: `usuario`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_usuario` | `INT(11)` | NO | **PK** | Identificador único del usuario |
| `username` | `VARCHAR(50)` | NO | **UNI** | Nombre de usuario único para inicio de sesión |
| `password_hash` | `VARCHAR(255)` | NO | | Hash seguro encriptado con BCrypt desde el backend |
| `id_persona` | `INT(11)` | NO | **FK** | Referencia a la tabla `persona` (ON DELETE CASCADE) |
| `id_rol` | `INT(11)` | NO | **FK** | Referencia al rol principal de la cuenta |
| `estado` | `ENUM('Activo', 'Inactivo')` | NO | | Estado de la cuenta de usuario |

#### Tabla: `auditoria`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_auditoria` | `INT(11)` | NO | **PK** | Identificador único de auditoría |
| `id_usuario` | `INT(11)` | YES | **FK** | Usuario que ejecutó la acción (`@current_user_id`) |
| `accion` | `VARCHAR(255)` | NO | | Descripción detallada de la operación |
| `fecha` | `DATE` | NO | | Fecha de la operación |
| `hora` | `TIME` | NO | | Hora exacta de ejecución |

---

### 2.2 Módulo de Personas y Actores

#### Tabla: `persona`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_persona` | `INT(11)` | NO | **PK** | Identificador base de la persona |
| `ci` | `VARCHAR(20)` | NO | **UNI** | Cédula de Identidad única |
| `nombres` | `VARCHAR(80)` | NO | | Nombres de la persona |
| `apellidos` | `VARCHAR(80)` | NO | | Apellidos de la persona |
| `fecha_nac` | `DATE` | NO | | Fecha de nacimiento |
| `sexo` | `ENUM('M', 'F')` | NO | | Género registrado |
| `email` | `VARCHAR(100)` | NO | **UNI** | Correo electrónico personal o institucional |
| `estado` | `ENUM('Activo', 'Inactivo')` | NO | | Estado de la persona |

#### Tabla: `estudiante`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_persona` | `INT(11)` | NO | **PK, FK** | Referencia a `persona` (ON DELETE CASCADE) |
| `ru` | `VARCHAR(20)` | NO | **UNI** | Registro Universitario único |
| `id_plan` | `INT(11)` | NO | **FK** | Plan de estudio / mención donde se encuentra inscrito |
| `anio_ingreso` | `INT(11)` | NO | | Año de admisión a la universidad |

#### Tabla: `docente`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_persona` | `INT(11)` | NO | **PK, FK** | Referencia a `persona` (ON DELETE CASCADE) |
| `registro_docente` | `VARCHAR(20)` | NO | **UNI** | Matrícula / Registro Docente único |
| `grado_academico` | `VARCHAR(50)` | NO | | Grado académico (Lic., M.Sc., Ph.D.) |

---

### 2.3 Módulo de Programación Académica y Espacios

#### Tabla: `gestion`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_gestion` | `INT(11)` | NO | **PK** | Identificador único de la gestión |
| `periodo` | `VARCHAR(20)` | NO | **UNI** | Código de periodo (ej. I/2026, II/2026, Invierno/2026) |
| `estado` | `ENUM('Activa', 'Cerrada')` | NO | | Estado de la gestión lectiva |

#### Tabla: `paralelo`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_materia` | `INT(11)` | NO | **PK, FK** | Referencia a la asignatura (`materia`) |
| `id_paralelo` | `INT(11)` | NO | **PK** | Número identificador del paralelo (1 = A, 2 = B) |
| `id_gestion` | `INT(11)` | NO | **PK, FK** | Referencia a la gestión académica |
| `nombre` | `VARCHAR(10)` | NO | | Nombre o letra del paralelo ('A', 'B', 'C') |
| `cupo_maximo` | `INT(11)` | NO | | Capacidad máxima (limitada por el aula asignada) |
| `cupo_actual` | `INT(11)` | NO | | Conteo acumulado de estudiantes inscritos |
| `id_docente` | `INT(11)` | YES | **FK** | Docente asignado (`NULL` si está vacante para toma) |

#### Tabla: `se_cursa`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_materia` | `INT(11)` | NO | **PK, FK** | Asignatura programada |
| `id_paralelo` | `INT(11)` | NO | **PK, FK** | Paralelo correspondiente |
| `id_aula` | `INT(11)` | NO | **PK, FK** | Aula o laboratorio físico asignado |
| `id_horario` | `INT(11)` | NO | **PK, FK** | Bloque de horario asignado |

---

### 2.4 Módulo de Inscripciones y Calificaciones

#### Tabla: `inscripcion`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_inscripcion` | `INT(11)` | NO | **PK** | Identificador único de la matrícula |
| `id_estudiante` | `INT(11)` | NO | **FK** | Estudiante que realiza la inscripción |
| `id_gestion` | `INT(11)` | NO | **FK** | Gestión académica correspondiente |
| `fecha_registro` | `DATETIME` | NO | | Marca de tiempo del registro |

#### Tabla: `detalle_inscripcion`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_detalle` | `INT(11)` | NO | **PK** | Identificador único del detalle de materia |
| `id_inscripcion` | `INT(11)` | NO | **FK** | Cabecera de inscripción vinculada |
| `id_materia` | `INT(11)` | NO | **FK** | Asignatura inscrita |
| `id_paralelo` | `INT(11)` | NO | **FK** | Paralelo seleccionado |
| `estado` | `ENUM('Inscrito', 'Aprobado', 'Reprobado', 'Abandono')` | NO | | Estado académico del estudiante en la materia |
| `nota_final` | `FLOAT` | YES | | Nota final ponderada calculada al cierre |

#### Tabla: `criterio_evaluacion`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_criterio` | `INT(11)` | NO | **PK** | Identificador del criterio |
| `id_materia` | `INT(11)` | NO | **FK** | Asignatura vinculada |
| `id_paralelo` | `INT(11)` | NO | **FK** | Paralelo al que pertenece la evaluación |
| `nombre` | `VARCHAR(100)` | NO | | Nombre del criterio (ej. Examen Parcial I) |
| `ponderacion` | `FLOAT` | NO | | Porcentaje sobre 100% de la calificación final |

#### Tabla: `nota`
| Campo | Tipo | Nulo | Clave | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `id_nota` | `INT(11)` | NO | **PK** | Identificador único de la nota parcial |
| `id_detalle` | `INT(11)` | NO | **FK** | Detalle de inscripción del alumno |
| `id_criterio` | `INT(11)` | NO | **FK** | Criterio de evaluación correspondiente |
| `nota_obtenida` | `FLOAT` | NO | | Calificación parcial ingresada por el docente |