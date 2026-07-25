import express from "express";

import {
    obtUsuarios,
    obtUsuarioPorID,
    insertaUsuario,
    actualizaUsuario,
    eliminaUsuario
} from "../controllers/usuarioController.js";

import { verificarToken } from "../middlewares/auth.js";

const UsuarioRutas = express.Router();

UsuarioRutas.get("/", verificarToken, obtUsuarios);

UsuarioRutas.get("/:id", verificarToken, obtUsuarioPorID);

UsuarioRutas.post("/", verificarToken, insertaUsuario);

UsuarioRutas.patch("/:id", verificarToken, actualizaUsuario);

UsuarioRutas.delete("/:id", verificarToken, eliminaUsuario);

export default UsuarioRutas;