import express from 'express';
import cors from 'cors';
import bcrypt from 'bcrypt';
import { pool } from './config/db.js';
// Servidor re-sincronizado para autorreparación de paralelos en gestión activa

// Rutas Entidades Verdes (Usuario, Actor, Rol, Inscripción, Dirige, Auth)
import usuarioRutas from "./routes/usuarioRoutes.js";
import loginRutas from "./routes/loginRoutes.js";
import actorRutas from "./routes/actorRoutes.js";
import inscripcionRutas from "./routes/inscripcionRoutes.js";
import rolRutas from "./routes/rolRoutes.js";
import dirigeRutas from "./routes/dirigeRoutes.js";

// Rutas Entidades Rojas (Carrera, Plan, Materia, Paralelo, Aula, Horario, Gestión, etc.)
import materiaRoutes from "./routes/materiaRoutes.js";
import paraleloRoutes from "./routes/paraleloRoutes.js";
import aulaRoutes from "./routes/aulaRoutes.js";
import horarioRoutes from "./routes/horarioRoutes.js";
import gestionRoutes from "./routes/gestionRoutes.js";
import seCursaRoutes from "./routes/seCursaRoutes.js";
import carreraRoutes from "./routes/carreraRoutes.js";
import planEstudioRoutes from "./routes/planEstudioRoutes.js";
import planMateriaRoutes from "./routes/planMateriaRoutes.js";
import prerequisitoRoutes from "./routes/prerequisitoRoutes.js";
import criterioEvaluacionRoutes from "./routes/criterioEvaluacionRoutes.js";
import notaRoutes from "./routes/notaRoutes.js";

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// RUTAS ENTIDADES VERDES
app.use("/api/usuarios", usuarioRutas);
app.use("/api/login", loginRutas);
app.use("/api/actores", actorRutas);
app.use("/api/roles", rolRutas);
app.use("/api/inscripciones", inscripcionRutas);
app.use("/api/dirige", dirigeRutas);

// RUTAS ENTIDADES ROJAS
app.use("/api/materias", materiaRoutes);
app.use("/api/paralelos", paraleloRoutes);
app.use("/api/aulas", aulaRoutes);
app.use("/api/horarios", horarioRoutes);
app.use("/api/gestiones", gestionRoutes);
app.use("/api/secursa", seCursaRoutes);
app.use("/api/carreras", carreraRoutes);
app.use("/api/planes", planEstudioRoutes);
app.use("/api/plan-materias", planMateriaRoutes);
app.use("/api/prerequisitos", prerequisitoRoutes);
app.use("/api/criterios", criterioEvaluacionRoutes);
app.use("/api/notas", notaRoutes);

// Auto-inicialización de usuarios semilla en MySQL si la BD está recién importada
const asegurarUsuariosSemilla = async () => {
    try {
        const hash = await bcrypt.hash("123456", 10);
        await pool.query(`
            INSERT IGNORE INTO persona (id_persona, ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES 
            (1, '4832015', 'Carlos Andrés', 'Mendoza Quispe', '1985-02-10', 'M', 'cmendozaq@fcpn.edu.bo', 'Activo'),
            (2, '1718901', 'Manuel Ramiro', 'Flores', '1980-05-15', 'M', 'mrflores@fcpn.edu.bo', 'Activo'),
            (3, '3451289', 'Francisco', 'Mamani Apaza', '1988-09-20', 'M', 'fmamania@fcpn.edu.bo', 'Activo'),
            (4, '12896709', 'Luis Alejandro', 'Zeballos Quiroz', '2002-11-03', 'M', 'lzeballosq@fcpn.edu.bo', 'Activo')
        `);

        // Insertar usuarios de prueba solo si no existen para evitar bloqueos del trigger trg_validar_usuario_unico
        const usuariosSemilla = [
            { id: 1, name: 'cmendozaq', persona: 1, rol: 1 },
            { id: 2, name: 'mrflores', persona: 2, rol: 2 },
            { id: 3, name: 'fmamania', persona: 3, rol: 3 },
            { id: 4, name: 'lzeballosq', persona: 4, rol: 4 }
        ];

        for (const u of usuariosSemilla) {
            try {
                const [exist] = await pool.query("SELECT id_usuario FROM usuario WHERE username = ?", [u.name]);
                if (exist.length === 0) {
                    await pool.query(
                        "INSERT INTO usuario (id_usuario, username, password_hash, id_persona, id_rol, estado) VALUES (?, ?, ?, ?, ?, 'Activo')",
                        [u.id, u.name, hash, u.persona, u.rol]
                    );
                }
            } catch (errUser) {
                /* ignora colisión si el usuario ya existe */
            }
        }

        await pool.query("INSERT IGNORE INTO administrativo (id_persona, item, id_carrera) VALUES (1, '101205', 1)");
        await pool.query("INSERT IGNORE INTO docente (id_persona, registro_docente, grado_academico) VALUES (2, '1015648', 'Ph.D.'), (3, '1015649', 'M.Sc.')");
        await pool.query("INSERT IGNORE INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (4, '1006000', 1, 2025)");
        await pool.query("INSERT IGNORE INTO director_carrera (id_persona) VALUES (2)");
        await pool.query("INSERT IGNORE INTO director_carrera_asignacion (id_persona, id_carrera, gestion) VALUES (2, 1, '2026-2028')");
        console.log("[AUTO-INIT] Sincronización de usuarios de prueba completada exitosamente.");
    } catch (e) {
        console.warn("[AUTO-INIT WARN]", e.message);
    }
};

import { repararParalelosGestionActiva } from "./models/gestionModel.js";

// Iniciar servidor
const PUERTO = 3001;
app.listen(PUERTO, async () => { 
    console.log(`Servidor de la Universidad corriendo en http://localhost:${PUERTO}`);
    await asegurarUsuariosSemilla();
    await repararParalelosGestionActiva();
});