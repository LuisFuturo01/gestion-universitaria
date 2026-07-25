import express from "express";

import{
    obtRoles,
    obtRolPorID,
    insertaRol,
    actualizaRol,
    eliminaRol
}from "../controllers/rolController.js";

import {verificarToken} from "../middlewares/auth.js";

const rolRutas=express.Router();

rolRutas.get("/",verificarToken,obtRoles);
rolRutas.get("/:id",verificarToken,obtRolPorID);
rolRutas.post("/",verificarToken,insertaRol);
rolRutas.patch("/:id",verificarToken,actualizaRol);
rolRutas.delete("/:id",verificarToken,eliminaRol);

export default rolRutas;