# Especificación de Usuarios y Seguridad a Nivel de Base de Datos (MariaDB / MySQL)

> **Documento Oficial de Configuración de Seguridad en BD:**
> Este documento especifica la creación, permisos y arquitectura de conexión para los 5 usuarios independientes creados en MariaDB para la base de datos `sistemaacademico`.

---

## 1. Script de Creación y Privilegios

El script ejecutable oficial es [`crear_usuarios_db_roles.sql`](file:///d:/xampp/htdocs/UMSA/db2/proyecto/backend/extra/crear_usuarios_db_roles.sql).

### Resumen de Usuarios y Contraseñas

| Usuario MySQL | Contraseña | Rol del Sistema | Alcance de Privilegios |
| :--- | :--- | :--- | :--- |
| `usr_login` | `123456` | **Autenticación / Login** | `GRANT SELECT` únicamente en `usuario`, `persona`, `rol`, `estudiante`, `docente`, `administrativo`, `director_carrera`. |
| `usr_estudiante` | `123456` | **Estudiante** | `GRANT SELECT` en tablas de catálogo, kárdex y oferta.<br>`GRANT EXECUTE` en `sp_realizar_inscripcion`, `sp_retirar_inscripcion`, `fn_ya_inscrito`, `fn_tiene_prerrequisitos`. |
| `usr_docente` | `123456` | **Docente** | `GRANT SELECT` en catálogo.<br>`GRANT SELECT, INSERT, UPDATE, DELETE` en `criterio_evaluacion` y `nota`.<br>`GRANT EXECUTE` en `sp_crear_criterio`, `sp_actualizar_criterio`, `sp_eliminar_criterio`, `sp_crear_nota`, `sp_actualizar_nota`, `sp_eliminar_nota`, `fn_calcular_nota_final`. |
| `usr_director` | `123456` | **Director de Carrera** | `GRANT SELECT, INSERT, UPDATE, DELETE` en estructura académica (carreras, menciones, planes, materias, paralelos, aulas, horarios, gestiones).<br>Puede crear administradores pero no usuarios corrientes.<br>`GRANT EXECUTE` en `sp_aperturar_paralelo_completo` y `sp_asignar_horarios_sin_choque`. |
| `usr_admin` | `123456` | **Administrador** | `GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON sistemaacademico.*` (Sin `CREATE`, `DROP` ni `INDEX`).<br>Privilegios de ejecución en SPs administrativos explícitos (excluye `sp_cerrar_gestion`). |

---

## 2. Configuración en el Backend de Node.js

En [`backend/config/db.js`](file:///d:/xampp/htdocs/UMSA/db2/proyecto/backend/config/db.js) se han configurado pools de conexión dedicados:
- `authPool` (utiliza `usr_login` para autenticar credenciales).
- `estudiantePool` (utiliza `usr_estudiante`).
- `docentePool` (utiliza `usr_docente`).
- `directorPool` (utiliza `usr_director`).
- `adminPool` (utiliza `usr_admin`).
- `pool` (pool de ejecución general con fallback).

---

## 3. Generación Automática de Usuarios en Frontend

En la interfaz [`UsersPage.jsx`](file:///d:/xampp/htdocs/UMSA/db2/proyecto/frontend/src/pages/Users/UsersPage.jsx):
- El formulario solicita **únicamente**: Nombres, Apellidos, CI, Fecha de Nacimiento, Sexo y Rol.
- El `username` y `email` son generados de manera automática en la base de datos MariaDB mediante el procedimiento `sp_insertar_persona_usuario`.
- La contraseña por defecto es siempre **`123456`**.
- Al registrar el usuario, se muestra una sola vez una ventana modal destacando las credenciales generadas.
