const mysql = require('mysql2/promise');

async function check() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'sistemaacademico'
    });

    const [gestiones] = await pool.query("SELECT * FROM gestion WHERE estado = 'Activa'");
    console.log("GESTIONES ACTIVAS:", gestiones);

    const [totales] = await pool.query("SELECT id_gestion, COUNT(*) as cantidad FROM paralelo GROUP BY id_gestion");
    console.log("PARALELOS POR GESTION:", totales);

    const [muestra] = await pool.query("SELECT id_materia, id_paralelo, id_gestion FROM paralelo LIMIT 10");
    console.log("MUESTRA PARALELOS:", muestra);

    await pool.end();
}

check().catch(console.error);
