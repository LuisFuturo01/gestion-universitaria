import { obtTodo, obtUsuario, inserta, actualiza, elimina } from "../models/usuarioModel.js";
import { pool, adminPool } from "../config/db.js";
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
        const { username, password, id_persona, id_rol, idsRol, persona, nombres, apellidos, ci, fecha_nac, sexo, id_plan, id_carrera } = req.body;
        const rolId = Number(id_rol || (Array.isArray(idsRol) ? idsRol[0] : 1));
        const planId = Number(id_plan || 1);
        const carreraId = Number(id_carrera || 1);

        const targetNombres = (persona?.nombres || nombres || "").trim();
        const targetApellidos = (persona?.apellidos || apellidos || "").trim();
        const targetCi = (persona?.ci || ci || "").trim();
        const targetFechaNac = persona?.fecha_nac || fecha_nac || "2000-01-01";
        const targetSexo = persona?.sexo || sexo || "M";

        if (!targetNombres || !targetApellidos || !targetCi) {
            return res.status(400).json({ error: "Nombres, Apellidos y CI son obligatorios para crear usuario." });
        }

        const activePool = pool || adminPool;
        const currentUserId = req.usuario?.id_usuario || null;

        const connection = await activePool.getConnection();
        try {
            if (currentUserId) {
                await connection.query("SET @current_user_id = ?", [currentUserId]);
            }
            const [rows] = await connection.query(
                "CALL sp_insertar_persona_usuario(?, ?, ?, ?, ?, ?, 'A')",
                [targetCi, targetNombres, targetApellidos, targetFechaNac, targetSexo, rolId]
            );
            const creado = rows[0]?.[0] || rows[0] || {};
            const usernameGenerado = creado.username || `${targetNombres.charAt(0).toLowerCase()}${targetApellidos.split(' ')[0].toLowerCase()}`;
            const emailGenerado = creado.email || `${usernameGenerado}@fcpn.edu.bo`;
            const idPersonaNuevo = creado.id_persona;

            // Hashear con bcrypt la contraseña por defecto '123456' antes de guardarla en la BD
            const defaultPassHash = await bcrypt.hash("123456", 10);
            if (idPersonaNuevo) {
                await connection.query("UPDATE usuario SET password_hash = ? WHERE id_persona = ?", [defaultPassHash, idPersonaNuevo]);
                
                // Vincular específicamente Carrera y Plan de Estudio (Mención) según el rol asignado
                if (rolId === 4) { // Estudiante
                    await connection.query(
                        "INSERT INTO estudiante (id_persona, ru, id_plan, anio_ingreso) VALUES (?, ?, ?, YEAR(CURDATE())) ON DUPLICATE KEY UPDATE id_plan = VALUES(id_plan)",
                        [idPersonaNuevo, `RU-${idPersonaNuevo}`, planId]
                    );
                } else if (rolId === 3) { // Docente
                    await connection.query(
                        "INSERT INTO docente (id_persona, registro_docente, grado_academico) VALUES (?, ?, 'Lic.') ON DUPLICATE KEY UPDATE id_persona = VALUES(id_persona)",
                        [idPersonaNuevo, `DOC-${idPersonaNuevo}`]
                    );
                } else if (rolId === 2) { // Director
                    await connection.query(
                        "INSERT INTO director_carrera (id_persona, id_carrera, gestion) VALUES (?, ?, '2026') ON DUPLICATE KEY UPDATE id_carrera = VALUES(id_carrera)",
                        [idPersonaNuevo, carreraId]
                    );
                } else if (rolId === 1) { // Admin
                    await connection.query(
                        "INSERT INTO administrativo (id_persona, item, id_carrera) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE id_carrera = VALUES(id_carrera)",
                        [idPersonaNuevo, `ADM-${idPersonaNuevo}`, carreraId]
                    );
                }
            }

            return res.status(201).json({
                ok: true,
                username: usernameGenerado,
                email: emailGenerado,
                id_persona: idPersonaNuevo,
                id_plan: planId,
                id_carrera: carreraId,
                password_temp: "123456"
            });
        } finally {
            connection.release();
        }
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