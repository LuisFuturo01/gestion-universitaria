import express from 'express';
import cors from 'cors';
import usuarioRutas from "./routes/usuarioRoutes.js";
import loginRutas from "./routes/loginRoutes.js";
import actorRutas from "./routes/actorRoutes.js";
import inscripcionRutas from "./routes/inscripcionRoutes.js";
import rolRutas from "./routes/rolRoutes.js";
import dirigeRutas from "./routes/dirigeRoutes.js";

const app = express();
//Middleware
app.use(cors());
app.use(express.json());
//RUTAS
app.use("/api/usuarios", usuarioRutas);
app.use("/api/login", loginRutas);
app.use("/api/actores", actorRutas);
app.use("/api/roles", rolRutas);
app.use("/api/inscripciones", inscripcionRutas);
app.use("/api/dirige", dirigeRutas);

// Iniciar servidor
const PUERTO = 3001;
app.listen(PUERTO, 
() => { console.log(`Servidor en http://localhost:${PUERTO}`);
});