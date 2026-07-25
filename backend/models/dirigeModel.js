import { pool } from "../config/db.js";


export const obtTodo = async()=>{

    const [resultado]=await pool.query(`
        SELECT
            d.id_persona,
            p.nombres,
            p.apellidos,
            c.id_carrera,
            c.nombre AS carrera,
            d.gestion

        FROM DIRECTOR_CARRERA_ASIGNACION d

        INNER JOIN PERSONA p
        ON d.id_persona=p.id_persona

        INNER JOIN CARRERA c
        ON d.id_carrera=c.id_carrera
    `);

    return resultado;

};


export const obtAsignacion = async(id_persona,id_carrera)=>{

    const [resultado]=await pool.query(
        `
        SELECT *
        FROM DIRECTOR_CARRERA_ASIGNACION
        WHERE id_persona=?
        AND id_carrera=?
        `,
        [
            id_persona,
            id_carrera
        ]
    );

    return resultado[0];

};


export const inserta = async(asignacion)=>{

    const {
        id_persona,
        id_carrera,
        gestion
    }=asignacion;


    await pool.query(
        `
        INSERT INTO DIRECTOR_CARRERA_ASIGNACION
        (id_persona,id_carrera,gestion)
        VALUES(?,?,?)
        `,
        [
            id_persona,
            id_carrera,
            gestion
        ]
    );


    return asignacion;

};


export const actualiza = async(id_persona,id_carrera,asignacion)=>{


    const {
        gestion
    }=asignacion;


    await pool.query(
        `
        UPDATE DIRECTOR_CARRERA_ASIGNACION
        SET gestion=?
        WHERE id_persona=?
        AND id_carrera=?
        `,
        [
            gestion,
            id_persona,
            id_carrera
        ]
    );


    return {
        id_persona,
        id_carrera,
        gestion
    };

};


export const elimina = async(id_persona,id_carrera)=>{


    await pool.query(
        `
        DELETE FROM DIRECTOR_CARRERA_ASIGNACION
        WHERE id_persona=?
        AND id_carrera=?
        `,
        [
            id_persona,
            id_carrera
        ]
    );


    return {
        id_persona,
        id_carrera
    };

};