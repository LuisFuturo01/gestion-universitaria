import { pool } from "./config/db.js";
import bcrypt from "bcrypt";

const seedDatabase = async () => {
    try {
        console.log("--> Iniciando truncado de tablas y reinicio de autoincrementables...");
        await pool.query("SET FOREIGN_KEY_CHECKS = 0");

        const tablas = [
            "detalle_inscripcion",
            "inscripcion",
            "nota",
            "criterio_evaluacion",
            "se_cursa",
            "paralelo",
            "exige_o_dirige",
            "director_carrera_asignacion",
            "director_carrera",
            "docente",
            "estudiante",
            "administrativo",
            "usuario",
            "persona",
        ];

        for (const tabla of tablas) {
            try {
                await pool.query(`TRUNCATE TABLE ${tabla}`);
            } catch (e) {
                console.warn(`Aviso truncando ${tabla}: ${e.message}`);
            }
        }

        await pool.query("SET FOREIGN_KEY_CHECKS = 1");
        console.log("--> Tablas limpiadas con éxito.");

        // Hash Bcrypt generado en tiempo de ejecución para '123456'
        const hashPass = await bcrypt.hash("123456", 10);

        console.log("--> Insertando Personas...");
        const personas = [
            [1, "1111111", "Ana", "Mamani Quispe", "1985-02-10", "F", "admin@uni.edu.bo", "A"],
            [2, "2222222", "Carlos", "Condori Ramos", "1980-05-15", "M", "director@uni.edu.bo", "A"],
            [3, "3333333", "María", "Gómez Vargas", "1988-09-20", "F", "docente@uni.edu.bo", "A"],
            [4, "4444444", "Juan", "Pérez Ramos", "2002-11-03", "M", "estudiante@uni.edu.bo", "A"],
        ];

        for (const p of personas) {
            await pool.query(
                `INSERT INTO persona (id_persona, ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                p
            );
        }

        console.log("--> Insertando Usuarios con Hash Bcrypt dinámico para '123456'...");
        const usuarios = [
            [1, "admin", hashPass, 1, 1, "A"],
            [2, "director", hashPass, 2, 2, "A"],
            [3, "docente", hashPass, 3, 3, "A"],
            [4, "estudiante", hashPass, 4, 4, "A"],
        ];

        for (const u of usuarios) {
            await pool.query(
                `INSERT INTO usuario (id_usuario, username, password_hash, id_persona, id_rol, estado) VALUES (?, ?, ?, ?, ?, ?)`,
                u
            );
        }

        console.log("--> Insertando datos de roles...");
        await pool.query(`INSERT INTO administrativo (id_persona, item, id_carrera) VALUES (1, 'ADM-001', 1)`);
        await pool.query(`INSERT INTO docente (id_persona, registro_docente, grado_academico) VALUES (2, 'DOC-001', 'Ph.D.'), (3, 'DOC-002', 'M.Sc.')`);
        await pool.query(`INSERT INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (4, '20210458', 1, 2021)`);
        await pool.query(`INSERT INTO director_carrera (id_persona) VALUES (2)`);

        console.log("=================================================");
        console.log("[SEED SUCCESS] ¡Datos iniciales creados exitosamente en MySQL!");
        console.log("Usuarios creados (Contraseña para todos: '123456'):");
        console.log(" - admin (Administrador)");
        console.log(" - director (Director)");
        console.log(" - docente (Docente)");
        console.log(" - estudiante (Estudiante)");
        console.log("=================================================");

        pool.end();
    } catch (error) {
        console.error("Error durante la ejecución del seed:", error);
        pool.end();
    }
};

seedDatabase();
