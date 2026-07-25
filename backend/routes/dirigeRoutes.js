import express from "express";

import {
    obtAsignaciones,
    obtAsignacionID,
    insertaAsignacion,
    actualizaAsignacion,
    eliminaAsignacion
} from "../controllers/dirigeController.js";

import {
    verificarToken
} from "../middlewares/auth.js";


const dirigeRutas=express.Router();


dirigeRutas.get("/",verificarToken,obtAsignaciones);
dirigeRutas.get("/:id_persona/:id_carrera",verificarToken,obtAsignacionID);
dirigeRutas.post("/",verificarToken,insertaAsignacion);
dirigeRutas.patch("/:id_persona/:id_carrera",verificarToken,actualizaAsignacion);
dirigeRutas.delete("/:id_persona/:id_carrera",verificarToken,eliminaAsignacion);


export default dirigeRutas;