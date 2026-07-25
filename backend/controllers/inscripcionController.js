import{

realizarInscripcion,
obtenerInscripciones,
obtenerInscripcion,
retirarInscripcion,
AsignarNota

}from"../models/inscripcionModel.js";

import{

check,
validationResult

}from"express-validator";

export const obtInscripciones=async(req,res)=>{

try{

const datos=await obtenerInscripciones();

res.status(200).json(datos);

}

catch(error){

res.status(500).json({

error:error.message

});

}

};

export const obtInscripcionPorID=async(req,res)=>{

try{

const dato=await obtenerInscripcion(req.params.id);

if(!dato){

return res.status(404).json({

mensaje:"Inscripción no encontrada."

});

}

res.status(200).json(dato);

}

catch(error){

res.status(500).json({

error:error.message

});

}

};

export const insertaInscripcion=async(req,res)=>{

try{

await check("id_estudiante")
.notEmpty()
.isNumeric()
.run(req);

await check("id_gestion")
.notEmpty()
.isNumeric()
.run(req);

await check("id_plan")
.notEmpty()
.isNumeric()
.run(req);

await check("id_materia")
.notEmpty()
.isNumeric()
.run(req);

await check("id_paralelo")
.notEmpty()
.isNumeric()
.run(req);

const errores=validationResult(req);

if(!errores.isEmpty()){

return res.status(400).json({

mensaje:errores.array()

});

}

const respuesta=await realizarInscripcion(req.body);

res.status(201).json(respuesta);

}

catch(error){

res.status(500).json({

error:error.message

});

}
};

export const eliminaInscripcion=async(req,res)=>{

try{

const respuesta=await retirarInscripcion(req.params.id);

res.status(200).json(respuesta);

}

catch(error){

res.status(500).json({

error:error.message

});

}

};

export const AsignarN= async (req, res) => {
    try {
        const { id, nota_final } = req.body;
        const respuesta = await AsignarNota(id, nota_final);
        res.status(200).json(respuesta);
    } catch (error) {
        res.status(500).json({
            error: error.message
        });
    }
};