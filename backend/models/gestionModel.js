import { pool } from '../config/db.js';

export const crear = async (periodo) => {
    const [result] = await pool.query('CALL sp_crear_gestion(?)', [periodo]);
    return result;
};

export const obtenerTodas = async () => {
    try {
        const [rows] = await pool.query('CALL sp_obtener_gestiones()');
        return rows[0];
    } catch (e) {
        // Fallback: consulta directa si el SP no existe o falla
        const [rows] = await pool.query('SELECT id_gestion, periodo, estado FROM gestion ORDER BY id_gestion DESC');
        return rows;
    }
};

export const actualizar = async (id_gestion, periodo) => {
    const [result] = await pool.query('CALL sp_actualizar_gestion(?, ?)', [id_gestion, periodo]);
    return result;
};

export const eliminar = async (id_gestion) => {
    const [result] = await pool.query('CALL sp_eliminar_gestion(?)', [id_gestion]);
    return result;
};

// Cierre de gestión — usa sp_preview_cierre_gestion (devuelve 2 result sets: resumen + detalle)
export const previewCierre = async (id_gestion) => {
    const [rows] = await pool.query('CALL sp_preview_cierre_gestion(?)', [id_gestion]);
    // rows[0] = resumen (1 fila), rows[1] = detalle por estudiante
    return { resumen: rows[0]?.[0] || {}, detalle: rows[1] || [] };
};

// Cierre de gestión — usa sp_cerrar_gestion (transacción definitiva)
export const cerrar = async (id_gestion) => {
    const [rows] = await pool.query('CALL sp_cerrar_gestion(?)', [id_gestion]);
    return rows[0]?.[0] || {};
};

// Auditoría — consulta la tabla auditoria con datos del usuario
export const obtenerAuditoria = async () => {
    const [rows] = await pool.query(`
        SELECT 
            a.id_auditoria,
            a.id_usuario,
            u.username,
            a.accion,
            a.fecha,
            a.hora
        FROM auditoria a
        LEFT JOIN usuario u ON a.id_usuario = u.id_usuario
        ORDER BY a.fecha DESC, a.hora DESC
        LIMIT 50
    `);
    return rows;
};

// Apertura e Inicio de Nueva Gestión con Generación Automática de Paralelos (1 paralelo A por materia)
export const iniciarGestionConParalelos = async (periodo, usuarioAudit = 1) => {
    const connection = await pool.getConnection();
    try {
        await connection.beginTransaction();

        // 0. Asegurar que la Llave Primaria incluya id_gestion y que id_docente permita NULL
        try {
            await connection.query('ALTER TABLE paralelo DROP PRIMARY KEY, ADD PRIMARY KEY (id_materia, id_paralelo, id_gestion)');
        } catch (ePK) {}
        try {
            await connection.query('ALTER TABLE paralelo MODIFY COLUMN id_docente INT(11) NULL DEFAULT NULL');
        } catch (eAlter) {}

        // Configurar usuario de auditoría para evitar registros fantasma
        await connection.query('SET @current_user_id = ?', [usuarioAudit || 1]);

        // 1. Verificar si ya existe una gestión con ese código de periodo
        let newIdGestion;
        const [gestionesExistentes] = await connection.query(
            'SELECT id_gestion, estado FROM gestion WHERE periodo = ?',
            [periodo]
        );
        if (gestionesExistentes.length > 0) {
            if (gestionesExistentes[0].estado === 'Activa') {
                throw new Error(`La gestión con periodo '${periodo}' ya se encuentra actualmente activa.`);
            }
            newIdGestion = gestionesExistentes[0].id_gestion;
            await connection.query("UPDATE gestion SET estado = 'Activa' WHERE id_gestion = ?", [newIdGestion]);
        } else {
            const [resGestion] = await connection.query(
                "INSERT INTO gestion (periodo, estado) VALUES (?, 'Activa')",
                [periodo]
            );
            newIdGestion = resGestion.insertId;
        }

        // 4. Obtener materias y aulas
        const [materias] = await connection.query('SELECT id_materia, sigla, nombre FROM materia');
        const [aulas] = await connection.query('SELECT id_aula, capacidad FROM aula ORDER BY capacidad DESC');

        let paralelosCreados = 0;

        for (let i = 0; i < materias.length; i++) {
            const materia = materias[i];
            const aula = aulas.length > 0 ? aulas[i % aulas.length] : { id_aula: 1, capacidad: 40 };

            // EL CUPO MÁXIMO DEL PARALELO NUNCA EXCEDE LA CAPACIDAD MÁXIMA DEL AULA ASIGNADA
            const cupoMaximo = Math.min(40, aula.capacidad || 40);

            try {
                // Intentar insertar con NULL
                await connection.query(
                    `INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
                     VALUES (?, 1, 'A', ?, 0, NULL, ?)`,
                    [materia.id_materia, cupoMaximo, newIdGestion]
                );
                paralelosCreados++;
            } catch (errInsert) {
                // Fallback por si la BD requiere id_docente no nulo
                try {
                    await connection.query(
                        `INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
                         VALUES (?, 1, 'A', ?, 0, 0, ?)`,
                        [materia.id_materia, cupoMaximo, newIdGestion]
                    );
                    paralelosCreados++;
                } catch (errFallback) {
                    console.warn(`Error al aperturar paralelo para ${materia.sigla}:`, errFallback.message);
                }
            }
        }

        // Asignación automática sin choque de aulas y horarios en se_cursa
        try {
            await connection.query('CALL sp_asignar_horarios_sin_choque(?)', [newIdGestion]);
        } catch (eSP) {
            console.warn('[SP WARN] No se pudo ejecutar sp_asignar_horarios_sin_choque:', eSP.message);
        }

        await connection.commit();
        return {
            id_gestion: newIdGestion,
            periodo,
            paralelos_creados: paralelosCreados
        };
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
};

// Función de autorreparación: asegura la llave primaria correcta y genera paralelos para la gestión activa actual
export const repararParalelosGestionActiva = async () => {
    try {
        // 1. Modificar la Llave Primaria de paralelo para incluir id_gestion (evita ER_DUP_ENTRY '1-1')
        try {
            await pool.query('ALTER TABLE paralelo DROP PRIMARY KEY, ADD PRIMARY KEY (id_materia, id_paralelo, id_gestion)');
        } catch (ePK) {
            /* ignora si la llave primaria ya incluye id_gestion */
        }

        // 2. Asegurar que id_docente permita NULL
        try {
            await pool.query('ALTER TABLE paralelo MODIFY COLUMN id_docente INT(11) NULL DEFAULT NULL');
        } catch (eNull) {}

        // 3. Consolidar que solo la última gestión permanezca como 'Activa'
        try {
            await pool.query("UPDATE gestion SET estado = 'Cerrada' WHERE LOWER(estado) = 'activa' AND id_gestion NOT IN (SELECT max_id FROM (SELECT MAX(id_gestion) AS max_id FROM gestion WHERE LOWER(estado) = 'activa') AS t)");
        } catch (eClean) {}

        let [gestionesActivas] = await pool.query(
            "SELECT id_gestion, periodo FROM gestion WHERE LOWER(estado) = 'activa' ORDER BY id_gestion DESC"
        );

        if (gestionesActivas.length === 0) {
            const [ultimaGestion] = await pool.query(
                "SELECT id_gestion, periodo FROM gestion ORDER BY id_gestion DESC LIMIT 1"
            );
            if (ultimaGestion.length > 0) {
                await pool.query("UPDATE gestion SET estado = 'Activa' WHERE id_gestion = ?", [ultimaGestion[0].id_gestion]);
                gestionesActivas = ultimaGestion;
            } else {
                return { reparados: 0 };
            }
        }

        const idGestionActiva = gestionesActivas[0].id_gestion;

        // 3. Obtener materias que YA tienen un paralelo en la gestión activa
        const [paralelosExistentes] = await pool.query(
            'SELECT id_materia FROM paralelo WHERE id_gestion = ?',
            [idGestionActiva]
        );

        const idsMateriasConParalelo = new Set(paralelosExistentes.map((p) => Number(p.id_materia)));
        const [materias] = await pool.query('SELECT id_materia, sigla FROM materia');
        const [aulas] = await pool.query('SELECT id_aula, capacidad FROM aula ORDER BY capacidad DESC');

        let agregados = 0;
        for (let i = 0; i < materias.length; i++) {
            const m = materias[i];
            const idMat = Number(m.id_materia);

            if (!idsMateriasConParalelo.has(idMat)) {
                const aula = aulas.length > 0 ? aulas[i % aulas.length] : { id_aula: 1, capacidad: 40 };
                const cupoMaximo = Math.min(40, aula.capacidad || 40);

                try {
                    await pool.query(
                        `INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
                         VALUES (?, 1, 'A', ?, 0, NULL, ?)`,
                        [idMat, cupoMaximo, idGestionActiva]
                    );
                    agregados++;
                } catch (err) {
                    try {
                        await pool.query(
                            `INSERT INTO paralelo (id_materia, id_paralelo, nombre, cupo_maximo, cupo_actual, id_docente, id_gestion)
                             VALUES (?, 1, 'A', ?, 0, 0, ?)`,
                            [idMat, cupoMaximo, idGestionActiva]
                        );
                        agregados++;
                    } catch (e2) {
                        console.warn(`[REPAIR WARN] No se pudo crear paralelo para ${m.sigla}:`, e2.message);
                    }
                }
            }
        }

        if (agregados > 0) {
            console.log(`[AUTO-REPAIR] ¡Se aperturaron ${agregados} paralelos faltantes para la gestión activa (${gestionesActivas[0].periodo})!`);
        }
        return { reparados: agregados };
    } catch (e) {
        console.warn("[AUTO-REPAIR WARN]", e.message);
        return { reparados: 0 };
    }
};