import {
    obtTodo,
    obtAsignacion,
    inserta,
    actualiza,
    elimina
} from "../models/dirigeModel.js";


export const obtAsignaciones=async(req,res)=>{

    try{

        const resultado=await obtTodo();

        res.status(200).json(resultado);

    }catch(error){

        res.status(500).json({
            error:error.message
        });

    }

};



export const obtAsignacionID=async(req,res)=>{

    try{

        const resultado=await obtAsignacion(
            req.params.id_persona,
            req.params.id_carrera
        );


        if(!resultado)
            return res.status(404).json({
                error:"Asignación no encontrada"
            });


        res.status(200).json(resultado);


    }catch(error){

        res.status(500).json({
            error:error.message
        });

    }

};



export const insertaAsignacion=async(req,res)=>{

    try{

        const resultado=await inserta(req.body);

        res.status(201).json(resultado);


    }catch(error){

        res.status(500).json({
            error:error.message
        });

    }

};



export const actualizaAsignacion=async(req,res)=>{

    try{

        const resultado=await actualiza(
            req.params.id_persona,
            req.params.id_carrera,
            req.body
        );


        res.status(200).json(resultado);


    }catch(error){

        res.status(500).json({
            error:error.message
        });

    }

};



export const eliminaAsignacion=async(req,res)=>{

    try{

        await elimina(
            req.params.id_persona,
            req.params.id_carrera
        );


        res.status(200).json({
            mensaje:"Asignación eliminada correctamente"
        });


    }catch(error){

        res.status(500).json({
            error:error.message
        });

    }

};