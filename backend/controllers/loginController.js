import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

import { iniciarSesion } from "../models/loginModel.js";
import { check, validationResult } from "express-validator";

export const login = async (req, res) => {

    try {
         await check("username")
            .notEmpty()
            .run(req);
        await check("password")
            .notEmpty()
            .run(req);
        const errores = validationResult(req);
        if (!errores.isEmpty()) {
            return res.status(400).json({
                mensaje: errores.array()
            });
        }
        const { username, password } = req.body;
        const usuario = await iniciarSesion(username);
        if (usuario.length === 0) {
            return res.status(401).json({
                mensaje: "Credenciales incorrectas"
            });
        }
        const passwordCorrecta = await bcrypt.compare(
            password,
            usuario[0].password_hash
        );
        if (!passwordCorrecta) {
            return res.status(401).json({
                mensaje: "Credenciales incorrectas"
            });
        }
        const token = jwt.sign(
            {
                id_usuario: usuario[0].id_usuario,
                username: usuario[0].username
            },
            "SISTEMA_ACADEMICO",
            {
                expiresIn: "8h"
            }
        );
        res.status(200).json({
            mensaje: "Inicio de sesión correcto", token, usuario});
    }
    catch (error) {
        res.status(500).json({error: error.message});
    }
};