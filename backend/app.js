import express from 'express';
import cors from 'cors';
import bcrypt from 'bcrypt';
import { pool } from './config/db.js';

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
        const [rows] = await pool.query("SELECT COUNT(*) AS total FROM usuario");
        if (rows[0].total < 4) {
            console.log("[AUTO-INIT] Sincronizando usuarios principales en MySQL...");
            const hash = await bcrypt.hash("123456", 10);
            await pool.query("INSERT IGNORE INTO persona (id_persona, ci, nombres, apellidos, fecha_nac, sexo, email, estado) VALUES (1, '1111111', 'Ana', 'Mamani Quispe', '1985-02-10', 'F', 'admin@uni.edu.bo', 'A'), (2, '2222222', 'Carlos', 'Condori Ramos', '1980-05-15', 'M', 'director@uni.edu.bo', 'A'), (3, '3333333', 'María', 'Gómez Vargas', '1988-09-20', 'F', 'docente@uni.edu.bo', 'A'), (4, '4444444', 'Juan', 'Pérez Ramos', '2002-11-03', 'M', 'estudiante@uni.edu.bo', 'A')");
            await pool.query("INSERT IGNORE INTO usuario (id_usuario, username, password_hash, id_persona, id_rol, estado) VALUES (1, 'admin', ?, 1, 1, 'A'), (2, 'director', ?, 2, 2, 'A'), (3, 'docente', ?, 3, 3, 'A'), (4, 'estudiante', ?, 4, 4, 'A')", [hash, hash, hash, hash]);
            await pool.query("INSERT IGNORE INTO administrativo (id_persona, item, id_carrera) VALUES (1, 'ADM-001', 1)");
            await pool.query("INSERT IGNORE INTO docente (id_persona, registro_docente, grado_academico) VALUES (2, 'DOC-001', 'Ph.D.'), (3, 'DOC-002', 'M.Sc.')");
            await pool.query("INSERT IGNORE INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (4, '20210458', 1, 2021)");
            await pool.query("INSERT IGNORE INTO director_carrera (id_persona) VALUES (2)");
            console.log("[AUTO-INIT] Sincronización completada exitosamente.");
        }
    } catch (e) {
        console.warn("[AUTO-INIT WARN]", e.message);
    }
};

// Iniciar servidor
const PUERTO = 3001;
app.listen(PUERTO, async () => { 
    console.log(`Servidor de la Universidad corriendo en http://localhost:${PUERTO}`);
    await asegurarUsuariosSemilla();
});