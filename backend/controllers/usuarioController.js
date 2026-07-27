import { obtTodo, obtUsuario, inserta, actualiza, elimina } from "../models/usuarioModel.js";
import { check, validationResult } from "express-validator";
import bcrypt from "bcrypt";

export const obtUsuarios = async (req, res) => {
    try {
        const usuarios = await obtTodo();
        res.status(200).json(usuarios);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const obtUsuarioPorID = async (req, res) => {
    try {
        const usuario = await obtUsuario(req.params.id);
        if (!usuario)
            return res.status(404).json({ error: "Usuario no encontrado" });
        res.status(200).json(usuario);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const insertaUsuario = async (req, res) => {
    try {
        const { username, password, id_persona, id_rol, idsRol, persona, nombres, apellidos, ci, fecha_nac, sexo } = req.body;
        const rolId = id_rol || (Array.isArray(idsRol) ? idsRol[0] : 1);

        const targetNombres = (persona?.nombres || nombres || "").trim();
        const targetApellidos = (persona?.apellidos || apellidos || "").trim();
        const targetCi = (persona?.ci || ci || "").trim();
        const targetFechaNac = persona?.fecha_nac || fecha_nac || "2000-01-01";
        const targetSexo = persona?.sexo || sexo || "M";

        if (targetNombres && targetApellidos && targetCi) {
            const [rows] = await pool.query(
                "CALL sp_insertar_persona_usuario(?, ?, ?, ?, ?, ?, 'A')",
                [targetCi, targetNombres, targetApellidos, targetFechaNac, targetSexo, rolId]
            );
            const creado = rows[0]?.[0] || rows[0] || {};
            const usernameGenerado = creado.username || `${targetNombres.charAt(0).toLowerCase()}${targetApellidos.split(' ')[0].toLowerCase()}`;
            const emailGenerado = creado.email || `${usernameGenerado}@fcpn.edu.bo`;

            return res.status(201).json({
                ok: true,
                username: usernameGenerado,
                email: emailGenerado,
                id_persona: creado.id_persona,
                password_temp: "123456"
            });
        }

        const passToUse = password || "123456";
        const password_hash = await bcrypt.hash(passToUse, 10);
        const userToInsert = username || `${targetNombres.charAt(0).toLowerCase()}${targetApellidos.split(' ')[0].toLowerCase()}`;

        const usuarioNuevo = await inserta({
            username: userToInsert,
            password_hash,
            id_persona,
            id_rol: rolId
        });

        res.status(201).json({
            ...usuarioNuevo,
            password_temp: "123456"
        });
    } catch (error) {
        console.error("[INSERTAR USUARIO CONTROLLER ERROR]:", error.message);
        res.status(500).json({ error: error.message });
    }
};

export const actualizaUsuario = async (req, res) => {
    try {
        const usuario = await obtUsuario(req.params.id);

        if (!usuario)
            return res.status(404).json({ error: "Usuario no encontrado" });

        const { username, password, password_hash, id_rol } = req.body;
        let passHash = password_hash;
        if (password) {
            passHash = await bcrypt.hash(password, 10);
        }

        const usuarioAct = await actualiza(req.params.id, {
            username: username || usuario.username,
            password_hash: passHash,
            id_rol
        });

        res.status(200).json(usuarioAct);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const eliminaUsuario = async (req, res) => {
    try {
        const usuario = await obtUsuario(req.params.id);

        if (!usuario)
            return res.status(404).json({ error: "Usuario no encontrado" });

        await elimina(req.params.id);

        res.status(200).json({
            mensaje: "Usuario eliminado correctamente"
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};