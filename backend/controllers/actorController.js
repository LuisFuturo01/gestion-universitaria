import {obtTodo,obtActor,inserta,actualiza,elimina} from "../models/actorModel.js";
import {obtTodoEstudiantes,obtEstudiante,insertaEst,actualizaEst,eliminaEst} from "../models/actorModel.js";
import {obtTodoDocentes,obtDocente,insertaDoc,actualizaDoc,eliminaDoc} from "../models/actorModel.js";
import {obtTodoAdministrativos,obtAdministrativo,actualizaAdm,eliminaAdm} from "../models/actorModel.js";
import {obtTodoDirectores,obtDirector,insertaDirec,actualizaDirector,eliminaDirector} from "../models/actorModel.js";

import { check, validationResult } from "express-validator";

export const obtActores = async (req,res) => {

    try {

        const actores = await obtTodo();

        res.status(200).json(actores);

    } catch (error) {

        res.status(500).json({
            error:error.message
        });

    }

};

export const obtActorPorID = async (req,res) => {

    try {

        const actor = await obtActor(req.params.id);

        if(!actor){

            return res.status(404).json({
                mensaje:"Actor no encontrado"
            });

        }

        res.status(200).json(actor);

    } catch (error) {

        res.status(500).json({
            error:error.message
        });

    }

};

export const insertaActor = async (req,res) => {

    try {

        await check("ci").notEmpty().withMessage("El CI es obligatorio").run(req);
        await check("nombres").notEmpty().withMessage("Los nombres son obligatorios").run(req);
        await check("apellidos").notEmpty().withMessage("Los apellidos son obligatorios").run(req);
        await check("fecha_nac").notEmpty().withMessage("La fecha de nacimiento es obligatoria").run(req);
        await check("sexo").isIn(["M","F"]).withMessage("Sexo inválido").run(req);
        await check("email").isEmail().withMessage("Correo electrónico inválido").run(req);

        const errores = validationResult(req);

        if(!errores.isEmpty()){

            return res.status(400).json({
                mensaje:errores.array()
            });

        }

        const actorNuevo = await inserta(req.body);

        res.status(201).json(actorNuevo);

    } catch (error) {

        res.status(500).json({
            error:error.message
        });

    }

};

export const actualizaActor = async (req,res) => {

    try {

        const actor = await obtActor(req.params.id);

        if(!actor){

            return res.status(404).json({
                mensaje:"Actor no encontrado"
            });

        }

        await check("ci").notEmpty().withMessage("El CI es obligatorio").run(req);
        await check("nombres").notEmpty().withMessage("Los nombres son obligatorios").run(req);
        await check("apellidos").notEmpty().withMessage("Los apellidos son obligatorios").run(req);
        await check("fecha_nac").notEmpty().withMessage("La fecha de nacimiento es obligatoria").run(req);
        await check("sexo").isIn(["M","F"]).withMessage("Sexo inválido").run(req);
        await check("email").isEmail().withMessage("Correo electrónico inválido").run(req);

        const errores = validationResult(req);

        if(!errores.isEmpty()){

            return res.status(400).json({
                mensaje:errores.array()
            });

        }

        const actorActualizado = await actualiza(req.params.id,req.body);

        res.status(200).json(actorActualizado);

    } catch (error) {

        res.status(500).json({
            error:error.message
        });

    }

};

export const eliminaActor = async (req,res) => {

    try {

        const actor = await obtActor(req.params.id);

        if(!actor){

            return res.status(404).json({
                mensaje:"Actor no encontrado"
            });

        }

        await elimina(req.params.id);

        res.status(200).json({
            mensaje:"Actor eliminado correctamente"
        });

    } catch (error) {

        res.status(500).json({
            error:error.message
        });

    }
};

//Controller para estudiantes

export const obtEstudiantes = async (req,res) => {

    try{

        const estudiantes=await obtTodoEstudiantes();

        res.status(200).json(estudiantes);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const obtEstudiantePorID = async (req,res) => {

    try{

        const estudiante=await obtEstudiante(req.params.id);

        if(!estudiante) return res.status(404).json({mensaje:"Estudiante no encontrado"});

        res.status(200).json(estudiante);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const insertaEstudiante = async (req,res)=>{

    try{

        await check("ci").notEmpty().run(req);
        await check("nombres").notEmpty().run(req);
        await check("apellidos").notEmpty().run(req);
        await check("fecha_nac").notEmpty().run(req);
        await check("sexo").isIn(["M","F"]).run(req);
        await check("email").isEmail().run(req);
        await check("username").notEmpty().run(req);
        await check("password").isLength({min:6}).run(req);
        await check("ru").notEmpty().run(req);
        await check("id_plan").isInt().run(req);
        await check("anio_ingreso").isInt().run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()) return res.status(400).json({mensaje:errores.array()});

        const estudiante=await insertaEst(req.body);

        res.status(201).json(estudiante);

    }catch(error){

        res.status(500).json({error:error.message});
    }
};

export const actualizaEstudiante = async (req,res) => {

    try{

        const estudiante=await obtEstudiante(req.params.id);

        if(!estudiante) return res.status(404).json({mensaje:"Estudiante no encontrado"});

        await check("ru").notEmpty().run(req);
        await check("id_plan").isInt().run(req);
        await check("anio_ingreso").isInt().run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()) return res.status(400).json({mensaje:errores.array()});

        const estudianteAct=await actualizaEst(req.params.id,req.body);

        res.status(200).json(estudianteAct);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const eliminaEstudiante = async (req,res) => {

    try{

        const estudiante=await obtEstudiante(req.params.id);

        if(!estudiante) return res.status(404).json({mensaje:"Estudiante no encontrado"});

        await eliminaEst(req.params.id);

        res.status(200).json({mensaje:"Estudiante eliminado correctamente"});

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

//Controller para docentes
export const obtDocentes=async(req,res)=>{

    try{

        const docentes=await obtTodoDocentes();

        res.status(200).json(docentes);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const obtDocentePorID=async(req,res)=>{

    try{

        const docente=await obtDocente(req.params.id);

        if(!docente) return res.status(404).json({mensaje:"Docente no encontrado"});

        res.status(200).json(docente);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const actualizaDocente=async(req,res)=>{

    try{

        const docente=await obtDocente(req.params.id);

        if(!docente) return res.status(404).json({mensaje:"Docente no encontrado"});

        const docenteAct=await actualizaDoc(req.params.id,req.body);

        res.status(200).json(docenteAct);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const eliminaDocente=async(req,res)=>{

    try{

        const docente=await obtDocente(req.params.id);

        if(!docente) return res.status(404).json({mensaje:"Docente no encontrado"});

        await eliminaDoc(req.params.id);

        res.status(200).json({mensaje:"Docente eliminado correctamente"});

    }catch(error){

        res.status(500).json({error:error.message});

    }

};
export const insertaDocente=async(req,res)=>{

    try{

        await check("ci").notEmpty().run(req);
        await check("username").notEmpty().run(req);
        await check("password").isLength({min:6}).run(req);
        await check("registro_docente").notEmpty().run(req);
        await check("grado_academico").notEmpty().run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()) return res.status(400).json({mensaje:errores.array()});

        const docente=await insertaDoc(req.body);

        res.status(201).json(docente);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

//Controller para administrativos
export const obtAdministrativos=async(req,res)=>{

    try{

        const administrativos=await obtTodoAdministrativos();

        res.status(200).json(administrativos);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const obtAdministrativoPorID=async(req,res)=>{

    try{

        const administrativo=await obtAdministrativo(req.params.id);

        if(!administrativo) return res.status(404).json({mensaje:"Administrativo no encontrado"});

        res.status(200).json(administrativo);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const actualizaAdministrativo=async(req,res)=>{

    try{

        const administrativo=await obtAdministrativo(req.params.id);

        if(!administrativo) return res.status(404).json({mensaje:"Administrativo no encontrado"});

        const administrativoAct=await actualizaAdm(req.params.id,req.body);

        res.status(200).json(administrativoAct);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const eliminaAdministrativo=async(req,res)=>{

    try{

        const administrativo=await obtAdministrativo(req.params.id);

        if(!administrativo) return res.status(404).json({mensaje:"Administrativo no encontrado"});

        await eliminaAdm(req.params.id);

        res.status(200).json({mensaje:"Administrativo eliminado correctamente"});

    }catch(error){

        res.status(500).json({error:error.message});

    }

};
export const insertaAdministrativo=async(req,res)=>{

    try{

        await check("ci").notEmpty().run(req);
        await check("username").notEmpty().run(req);
        await check("password").isLength({min:6}).run(req);
        await check("item").notEmpty().run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()) return res.status(400).json({mensaje:errores.array()});

        const administrativo=await insertaAdm(req.body);

        res.status(201).json(administrativo);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};


//Controller para directores
export const obtDirectores=async(req,res)=>{

    try{

        const directores=await obtTodoDirectores();

        res.status(200).json(directores);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const obtDirectorPorID=async(req,res)=>{

    try{

        const director=await obtDirector(req.params.id);

        if(!director) return res.status(404).json({mensaje:"Director no encontrado"});

        res.status(200).json(director);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const actualizaDirectorCarrera=async(req,res)=>{

    try{

        const director=await obtDirector(req.params.id);

        if(!director) return res.status(404).json({mensaje:"Director no encontrado"});

        const directorAct=await actualizaDirector(req.params.id,req.body);

        res.status(200).json(directorAct);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const eliminaDirectorCarrera=async(req,res)=>{

    try{

        const director=await obtDirector(req.params.id);

        if(!director) return res.status(404).json({mensaje:"Director no encontrado"});

        await eliminaDirector(req.params.id);

        res.status(200).json({mensaje:"Director eliminado correctamente"});

    }catch(error){

        res.status(500).json({error:error.message});

    }

};
export const insertaDirector=async(req,res)=>{

    try{

        await check("ci").notEmpty().run(req);
        await check("username").notEmpty().run(req);
        await check("password").isLength({min:6}).run(req);
        await check("registro_docente").notEmpty().run(req);
        await check("grado_academico").notEmpty().run(req);
        await check("id_carrera").isInt().run(req);
        await check("gestion").notEmpty().run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()) return res.status(400).json({mensaje:errores.array()});

        const director=await insertaDirec(req.body);

        res.status(201).json(director);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};