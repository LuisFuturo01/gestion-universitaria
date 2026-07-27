import mysql from 'mysql2/promise';

// Pool restringido para autenticación (usr_login)
export const authPool = mysql.createPool({
    host: 'localhost',
    user: 'usr_login',
    password: '123456',
    database: 'sistemaacademico'
});

// Pool para Administrador (usr_admin)
export const adminPool = mysql.createPool({
    host: 'localhost',
    user: 'usr_admin',
    password: '123456',
    database: 'sistemaacademico'
});

// Pool para Director de Carrera (usr_director)
export const directorPool = mysql.createPool({
    host: 'localhost',
    user: 'usr_director',
    password: '123456',
    database: 'sistemaacademico'
});

// Pool para Docente (usr_docente)
export const docentePool = mysql.createPool({
    host: 'localhost',
    user: 'usr_docente',
    password: '123456',
    database: 'sistemaacademico'
});

// Pool para Estudiante (usr_estudiante)
export const estudiantePool = mysql.createPool({
    host: 'localhost',
    user: 'usr_estudiante',
    password: '123456',
    database: 'sistemaacademico'
});

// Pool por defecto del sistema (redireccionado a usr_admin)
export const pool = adminPool;

export const getPoolByRole = (rol) => {
    const r = (rol || '').toUpperCase();
    if (r === 'ESTUDIANTE') return estudiantePool;
    if (r === 'DOCENTE') return docentePool;
    if (r === 'DIRECTOR') return directorPool;
    if (r === 'ADMINISTRADOR' || r === 'ADMIN') return adminPool;
    if (r === 'LOGIN') return authPool;
    return adminPool;
};
