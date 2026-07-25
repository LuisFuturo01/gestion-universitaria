import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { StatCard, SectionHeader, Badge } from "../../components/Common/Common";

export default function DashboardPage() {
  const { session } = useAuth();
  const data = useData();
  const rol = session.rolActivo;
  const gestionActiva = data.getGestionActiva();

  if (rol === "ADMIN") {
    const totalEstudiantes = data.estudiantes.length;
    const totalDocentes = data.docentes.length;
    const totalUsuarios = data.usuarios.length;
    const paralelosAbiertos = data.paralelos.filter((p) => p.id_gestion === gestionActiva?.id_gestion).length;
    return (
      <div>
        <SectionHeader title={`Bienvenido, ${session.nombreCompleto}`} subtitle="Panel de administración general del sistema" />
        <div className="stats-grid">
          <StatCard icon="👥" label="Estudiantes registrados" value={totalEstudiantes} tone="blue" />
          <StatCard icon="🎓" label="Docentes" value={totalDocentes} tone="green" />
          <StatCard icon="🔑" label="Usuarios del sistema" value={totalUsuarios} tone="purple" />
          <StatCard icon="📚" label={`Paralelos abiertos (${gestionActiva?.periodo || "—"})`} value={paralelosAbiertos} tone="yellow" />
        </div>
        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Accesos rápidos" />
          <ul className="quick-links">
            <li><a href="/usuarios">Gestión de Usuarios y Roles</a></li>
            <li><a href="/inscripcion">Ventanilla de Inscripción</a></li>
            <li><a href="/reportes">Reportes y Estadísticas</a></li>
            <li><a href="/cierre-gestion">Cierre de Gestión</a></li>
          </ul>
        </div>
      </div>
    );
  }

  if (rol === "DIRECTOR") {
    const carrera = data.carreras[0];
    const totalEstudiantesCarrera = data.estudiantes.filter((e) => {
      const plan = data.planes.find((p) => p.id_plan === e.id_plan);
      return plan?.id_carrera === carrera.id_carrera;
    }).length;
    return (
      <div>
        <SectionHeader title={`Bienvenido, ${session.nombreCompleto}`} subtitle={`Dirección de carrera — ${carrera.nombre}`} />
        <div className="stats-grid">
          <StatCard icon="👥" label="Estudiantes en la carrera" value={totalEstudiantesCarrera} tone="blue" />
          <StatCard icon="📅" label="Gestión activa" value={gestionActiva?.periodo || "—"} tone="green" />
          <StatCard icon="📊" label="Reportes disponibles" value="6" tone="purple" />
        </div>
        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Accesos rápidos" />
          <ul className="quick-links">
            <li><a href="/reportes">Reportes y Estadísticas</a></li>
            <li><a href="/historial">Historial Académico de estudiantes</a></li>
            <li><a href="/cierre-gestion">Cierre de Gestión</a></li>
          </ul>
        </div>
      </div>
    );
  }

  if (rol === "DOCENTE") {
    const misParalelos = data.paralelos.filter(
      (p) => p.id_docente === session.id_persona && p.id_gestion === gestionActiva?.id_gestion
    );
    return (
      <div>
        <SectionHeader title={`Bienvenido, ${session.nombreCompleto}`} subtitle="Panel docente" />
        <div className="stats-grid">
          <StatCard icon="📚" label="Paralelos a cargo" value={misParalelos.length} tone="blue" />
          <StatCard icon="📅" label="Gestión activa" value={gestionActiva?.periodo || "—"} tone="green" />
        </div>
        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title={`Mis paralelos — ${gestionActiva?.periodo || ""}`} />
          {misParalelos.length === 0 ? (
            <p className="empty-state">No tiene paralelos asignados en la gestión activa.</p>
          ) : (
            <table className="table">
              <thead>
                <tr><th>Materia</th><th>Paralelo</th><th>Inscritos</th><th>Cupo</th></tr>
              </thead>
              <tbody>
                {misParalelos.map((p) => {
                  const materia = data.getMateria(p.id_materia);
                  return (
                    <tr key={`${p.id_materia}-${p.id_paralelo}`}>
                      <td>{materia.sigla} — {materia.nombre}</td>
                      <td>{p.nombre}</td>
                      <td>{p.cupo_actual}</td>
                      <td>{p.cupo_maximo}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>
    );
  }

  // ESTUDIANTE
  const estudiante = session.estudiante;
  const historial = data.getHistorialEstudiante(estudiante.id_persona);
  const aprobadas = historial.filter((h) => h.estado === "Aprobado").length;
  const cursando = historial.filter((h) => h.estado === "Inscrito").length;
  const reprobadas = historial.filter((h) => h.estado === "Reprobado").length;

  return (
    <div>
      <SectionHeader title={`Hola, ${session.nombreCompleto}`} subtitle={`RU: ${estudiante.ru} — Ingreso: ${estudiante.anio_ingreso}`} />
      <div className="stats-grid">
        <StatCard icon="✅" label="Materias aprobadas" value={aprobadas} tone="green" />
        <StatCard icon="📖" label="Cursando actualmente" value={cursando} tone="yellow" />
        <StatCard icon="❌" label="Materias reprobadas" value={reprobadas} tone="red" />
      </div>
      <div className="page-card" style={{ marginTop: 20 }}>
        <SectionHeader title="Actividad reciente" />
        {historial.slice(-5).reverse().map((h) => (
          <div key={h.id_detalle} className="activity-row">
            <span>{h.materia.sigla} — {h.materia.nombre}</span>
            <span className="activity-meta">{h.gestion.periodo}</span>
            <Badge>{h.estado}</Badge>
          </div>
        ))}
      </div>
    </div>
  );
}
