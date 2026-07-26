import { pool } from './config/db.js';

async function main() {
    try {
        const [gestiones] = await pool.query("SELECT * FROM gestion WHERE estado = 'Activa'");
        console.log("=== GESTIONES ACTIVAS ===", gestiones);

        const [totales] = await pool.query("SELECT id_gestion, COUNT(*) as cantidad FROM paralelo GROUP BY id_gestion");
        console.log("=== PARALELOS POR GESTION ===", totales);

        const [paralelos] = await pool.query("SELECT id_materia, id_paralelo, nombre, id_gestion FROM paralelo LIMIT 10");
        console.log("=== MUESTRA DE PARALELOS ===", paralelos);

    } catch (e) {
        console.error("Error DB:", e.message);
    } finally {
        process.exit(0);
    }
}

main();
