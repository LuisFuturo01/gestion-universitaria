import { pool }  from "../config/db.js";

export const obtTodo = async () => {

    const [resultado] = await pool.query(`
        SELECT
            u.id_usuario,
            u.username,
            p.nombres,
            p.apellidos,
            p.email
        FROM USUARIO u
        INNER JOIN PERSONA p
        ON u.id_persona = p.id_persona
        WHERE u.estado = 'A'
    `);

    return resultado;
};

export const obtUsuario = async (id) => {

    const [resultado] = await pool.query(
        `
        SELECT
            u.id_usuario,
            u.username,
            p.nombres,
            p.apellidos,
            p.email
        FROM USUARIO u
        INNER JOIN PERSONA p
        ON u.id_persona = p.id_persona
        WHERE u.id_usuario = ? AND u.estado = 'A'  
        `,
        [id]
    );

    return resultado[0];
};

export const inserta = async (usuario) => {

    const { username, password_hash, id_persona } = usuario;

    const [resultado] = await pool.query(
        `
        INSERT INTO USUARIO
        (username,password_hash,id_persona)
        VALUES(?,?,?)
        `,
        [username, password_hash, id_persona]
    );

    return {
        id_usuario: resultado.insertId,
        ...usuario
    };
};

export const actualiza = async (id, usuario) => {

    const { username, password_hash } = usuario;

    await pool.query(
        `
        UPDATE USUARIO
        SET username=?,
            password_hash=?
        WHERE id_usuario=?
        `,
        [username, password_hash, id]
    );

    return {
        id_usuario: id,
        ...usuario
    };
};

export const elimina = async (id) => {

    await pool.query(
        `
        UPDATE USUARIO
        SET estado='I'
        WHERE id_usuario=?
        `,
        [id]
    );

    return id;
};