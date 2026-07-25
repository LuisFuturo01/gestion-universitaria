import { pool } from "../config/db.js";

export const realizarInscripcion = async (inscripcion) => {
    const { id_estudiante, id_gestion, id_plan, id_materia, id_paralelo } = inscripcion;
    await pool.query(
        "CALL sp_realizar_inscripcion(?,?,?,?,?)",
        [id_estudiante, id_gestion, id_plan || 1, id_materia, id_paralelo]
    );
    return { mensaje: "Inscripción realizada correctamente." };
};

export const obtenerInscripciones = async () => {
    const [resultado] = await pool.query(
        `SELECT
            i.id_inscripcion,
            d.id_detalle,
            i.id_estudiante,
            p.nombres,
            p.apellidos,
            d.id_materia,
            m.nombre AS materia,
            d.id_paralelo,
            pa.nombre AS paralelo,
            i.id_gestion,
            g.periodo,
            COALESCE(d.estado, 'Inscrito') AS estado,
            COALESCE(d.nota_final, 0) AS nota_final
        FROM inscripcion i
        LEFT JOIN detalle_inscripcion d ON i.id_inscripcion = d.id_inscripcion
        LEFT JOIN persona p ON i.id_estudiante = p.id_persona
        LEFT JOIN materia m ON d.id_materia = m.id_materia
        LEFT JOIN paralelo pa ON d.id_materia = pa.id_materia AND d.id_paralelo = pa.id_paralelo
        LEFT JOIN gestion g ON i.id_gestion = g.id_gestion`
    );

    return resultado;
};

export const obtenerInscripcion = async (id) => {
    const [resultado] = await pool.query(
        `SELECT * FROM inscripcion WHERE id_inscripcion = ?`,
        [id]
    );
    return resultado[0];
};

export const retirarInscripcion = async (id) => {
    await pool.query(
        "CALL sp_retirar_inscripcion(?)",
        [id]
    );
    return { mensaje: "Inscripción retirada correctamente." };
};

export const AsignarNota = async (id, nota_final) => {
    await pool.query(
        'UPDATE detalle_inscripcion SET nota_final = ? WHERE id_detalle = ?',
        [nota_final, id]
    );
    return { mensaje: "Nota asignada correctamente." };
};