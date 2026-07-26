import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { StatCard, SectionHeader, Badge } from "../../components/Common/Common";

export default function DashboardPage() {
  const { session } = useAuth();
  const data = useData();
  const rol = session?.rolActivo || "ADMIN";
  const gestionActiva = data.getGestionActiva();

  // 1. VISTA ADMINISTRADOR (Soporte y Control Técnico)
  if (rol === "ADMIN" || rol === "ADMINISTRADOR") {
    const usuariosActivos = (data.usuarios || []).filter((u) => u.estado === "A" || u.activo !== false).length;
    const totalEstudiantes = (data.estudiantes || []).length;
    const totalDocentes = (data.docentes || []).length;
    const totalParalelosActivos = (data.paralelos || []).filter(
      (p) => Number(p.id_gestion) === Number(gestionActiva?.id_gestion)
    ).length;
    const totalParalelos = totalParalelosActivos > 0 ? totalParalelosActivos : (data.paralelos || []).length;

    return (
      <div>
        <SectionHeader title="Panel de Administración General" subtitle="Monitoreo de usuarios, oferta académica y control de gestión" />
        
        <div className="stats-grid">
          <StatCard icon="🔑" label="Usuarios del sistema" value={usuariosActivos} tone="blue" />
          <StatCard icon="👥" label="Estudiantes matriculados" value={totalEstudiantes} tone="purple" />
          <StatCard icon="👨‍🏫" label="Docentes registrados" value={totalDocentes} tone="yellow" />
          <StatCard icon="📚" label="Paralelos aperturados" value={totalParalelos} tone="green" />
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Estado del Periodo Académico" />
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: 16 }}>
            <div style={{ padding: 18, background: "#f8fafc", borderRadius: 10, border: "1px solid #e2e8f0" }}>
              <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#64748b", textTransform: "uppercase" }}>
                Gestión Activa en Curso
              </span>
              <h3 style={{ margin: "6px 0 4px", color: "#0f172a" }}>
                {gestionActiva ? gestionActiva.periodo : "Sin gestión activa"}
              </h3>
              <Badge style={{ background: gestionActiva?.estado === "Activa" ? "#10b981" : "#ef4444", color: "#fff" }}>
                {gestionActiva?.estado || "Inactiva"}
              </Badge>
            </div>

            <div style={{ padding: 18, background: "#f8fafc", borderRadius: 10, border: "1px solid #e2e8f0" }}>
              <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#64748b", textTransform: "uppercase" }}>
                Oferta de Paralelos
              </span>
              <h3 style={{ margin: "6px 0 4px", color: "#0f172a" }}>{totalParalelos} paralelos</h3>
              <span style={{ fontSize: "0.85rem", color: "#64748b" }}>Grupos aperturados en la gestión actual</span>
            </div>
          </div>
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Accesos Rápidos de Administración" />
          <ul className="quick-links">
            <li><a href="/actores">Gestión de Usuarios (Estudiantes, Docentes, Administrativos)</a></li>
            <li><a href="/oferta">Oferta Académica y Asignación de Paralelos</a></li>
            <li><a href="/cierre-gestion">Apertura y Cierre de Gestión Académica</a></li>
          </ul>
        </div>
      </div>
    );
  }

  // 2. VISTA DIRECTOR DE CARRERA (Gestión Académica)
  if (rol === "DIRECTOR") {
    const carrera = data.carreras[0] || { nombre: "Ingeniería de Sistemas", id_carrera: 1 };
    const estudiantesCarrera = data.estudiantes.length;

    return (
      <div>
        <SectionHeader title={`Dirección de Carrera — ${carrera.nombre}`} subtitle={`Gestión Activa: ${gestionActiva?.periodo || "I/2026"}`} />
        <div className="stats-grid">
          <StatCard icon="👥" label="Estudiantes inscritos en la carrera" value={estudiantesCarrera} tone="blue" />
          <StatCard icon="📅" label="Estado de gestión" value={gestionActiva?.estado || "Activa"} tone="purple" />
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Accesos Rápidos de Dirección" />
          <ul className="quick-links">
            <li><a href="/reportes">Reportes y Métricas Académicas de la Carrera</a></li>
            <li><a href="/cierre-gestion">Apertura y Cierre de Gestión Académica</a></li>
            <li><a href="/oferta">Oferta Académica General</a></li>
          </ul>
        </div>
      </div>
    );
  }

  // 3. VISTA DOCENTE (Materias Asignadas y Alertas)
  if (rol === "DOCENTE") {
    const misParalelos = data.paralelos.filter(
      (p) => Number(p.id_docente) === Number(session?.id_persona) && Number(p.id_gestion) === Number(gestionActiva?.id_gestion)
    );

    return (
      <div>
        <SectionHeader title={`Panel Docente — ${session?.nombreCompleto}`} subtitle={`Gestión Activa: ${gestionActiva?.periodo || "I/2026"}`} />
        <div className="stats-grid">
          <StatCard icon="📚" label="Materias / Paralelos a mi cargo" value={misParalelos.length} tone="blue" />
          <StatCard icon="🔔" label="Notas pendientes de publicar" value={misParalelos.length > 0 ? "Borrador activo" : "0"} tone="yellow" />
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Mis asignaturas dictadas esta gestión" />
          {misParalelos.length === 0 ? (
            <p className="empty-state">No tiene paralelos asignados en la gestión activa. Acceda a 'Oferta Académica' para tomar materias.</p>
          ) : (
            <table className="table">
              <thead>
                <tr><th>Materia</th><th>Paralelo</th><th>Estudiantes</th><th>Acción</th></tr>
              </thead>
              <tbody>
                {misParalelos.map((p) => {
                  const materia = data.getMateria(p.id_materia);
                  return (
                    <tr key={`${p.id_materia}-${p.id_paralelo}`}>
                      <td><strong>{materia?.sigla}</strong> — {materia?.nombre}</td>
                      <td>Paralelo {p.nombre}</td>
                      <td>{p.cupo_actual} inscritos</td>
                      <td><a href="/notas" className="link-button">Ir a Planilla ➔</a></td>
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

  // 4. VISTA ESTUDIANTE (Resumen Personal)
  const idEstudiante = session?.id_persona;
  const historial = data.getHistorialEstudiante(idEstudiante);
  const activas = historial.filter((h) => h.estado === "Inscrito");
  const aprobadas = historial.filter((h) => h.estado === "Aprobado");
  const promedioGeneral = aprobadas.length > 0
    ? Math.round((aprobadas.reduce((acc, h) => acc + (h.nota_final || 0), 0) / aprobadas.length) * 100) / 100
    : 0;

  return (
    <div>
      <SectionHeader title={`Hola, ${session?.nombreCompleto}`} subtitle={`RU: RU-${idEstudiante} · Promedio Ponderado: ${promedioGeneral} pts`} />
      <div className="stats-grid">
        <StatCard icon="📖" label="Materias cursando actualmente" value={activas.length} tone="blue" />
        <StatCard icon="✅" label="Materias aprobadas" value={aprobadas.length} tone="green" />
        <StatCard icon="⭐" label="Promedio acumulado" value={`${promedioGeneral} pts`} tone="purple" />
      </div>

      <div className="page-card" style={{ marginTop: 20 }}>
        <SectionHeader title="Mis asignaturas cursadas en el periodo actual" />
        {activas.length === 0 ? (
          <p className="empty-state">No se encuentra inscrito a ninguna materia en este periodo. Acceda a la Ventanilla de Inscripciones.</p>
        ) : (
          activas.map((h) => (
            <div key={h.id_detalle} className="activity-row">
              <span><strong>{h.materia?.sigla}</strong> — {h.materia?.nombre}</span>
              <span className="activity-meta">{h.gestion?.periodo || 'I/2026'}</span>
              <Badge>{h.estado}</Badge>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
