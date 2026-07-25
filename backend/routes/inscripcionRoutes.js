import express from "express";

import{

obtInscripciones,
obtInscripcionPorID,
insertaInscripcion,
eliminaInscripcion,
AsignarN

}from"../controllers/inscripcionController.js";

const inscripcionRutas=express.Router();

inscripcionRutas.get("/",obtInscripciones);
inscripcionRutas.get("/:id",obtInscripcionPorID);
inscripcionRutas.post("/",insertaInscripcion);
inscripcionRutas.patch("/retirar/:id",eliminaInscripcion);
inscripcionRutas.post("/nota",AsignarN);

export default inscripcionRutas;