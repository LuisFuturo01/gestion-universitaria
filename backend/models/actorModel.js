import { pool } from "../config/db.js";
import bcrypt from "bcrypt";

export const obtTodo = async () => {

    const [resultado] = await pool.query(`
        SELECT
            id_persona,
            ci,
            nombres,
            apellidos,
            fecha_nac,
            sexo,
            email
        FROM PERSONA
        WHERE estado='A'
    `);

    return resultado;

};

export const obtActor = async (id) => {

    const [resultado] = await pool.query(`
        SELECT
            id_persona,
            ci,
            nombres,
            apellidos,
            fecha_nac,
            sexo,
            email
        FROM PERSONA
        WHERE id_persona=? AND estado='A'
    `,[id]);

    return resultado[0];

};

export const inserta = async (actor) => {

    const {
        ci,
        nombres,
        apellidos,
        fecha_nac,
        sexo,
        email
    } = actor;

    const [resultado] = await pool.query(`
        INSERT INTO PERSONA
        (
            ci,
            nombres,
            apellidos,
            fecha_nac,
            sexo,
            email
        )
        VALUES (?,?,?,?,?,?)
    `,[
        ci,
        nombres,
        apellidos,
        fecha_nac,
        sexo,
        email
    ]);

    return {
        id_persona: resultado.insertId,
        ...actor
    };

};

export const actualiza = async (id,actor) => {

    const {
        ci,
        nombres,
        apellidos,
        fecha_nac,
        sexo,
        email
    } = actor;

    await pool.query(`
        UPDATE PERSONA
        SET
            ci=?,
            nombres=?,
            apellidos=?,
            fecha_nac=?,
            sexo=?,
            email=?
        WHERE id_persona=?
    `,[
        ci,
        nombres,
        apellidos,
        fecha_nac,
        sexo,
        email,
        id
    ]);

    return {
        id_persona:id,
        ...actor
    };

};

export const elimina = async (id) => {

    await pool.query(`
        UPDATE PERSONA
        SET estado='I'
        WHERE id_persona=?
    `,[id]);

    return id;

};

// =======================
// ESTUDIANTES
// =======================

export const obtTodoEstudiantes = async () => {

    const [resultado] = await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.email,
            e.ru,
            e.id_plan,
            e.anio_ingreso
        FROM PERSONA p
        INNER JOIN ESTUDIANTE e
        ON p.id_persona=e.id_persona
        WHERE p.estado='A'
    `);
    return resultado;

};

export const obtEstudiante = async (id) => {

    const [resultado] = await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.email,
            e.ru,
            e.id_plan,
            e.anio_ingreso
        FROM PERSONA p
        INNER JOIN ESTUDIANTE e
        ON p.id_persona=e.id_persona
        WHERE p.id_persona=? AND p.estado='A'
    `,[id]);

    return resultado[0];

};

export const insertaEst = async (estudiante) => {
    const conexion = await pool.getConnection();
    try{
        await conexion.beginTransaction();
        const {ci,nombres,apellidos,fecha_nac,sexo,email,username,password,ru,id_plan,anio_ingreso}=estudiante;
        const hash=await bcrypt.hash(password,10);
        const [persona]=await conexion.query(`
            INSERT INTO PERSONA(ci,nombres,apellidos,fecha_nac,sexo,email)
            VALUES(?,?,?,?,?,?)
        `,[ci,nombres,apellidos,fecha_nac,sexo,email]);
        const id_persona=persona.insertId;
        const [usuario]=await conexion.query(`
            INSERT INTO USUARIO(username,password_hash,id_persona)
            VALUES(?,?,?)
        `,[username,hash,id_persona]);
        const id_usuario=usuario.insertId;
        await conexion.query(`
            INSERT INTO TIENE_ROL(id_usuario,id_rol)
            VALUES(?,3)
        `,[id_usuario]);

        await conexion.query(`
            INSERT INTO ESTUDIANTE(id_persona,ru,id_plan,anio_ingreso)
            VALUES(?,?,?,?)
        `,[id_persona,ru,id_plan,anio_ingreso]);

        await conexion.commit();

        return{
            id_persona,
            id_usuario,
            mensaje:"Estudiante registrado correctamente"
        };
    }catch(error){
        await conexion.rollback();
        throw error;
    }finally{

        conexion.release();
    }
};

export const actualizaEst = async (id,estudiante) => {

    const { ru,id_plan,anio_ingreso } = estudiante;

    await pool.query(`
        UPDATE ESTUDIANTE
        SET ru=?,id_plan=?,anio_ingreso=?
        WHERE id_persona=?
    `,[ru,id_plan,anio_ingreso,id]);

    return { id_persona:id,...estudiante };

};

export const eliminaEst = async (id) => {

    await pool.query(`
        UPDATE PERSONA
        SET estado='I'
        WHERE id_persona=?
    `,[id]);

    return id;

};

// =======================
// DOCENTES
// =======================

export const obtTodoDocentes = async () => {

    const [resultado] = await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.fecha_nac,
            p.sexo,
            p.email,
            d.registro_docente,
            d.grado_academico
        FROM PERSONA p
        INNER JOIN DOCENTE d ON p.id_persona=d.id_persona
        WHERE p.estado='A'
    `);

    return resultado;

};

export const obtDocente = async (id) => {

    const [resultado] = await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.fecha_nac,
            p.sexo,
            p.email,
            d.registro_docente,
            d.grado_academico
        FROM PERSONA p
        INNER JOIN DOCENTE d ON p.id_persona=d.id_persona
        WHERE p.id_persona=? AND p.estado='A'
    `,[id]);

    return resultado[0];

};

export const actualizaDoc = async (id,docente)=>{

    const conexion=await pool.getConnection();

    try{

        await conexion.beginTransaction();

        const {ci,nombres,apellidos,fecha_nac,sexo,email,registro_docente,grado_academico}=docente;

        await conexion.query(`
            UPDATE PERSONA
            SET ci=?,nombres=?,apellidos=?,fecha_nac=?,sexo=?,email=?
            WHERE id_persona=?
        `,[ci,nombres,apellidos,fecha_nac,sexo,email,id]);

        await conexion.query(`
            UPDATE DOCENTE
            SET registro_docente=?,grado_academico=?
            WHERE id_persona=?
        `,[registro_docente,grado_academico,id]);

        await conexion.commit();

        return{id_persona:id,...docente};

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};

export const eliminaDoc = async(id)=>{

    const conexion=await pool.getConnection();
    try{
        await conexion.beginTransaction();
        await conexion.query(`
            UPDATE PERSONA
            SET estado='I'
            WHERE id_persona=?
        `,[id]);
        await conexion.query(`
            UPDATE USUARIO
            SET estado='I'
            WHERE id_persona=?
        `,[id]);
        await conexion.commit();
        return id;
    }catch(error){
        await conexion.rollback();
        throw error;
    }finally{
        conexion.release();
    }
}
export const insertaDoc = async (docente) => {

    const conexion = await pool.getConnection();

    try{

        await conexion.beginTransaction();

        const {ci,nombres,apellidos,fecha_nac,sexo,email,username,password,registro_docente,grado_academico}=docente;

        const hash=await bcrypt.hash(password,10);

        const [persona]=await conexion.query(`
            INSERT INTO PERSONA(ci,nombres,apellidos,fecha_nac,sexo,email)
            VALUES(?,?,?,?,?,?)
        `,[ci,nombres,apellidos,fecha_nac,sexo,email]);

        const id_persona=persona.insertId;

        const [usuario]=await conexion.query(`
            INSERT INTO USUARIO(username,password_hash,id_persona)
            VALUES(?,?,?)
        `,[username,hash,id_persona]);

        const id_usuario=usuario.insertId;

        await conexion.query(`
            INSERT INTO TIENE_ROL(id_usuario,id_rol)
            VALUES(?,2)
        `,[id_usuario]);

        await conexion.query(`
            INSERT INTO DOCENTE(id_persona,registro_docente,grado_academico)
            VALUES(?,?,?)
        `,[id_persona,registro_docente,grado_academico]);

        await conexion.commit();

        return{
            id_persona,
            id_usuario,
            mensaje:"Docente registrado correctamente"
        };

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};

// =======================
// ADMINISTRATIVOS
// =======================

export const obtTodoAdministrativos=async()=>{

    const [resultado]=await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.fecha_nac,
            p.sexo,
            p.email,
            a.item
        FROM PERSONA p
        INNER JOIN ADMINISTRATIVO a
        ON p.id_persona=a.id_persona
        WHERE p.estado='A'
    `);

    return resultado;

};

export const obtAdministrativo=async(id)=>{

    const [resultado]=await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.fecha_nac,
            p.sexo,
            p.email,
            a.item
        FROM PERSONA p
        INNER JOIN ADMINISTRATIVO a
        ON p.id_persona=a.id_persona
        WHERE p.id_persona=? AND p.estado='A'
    `,[id]);

    return resultado[0];

};

export const actualizaAdm=async(id,administrativo)=>{

    const conexion=await pool.getConnection();

    try{

        await conexion.beginTransaction();

        const {ci,nombres,apellidos,fecha_nac,sexo,email,item}=administrativo;

        await conexion.query(`
            UPDATE PERSONA
            SET ci=?,nombres=?,apellidos=?,fecha_nac=?,sexo=?,email=?
            WHERE id_persona=?
        `,[ci,nombres,apellidos,fecha_nac,sexo,email,id]);

        await conexion.query(`
            UPDATE ADMINISTRATIVO
            SET item=?
            WHERE id_persona=?
        `,[item,id]);

        await conexion.commit();

        return{id_persona:id,...administrativo};

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};

export const eliminaAdm=async(id)=>{

    const conexion=await pool.getConnection();

    try{

        await conexion.beginTransaction();

        await conexion.query(`
            UPDATE PERSONA
            SET estado='I'
            WHERE id_persona=?
        `,[id]);

        await conexion.query(`
            UPDATE USUARIO
            SET estado='I'
            WHERE id_persona=?
        `,[id]);

        await conexion.commit();

        return id;

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};
export const insertaAdm = async (administrativo) => {

    const conexion = await pool.getConnection();

    try{

        await conexion.beginTransaction();

        const {ci,nombres,apellidos,fecha_nac,sexo,email,username,password,item}=administrativo;

        const hash=await bcrypt.hash(password,10);

        const [persona]=await conexion.query(`
            INSERT INTO PERSONA(ci,nombres,apellidos,fecha_nac,sexo,email)
            VALUES(?,?,?,?,?,?)
        `,[ci,nombres,apellidos,fecha_nac,sexo,email]);

        const id_persona=persona.insertId;

        const [usuario]=await conexion.query(`
            INSERT INTO USUARIO(username,password_hash,id_persona)
            VALUES(?,?,?)
        `,[username,hash,id_persona]);

        const id_usuario=usuario.insertId;

        await conexion.query(`
            INSERT INTO TIENE_ROL(id_usuario,id_rol)
            VALUES(?,1)
        `,[id_usuario]);

        await conexion.query(`
            INSERT INTO ADMINISTRATIVO(id_persona,item)
            VALUES(?,?)
        `,[id_persona,item]);

        await conexion.commit();

        return{
            id_persona,
            id_usuario,
            mensaje:"Administrativo registrado correctamente"
        };

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{
        conexion.release();
    }
};

// =======================
// DIRECTORES DE CARRERA
// =======================
export const obtTodoDirectores=async()=>{

    const [resultado]=await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.fecha_nac,
            p.sexo,
            p.email,
            d.registro_docente,
            d.grado_academico,
            a.id_carrera,
            c.nombre carrera,
            a.gestion
        FROM PERSONA p
        INNER JOIN DOCENTE d ON p.id_persona=d.id_persona
        INNER JOIN DIRECTOR_CARRERA dc ON p.id_persona=dc.id_persona
        INNER JOIN DIRECTOR_CARRERA_ASIGNACION a ON dc.id_persona=a.id_persona
        INNER JOIN CARRERA c ON a.id_carrera=c.id_carrera
        WHERE p.estado='A'
    `);

    return resultado;

};

export const obtDirector=async(id)=>{

    const [resultado]=await pool.query(`
        SELECT
            p.id_persona,
            p.ci,
            p.nombres,
            p.apellidos,
            p.fecha_nac,
            p.sexo,
            p.email,
            d.registro_docente,
            d.grado_academico,
            a.id_carrera,
            c.nombre carrera,
            a.gestion
        FROM PERSONA p
        INNER JOIN DOCENTE d ON p.id_persona=d.id_persona
        INNER JOIN DIRECTOR_CARRERA dc ON p.id_persona=dc.id_persona
        INNER JOIN DIRECTOR_CARRERA_ASIGNACION a ON dc.id_persona=a.id_persona
        INNER JOIN CARRERA c ON a.id_carrera=c.id_carrera
        WHERE p.id_persona=? AND p.estado='A'
    `,[id]);

    return resultado[0];

};

export const actualizaDirector=async(id,director)=>{

    const conexion=await pool.getConnection();

    try{

        await conexion.beginTransaction();

        const{
            ci,
            nombres,
            apellidos,
            fecha_nac,
            sexo,
            email,
            registro_docente,
            grado_academico,
            id_carrera,
            gestion
        }=director;

        await conexion.query(`
            UPDATE PERSONA
            SET ci=?,nombres=?,apellidos=?,fecha_nac=?,sexo=?,email=?
            WHERE id_persona=?
        `,[ci,nombres,apellidos,fecha_nac,sexo,email,id]);

        await conexion.query(`
            UPDATE DOCENTE
            SET registro_docente=?,grado_academico=?
            WHERE id_persona=?
        `,[registro_docente,grado_academico,id]);

        await conexion.query(`
            UPDATE DIRECTOR_CARRERA_ASIGNACION
            SET id_carrera=?,gestion=?
            WHERE id_persona=?
        `,[id_carrera,gestion,id]);

        await conexion.commit();

        return{id_persona:id,...director};

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};

export const eliminaDirector=async(id)=>{

    const conexion=await pool.getConnection();

    try{

        await conexion.beginTransaction();

        await conexion.query(`
            UPDATE PERSONA
            SET estado='I'
            WHERE id_persona=?
        `,[id]);

        await conexion.query(`
            UPDATE USUARIO
            SET estado='I'
            WHERE id_persona=?
        `,[id]);

        await conexion.commit();

        return id;

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};
export const insertaDirec = async (director) => {

    const conexion = await pool.getConnection();

    try{

        await conexion.beginTransaction();

        const {ci,nombres,apellidos,fecha_nac,sexo,email,username,password,registro_docente,grado_academico,id_carrera,gestion}=director;

        const hash=await bcrypt.hash(password,10);

        const [persona]=await conexion.query(`
            INSERT INTO PERSONA(ci,nombres,apellidos,fecha_nac,sexo,email)
            VALUES(?,?,?,?,?,?)
        `,[ci,nombres,apellidos,fecha_nac,sexo,email]);

        const id_persona=persona.insertId;

        const [usuario]=await conexion.query(`
            INSERT INTO USUARIO(username,password_hash,id_persona)
            VALUES(?,?,?)
        `,[username,hash,id_persona]);

        const id_usuario=usuario.insertId;

        await conexion.query(`
            INSERT INTO TIENE_ROL(id_usuario,id_rol)
            VALUES(?,4)
        `,[id_usuario]);

        await conexion.query(`
            INSERT INTO DOCENTE(id_persona,registro_docente,grado_academico)
            VALUES(?,?,?)
        `,[id_persona,registro_docente,grado_academico]);

        await conexion.query(`
            INSERT INTO DIRECTOR_CARRERA(id_persona)
            VALUES(?)
        `,[id_persona]);

        await conexion.query(`
            INSERT INTO DIRIGE(id_persona,id_carrera,gestion)
            VALUES(?,?,?)
        `,[id_persona,id_carrera,gestion]);

        await conexion.commit();

        return{
            id_persona,
            id_usuario,
            mensaje:"Director registrado correctamente"
        };

    }catch(error){

        await conexion.rollback();
        throw error;

    }finally{

        conexion.release();

    }

};