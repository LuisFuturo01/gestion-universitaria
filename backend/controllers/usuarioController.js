import {obtTodo,obtUsuario,inserta,actualiza ,elimina} from "../models/usuarioModel.js";
import { check, validationResult } from "express-validator";
import bcrypt from "bcrypt";


export const obtUsuarios = async (req, res) => {

    try {

        const usuarios = await obtTodo();

        res.status(200).json(usuarios);

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }

};

export const obtUsuarioPorID = async (req, res) => {

    try {

        const usuario = await obtUsuario(req.params.id);

        if (!usuario)
            return res.status(404).json({
                error: "Usuario no encontrado"
            });

        res.status(200).json(usuario);

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }

};
export const insertaUsuario = async (req, res) => {

    try {

        await check("username")
            .notEmpty()
            .withMessage("El username es obligatorio")
            .run(req);

        await check("password")
            .isLength({ min: 6 })
            .withMessage("La contraseña debe tener al menos 6 caracteres")
            .run(req);

        await check("id_persona")
            .isNumeric()
            .withMessage("ID de persona inválido")
            .run(req);

        const errores = validationResult(req);

        if (!errores.isEmpty()) {
            return res.status(400).json({
                mensaje: errores.array()
            });
        }

        const { username, password, id_persona } = req.body;

        const password_hash = await bcrypt.hash(password, 10);

        const usuarioNuevo = await crear({
            username,
            password_hash,
            id_persona
        });

        res.status(201).json(usuarioNuevo);

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }

};

export const actualizaUsuario = async (req, res) => {

    try {

        const usuario = await obtUsuario(req.params.id);

        if (!usuario)
            return res.status(404).json({
                error: "Usuario no encontrado"
            });

        await check("username")
            .notEmpty()
            .withMessage("El username es obligatorio")
            .run(req);

        await check("password_hash")
            .notEmpty()
            .withMessage("La contraseña es obligatoria")
            .run(req);

        const errores = validationResult(req);

        if (!errores.isEmpty())
            return res.status(400).json({
                mensaje: errores.array()
            });

        const usuarioAct = await actualiza(req.params.id, req.body);

        res.status(200).json(usuarioAct);

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }

};

export const eliminaUsuario = async (req, res) => {

    try {

        const usuario = await obtUsuario(req.params.id);

        if (!usuario)
            return res.status(404).json({
                error: "Usuario no encontrado"
            });

        await elimina(req.params.id);

        res.status(200).json({
            mensaje: "Usuario eliminado correctamente"
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }

};