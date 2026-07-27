-- ==============================================================================
-- SCRIPT DE CREACIÓN DE USUARIOS Y ROLES CON PERMISOS LIMITANTES EN MYSQL / MARIADB
-- Base de Datos: sistemaacademico
-- Servidor: localhost
-- Contraseña global por defecto: 123456
-- ==============================================================================

USE sistemaacademico;

-- 1. ELIMINAR USUARIOS SI YA EXISTEN PARA RECONFIGURACIÓN LIMPIA
DROP USER IF EXISTS 'usr_login'@'localhost';
DROP USER IF EXISTS 'usr_estudiante'@'localhost';
DROP USER IF EXISTS 'usr_docente'@'localhost';
DROP USER IF EXISTS 'usr_director'@'localhost';
DROP USER IF EXISTS 'usr_admin'@'localhost';

-- 2. CREACIÓN DE USUARIOS CON CONTRASEÑA 123456
CREATE USER 'usr_login'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'usr_estudiante'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'usr_docente'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'usr_director'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'usr_admin'@'localhost' IDENTIFIED BY '123456';

-- ==============================================================================
-- 3. ASIGNACIÓN DE PRIVILEGIOS POR ROL
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- A. USUARIO DE AUTENTICACIÓN / LOGIN (usr_login)
-- Permiso de lectura estrictamente limitado a las tablas necesarias para autenticar
-- ------------------------------------------------------------------------------
GRANT SELECT ON sistemaacademico.usuario TO 'usr_login'@'localhost';
GRANT SELECT ON sistemaacademico.persona TO 'usr_login'@'localhost';
GRANT SELECT ON sistemaacademico.rol TO 'usr_login'@'localhost';
GRANT SELECT ON sistemaacademico.estudiante TO 'usr_login'@'localhost';
GRANT SELECT ON sistemaacademico.docente TO 'usr_login'@'localhost';
GRANT SELECT ON sistemaacademico.administrativo TO 'usr_login'@'localhost';
GRANT SELECT ON sistemaacademico.director_carrera TO 'usr_login'@'localhost';

-- ------------------------------------------------------------------------------
-- B. USUARIO ESTUDIANTE (usr_estudiante)
-- Permisos de lectura sobre catálogo académico e historial propio, y ejecución de inscripción
-- ------------------------------------------------------------------------------
GRANT SELECT ON sistemaacademico.carrera TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.materia TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.paralelo TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.plan_estudio TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.plan_materia TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.prerequisito TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.gestion TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.horario TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.aula TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.se_cursa TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.persona TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.estudiante TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.inscripcion TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.detalle_inscripcion TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.criterio_evaluacion TO 'usr_estudiante'@'localhost';
GRANT SELECT ON sistemaacademico.nota TO 'usr_estudiante'@'localhost';

-- Procedimientos y Funciones almacenadas permitidos para estudiantes
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_realizar_inscripcion TO 'usr_estudiante'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_retirar_inscripcion TO 'usr_estudiante'@'localhost';
GRANT EXECUTE ON FUNCTION sistemaacademico.fn_ya_inscrito TO 'usr_estudiante'@'localhost';
GRANT EXECUTE ON FUNCTION sistemaacademico.fn_tiene_prerrequisitos TO 'usr_estudiante'@'localhost';

-- ------------------------------------------------------------------------------
-- C. USUARIO DOCENTE (usr_docente)
-- Permisos de consulta académica y gestión completa sobre sus criterios y notas
-- ------------------------------------------------------------------------------
GRANT SELECT ON sistemaacademico.carrera TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.materia TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.paralelo TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.plan_estudio TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.plan_materia TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.gestion TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.horario TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.aula TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.se_cursa TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.persona TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.docente TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.estudiante TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.inscripcion TO 'usr_docente'@'localhost';
GRANT SELECT ON sistemaacademico.detalle_inscripcion TO 'usr_docente'@'localhost';

-- Gestión de planillas
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.criterio_evaluacion TO 'usr_docente'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.nota TO 'usr_docente'@'localhost';

-- Procedimientos y Funciones almacenadas permitidos para docentes
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_criterio TO 'usr_docente'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_actualizar_criterio TO 'usr_docente'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_eliminar_criterio TO 'usr_docente'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_nota TO 'usr_docente'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_actualizar_nota TO 'usr_docente'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_eliminar_nota TO 'usr_docente'@'localhost';
GRANT EXECUTE ON FUNCTION sistemaacademico.fn_calcular_nota_final TO 'usr_docente'@'localhost';

-- ------------------------------------------------------------------------------
-- D. USUARIO DIRECTOR DE CARRERA (usr_director)
-- Gestión académica e infraestructura universitaria
-- ------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.carrera TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.plan_estudio TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.materia TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.plan_materia TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.prerequisito TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.paralelo TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.se_cursa TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.aula TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.horario TO 'usr_director'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON sistemaacademico.gestion TO 'usr_director'@'localhost';

GRANT SELECT ON sistemaacademico.persona TO 'usr_director'@'localhost';
GRANT SELECT ON sistemaacademico.docente TO 'usr_director'@'localhost';
GRANT SELECT ON sistemaacademico.estudiante TO 'usr_director'@'localhost';
GRANT SELECT ON sistemaacademico.inscripcion TO 'usr_director'@'localhost';
GRANT SELECT ON sistemaacademico.detalle_inscripcion TO 'usr_director'@'localhost';
GRANT SELECT ON sistemaacademico.criterio_evaluacion TO 'usr_director'@'localhost';
GRANT SELECT ON sistemaacademico.nota TO 'usr_director'@'localhost';

GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_aperturar_paralelo_completo TO 'usr_director'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_asignar_horarios_sin_choque TO 'usr_director'@'localhost';

-- ------------------------------------------------------------------------------
-- E. USUARIO ADMINISTRADOR (usr_admin)
-- Privilegios DML de datos y permiso estructural exclusivo 'ALTER' (Sin CREATE, DROP ni INDEX)
-- Excluye explícitamente la ejecución de sp_cerrar_gestion.
-- ------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON sistemaacademico.* TO 'usr_admin'@'localhost';

-- Procedimientos administrativos autorizados (Excluye explícitamente sp_cerrar_gestion)
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_aperturar_paralelo_completo TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_asignar_horarios_sin_choque TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_asignar_aulas_horarios_con_reintentos TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_aula TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_carrera TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_criterio TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_gestion TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_horario TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_materia TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_nota TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_paralelo TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_plan_estudio TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_plan_materia TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_prerequisito TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_crear_se_cursa TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_realizar_inscripcion TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_retirar_inscripcion TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_insertar_persona_usuario TO 'usr_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sistemaacademico.sp_insertar_estudiante_completo TO 'usr_admin'@'localhost';

-- APLICAR TODOS LOS CAMBIOS DE PERMISOS
FLUSH PRIVILEGES;
