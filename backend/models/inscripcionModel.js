import { pool } from "../config/db.js";

export const realizarInscripcion = async (inscripcion) => {

    const {
        id_estudiante, id_gestion, id_plan, id_materia, id_paralelo } = inscripcion;

    await pool.query(

        "CALL sp_realizar_inscripcion(?,?,?,?,?)",

        [
            id_estudiante,
            id_gestion,
            id_plan,
            id_materia,
            id_paralelo
        ]

    );
    return { mensaje: "Inscripción realizada correctamente." };
};

export const obtenerInscripciones = async () => {

    const [resultado] = await pool.query(

        `SELECT
i.id_inscripcion,
p.nombres,
p.apellidos,
m.nombre materia,
pa.nombre paralelo,
g.periodo,
d.estado,
d.nota_final
FROM INSCRIPCION i
INNER JOIN ESTUDIANTE e
ON i.id_estudiante=e.id_persona
INNER JOIN PERSONA p
ON e.id_persona=p.id_persona
INNER JOIN DETALLE_INSCRIPCION d
ON i.id_inscripcion=d.id_inscripcion
INNER JOIN MATERIA m
ON d.id_materia=m.id_materia
INNER JOIN PARALELO pa
ON d.id_materia=pa.id_materia
AND d.id_paralelo=pa.id_paralelo
INNER JOIN GESTION g
ON i.id_gestion=g.id_gestion`

    );

    return resultado;

};

export const obtenerInscripcion = async (id) => {

    const [resultado] = await pool.query(

        `SELECT
*
FROM INSCRIPCION
WHERE id_inscripcion=?`,

        [id]

    );

    return resultado[0];
};

export const retirarInscripcion = async (id) => {

    await pool.query(

        "CALL sp_retirar_inscripcion(?)",

        [id]

    );

    return {

        mensaje: "Inscripción retirada correctamente."

    };
};

export const AsignarNota = async (id, nota_final) => {
    await pool.query(
        'UPDATE DETALLE_INSCRIPCION SET nota_final=? WHERE id_detalle=? AND estado="Inscrito"',
        [nota_final, id]
    );

    return { mensaje: "Nota asignada correctamente." };
}