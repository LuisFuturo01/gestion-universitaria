import express from "express";
import {obtActores,obtActorPorID,insertaActor,actualizaActor,eliminaActor} from "../controllers/actorController.js";
import {obtEstudiantes,obtEstudiantePorID,insertaEstudiante,actualizaEstudiante,eliminaEstudiante} from "../controllers/actorController.js"
import {obtDocentes,obtDocentePorID,insertaDocente,actualizaDocente,eliminaDocente} from "../controllers/actorController.js"
import {obtAdministrativos,obtAdministrativoPorID, insertaAdministrativo, actualizaAdministrativo, eliminaAdministrativo} from "../controllers/actorController.js"
import {obtDirectores, obtDirectorPorID, insertaDirector, actualizaDirectorCarrera, eliminaDirectorCarrera} from "../controllers/actorController.js"

import { verificarToken } from "../middlewares/auth.js";

const actorRutas = express.Router();

actorRutas.get("/", verificarToken, obtActores);
actorRutas.get("/:id", verificarToken, obtActorPorID);
actorRutas.post("/", verificarToken, insertaActor);
actorRutas.patch("/:id", verificarToken, actualizaActor);
actorRutas.delete("/:id", verificarToken, eliminaActor);

actorRutas.get("/estudiantes", verificarToken, obtEstudiantes);
actorRutas.get("/estudiantes/:id", verificarToken, obtEstudiantePorID);
actorRutas.post("/estudiantes", verificarToken, insertaEstudiante);
actorRutas.patch("/estudiantes/:id", verificarToken, actualizaEstudiante);
actorRutas.delete("/estudiantes/:id", verificarToken, eliminaEstudiante);

actorRutas.get("/docentes",verificarToken,obtDocentes);
actorRutas.get("/docentes/:id",verificarToken,obtDocentePorID);
actorRutas.post("/docentes",verificarToken,insertaDocente);
actorRutas.patch("/docentes/:id",verificarToken,actualizaDocente);
actorRutas.delete("/docentes/:id",verificarToken,eliminaDocente);

actorRutas.get("/administrativos",verificarToken,obtAdministrativos);
actorRutas.get("/administrativos/:id",verificarToken,obtAdministrativoPorID);
actorRutas.post("/administrativos",verificarToken,insertaAdministrativo);
actorRutas.patch("/administrativos/:id",verificarToken,actualizaAdministrativo);
actorRutas.delete("/administrativos/:id",verificarToken,eliminaAdministrativo);

actorRutas.get("/directores",verificarToken,obtDirectores);
actorRutas.get("/directores/:id",verificarToken,obtDirectorPorID);
actorRutas.post("/directores",verificarToken,insertaDirector);
actorRutas.patch("/directores/:id",verificarToken,actualizaDirectorCarrera);
actorRutas.delete("/directores/:id",verificarToken,eliminaDirectorCarrera);



export default actorRutas;