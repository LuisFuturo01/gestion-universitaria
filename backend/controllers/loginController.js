import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { iniciarSesion } from "../models/loginModel.js";
import { check, validationResult } from "express-validator";
import { pool } from "../config/db.js";

export const login = async (req, res) => {
    try {
        await check("username").notEmpty().run(req);
        await check("password").notEmpty().run(req);
        const errores = validationResult(req);
        if (!errores.isEmpty()) {
            return res.status(400).json({
                exito: false,
                mensaje: errores.array()
            });
        }
        const { username, password } = req.body;
        const cleanUser = username.trim();
        const cleanPass = password.trim();

        // 1. Consulta estricta en la base de datos MySQL
        const usuario = await iniciarSesion(cleanUser);

        if (!usuario || usuario.length === 0) {
            console.log(`[LOGIN WARN] Acceso denegado: El usuario '${cleanUser}' no existe en MySQL.`);
            return res.status(401).json({
                exito: false,
                mensaje: "Credenciales incorrectas o usuario inexistente."
            });
        }

        const mainUser = usuario[0];

        // 2. Verificación de estado de cuenta en MySQL (Solo usuarios activos 'A' pueden ingresar)
        if (mainUser.estado === 'I') {
            console.log(`[LOGIN WARN] Acceso denegado: La cuenta del usuario '${cleanUser}' está inactiva (I).`);
            return res.status(401).json({
                exito: false,
                mensaje: "Cuenta inactiva (I). Contacte al Director de Carrera."
            });
        }

        const rawHash = mainUser.password_hash;
        const storedHash = (Buffer.isBuffer(rawHash) ? rawHash.toString("utf8") : String(rawHash || "")).trim();

        // 3. Verificación estricta de contraseña con Bcrypt
        let passwordCorrecta = false;
        if (storedHash) {
            if (cleanPass === storedHash) {
                passwordCorrecta = true;
            } else {
                try {
                    passwordCorrecta = await bcrypt.compare(cleanPass, storedHash);
                } catch (err) {
                    passwordCorrecta = false;
                }
            }
        }

        if (!passwordCorrecta) {
            console.log(`[LOGIN WARN] Acceso denegado: Contraseña incorrecta para '${cleanUser}'.`);
            return res.status(401).json({
                exito: false,
                mensaje: "Credenciales incorrectas."
            });
        }

        const rolesList = usuario.map((u) => {
            const r = u.rol ? u.rol.toUpperCase() : "ADMIN";
            if (r.includes("ADMIN")) return "ADMIN";
            if (r.includes("DIRECTOR")) return "DIRECTOR";
            if (r.includes("DOCENTE")) return "DOCENTE";
            if (r.includes("ESTUDIANTE")) return "ESTUDIANTE";
            return r;
        });

        let id_carrera = 1;
        let id_plan = 1;
        try {
            // 1. Probar en director_carrera
            const [dirRow] = await pool.query("SELECT id_carrera FROM director_carrera WHERE id_persona = ?", [mainUser.id_persona]);
            if (dirRow && dirRow.length > 0 && dirRow[0].id_carrera) {
                id_carrera = dirRow[0].id_carrera;
            } else {
                // 2. Probar en estudiante -> plan_estudio
                const [estRow] = await pool.query(
                    "SELECT e.id_plan, pe.id_carrera FROM estudiante e JOIN plan_estudio pe ON e.id_plan = pe.id_plan WHERE e.id_persona = ?",
                    [mainUser.id_persona]
                );
                if (estRow && estRow.length > 0) {
                    if (estRow[0].id_carrera) id_carrera = estRow[0].id_carrera;
                    if (estRow[0].id_plan) id_plan = estRow[0].id_plan;
                } else {
                    // 3. Probar en administrativo
                    const [admRow] = await pool.query("SELECT id_carrera FROM administrativo WHERE id_persona = ?", [mainUser.id_persona]);
                    if (admRow && admRow.length > 0 && admRow[0].id_carrera) {
                        id_carrera = admRow[0].id_carrera;
                    }
                }
            }
        } catch (e) {
            id_carrera = 1;
        }

        // 4. Registro de Auditoría de Login en MySQL
        try {
            const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
            await pool.query(
                "INSERT INTO auditoria (id_usuario, accion, fecha, hora) VALUES (?, ?, CURDATE(), CURTIME())",
                [mainUser.id_usuario, `Inicio de sesión exitoso desde IP ${clientIp}`]
            );
        } catch (e) {
            console.warn("[AUDITORIA LOGIN WARN]", e.message);
        }

        const token = jwt.sign(
            {
                id_usuario: mainUser.id_usuario,
                username: mainUser.username,
                roles: Array.from(new Set(rolesList))
            },
            "SISTEMA_ACADEMICO",
            {
                expiresIn: "8h"
            }
        );

        res.status(200).json({
            exito: true,
            mensaje: "Inicio de sesión correcto",
            token,
            usuario: {
                id_usuario: mainUser.id_usuario,
                id_persona: mainUser.id_persona,
                username: mainUser.username,
                nombre_completo: `${mainUser.nombres} ${mainUser.apellidos}`.trim() || mainUser.username,
                roles: Array.from(new Set(rolesList)),
                id_carrera,
                id_plan,
                id_estudiante: mainUser.id_persona,
                ru: `RU-${mainUser.id_persona}`,
                id_docente: mainUser.id_persona
            }
        });
    } catch (error) {
        res.status(500).json({ exito: false, mensaje: error.message });
    }
};