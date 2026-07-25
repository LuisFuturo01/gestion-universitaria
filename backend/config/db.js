import mysql from 'mysql2/promise'; // Usamos la versión con Promesas

export const pool = mysql.createPool({
host: 'localhost',
user: 'root',
password: '',
database: 'sistemaacademico'
})
