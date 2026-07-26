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
            [1, "4832015", "Carlos Andrés", "Mendoza Quispe", "1985-02-10", "M", "cmendozaq@fcpn.edu.bo", "A"],
            [2, "1718901", "Manuel Ramiro", "Flores Vargas", "1980-05-15", "M", "mrflores@fcpn.edu.bo", "A"],
            [3, "3451289", "Francisco", "Mamani Apaza", "1988-09-20", "M", "fmamania@fcpn.edu.bo", "A"],
            [4, "12896709", "Luis Alejandro", "Zeballos Quiroz", "2002-11-03", "M", "lzeballosq@fcpn.edu.bo", "A"],
        ];

        for (const p of personas) {
            await pool.query(
                `INSERT INTO persona (id_persona, ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                p
            );
        }

        console.log("--> Insertando Usuarios con Hash Bcrypt dinámico para '123456'...");
        const usuarios = [
            [1, "cmendozaq", hashPass, 1, 1, "A"],
            [2, "mrflores", hashPass, 2, 2, "A"],
            [3, "fmamania", hashPass, 3, 3, "A"],
            [4, "lzeballosq", hashPass, 4, 4, "A"],
            [5, "admin", hashPass, 1, 1, "A"],
            [6, "director", hashPass, 2, 2, "A"],
            [7, "docente", hashPass, 3, 3, "A"],
            [8, "estudiante", hashPass, 4, 4, "A"],
        ];

        for (const u of usuarios) {
            await pool.query(
                `INSERT INTO usuario (id_usuario, username, password_hash, id_persona, id_rol, estado) VALUES (?, ?, ?, ?, ?, ?)`,
                u
            );
        }

        console.log("--> Insertando datos de roles...");
        await pool.query(`INSERT INTO administrativo (id_persona, item, id_carrera) VALUES (1, '101205', 1)`);
        await pool.query(`INSERT INTO docente (id_persona, registro_docente, grado_academico) VALUES (2, '1015648', 'Ph.D.'), (3, '1015649', 'M.Sc.')`);
        await pool.query(`INSERT INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (4, '1006000', 1, 2025)`);
        await pool.query(`INSERT INTO director_carrera (id_persona) VALUES (2)`);

        console.log("=================================================");
        console.log("[SEED SUCCESS] ¡Datos iniciales creados exitosamente en MySQL!");
        console.log("Usuarios creados (Contraseña para todos: '123456'):");
        console.log(" - cmendozaq (Administrador)");
        console.log(" - mrflores (Director)");
        console.log(" - fmamania (Docente)");
        console.log(" - lzeballosq (Estudiante)");
        console.log("=================================================");

        pool.end();
    } catch (error) {
        console.error("Error durante la ejecución del seed:", error);
        pool.end();
    }
};

seedDatabase();
