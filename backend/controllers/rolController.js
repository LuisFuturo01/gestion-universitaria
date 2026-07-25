import{
    obtTodo,
    obtRol,
    inserta,
    actualiza,
    elimina
}from "../models/rolModel.js";

import {check,validationResult} from "express-validator";

export const obtRoles=async(req,res)=>{

    try{

        const roles=await obtTodo();

        res.status(200).json(roles);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const obtRolPorID=async(req,res)=>{

    try{

        const rol=await obtRol(req.params.id);

        if(!rol){

            return res.status(404).json({
                mensaje:"Rol no encontrado"
            });

        }

        res.status(200).json(rol);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const insertaRol=async(req,res)=>{

    try{

        await check("nombre")
        .notEmpty()
        .withMessage("El nombre es obligatorio")
        .run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()){

            return res.status(400).json({
                mensaje:errores.array()
            });

        }

        const rol=await inserta(req.body);

        res.status(201).json(rol);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const actualizaRol=async(req,res)=>{

    try{

        const rol=await obtRol(req.params.id);

        if(!rol){

            return res.status(404).json({
                mensaje:"Rol no encontrado"
            });

        }

        await check("nombre")
        .notEmpty()
        .withMessage("El nombre es obligatorio")
        .run(req);

        const errores=validationResult(req);

        if(!errores.isEmpty()){

            return res.status(400).json({
                mensaje:errores.array()
            });

        }

        const rolAct=await actualiza(req.params.id,req.body);

        res.status(200).json(rolAct);

    }catch(error){

        res.status(500).json({error:error.message});

    }

};

export const eliminaRol=async(req,res)=>{

    try{

        const rol=await obtRol(req.params.id);

        if(!rol){

            return res.status(404).json({
                mensaje:"Rol no encontrado"
            });

        }

        await elimina(req.params.id);

        res.status(200).json({
            mensaje:"Rol eliminado correctamente"
        });

    }catch(error){

        res.status(500).json({error:error.message});

    }

};