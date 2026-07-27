import jwt from "jsonwebtoken";

export const verificarToken = (req, res, next) => {
    const token = req.headers.authorization;

    if (!token) {
        return next();
    }

    try {
        const tokenLimpio = token.replace("Bearer ", "");
        const usuario = jwt.verify(
            tokenLimpio,
            "SISTEMA_ACADEMICO"
        );
        req.usuario = usuario;
        next();
    } catch (error) {
        return next();
    }
};