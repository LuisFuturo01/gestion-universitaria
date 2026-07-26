import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { StatCard, SectionHeader, Badge } from "../../components/Common/Common";

export default function DashboardPage() {
  const { session } = useAuth();
  const data = useData();
  const rol = session?.rolActivo || "ADMIN";
  const gestionActiva = data.getGestionActiva();

  // 1. VISTA ADMINISTRADOR (Soporte y Control Técnico)
  if (rol === "ADMIN") {
    const usuariosActivos = data.usuarios.filter((u) => u.estado === "A" || u.activo !== false).length;
    const totalParalelos = data.paralelos.length;
    const registrosAuditoria = data.auditoria || [];

    return (
      <div>
        <SectionHeader title={`Panel de Administración General`} subtitle="Monitoreo de infraestructura, cuentas y estado de conexión" />
        <div className="stats-grid">
          <StatCard icon="🟢" label="Salud del sistema" value="100% Operativo" tone="green" />
          <StatCard icon="🔑" label="Usuarios activos" value={usuariosActivos} tone="blue" />
          <StatCard icon="📚" label="Paralelos registrados" value={totalParalelos} tone="purple" />
          <StatCard icon="📋" label="Registros de auditoría" value={registrosAuditoria.length} tone="yellow" />
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Auditoría del sistema (tabla auditoria — MySQL)" />
          {registrosAuditoria.length === 0 ? (
            <p className="empty-state">No hay registros de auditoría en la base de datos.</p>
          ) : (
            <table className="table">
              <thead><tr><th>Usuario</th><th>Acción</th><th>Fecha</th><th>Hora</th></tr></thead>
              <tbody>
                {registrosAuditoria.slice(0, 20).map((a, i) => (
                  <tr key={a.id_auditoria || i}>
                    <td><strong>{a.username || `ID: ${a.id_usuario}`}</strong></td>
                    <td>{a.accion}</td>
                    <td>{a.fecha ? new Date(a.fecha).toLocaleDateString() : "—"}</td>
                    <td>{a.hora || "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    );
  }

  // 2. VISTA DIRECTOR DE CARRERA (Gestión Académica)
  if (rol === "DIRECTOR") {
    const carrera = data.carreras[0] || { nombre: "Ingeniería de Sistemas", id_carrera: 1 };
    const estudiantesCarrera = data.estudiantes.length;
    const avanceDocentes = "85%";

    return (
      <div>
        <SectionHeader title={`Dirección de Carrera — ${carrera.nombre}`} subtitle={`Gestión Activa: ${gestionActiva?.periodo || "I/2026"}`} />
        <div className="stats-grid">
          <StatCard icon="👥" label="Estudiantes inscritos en la carrera" value={estudiantesCarrera} tone="blue" />
          <StatCard icon="📊" label="Avance de notas docentes" value={avanceDocentes} tone="green" />
          <StatCard icon="📅" label="Estado de gestión" value={gestionActiva?.estado || "Activa"} tone="purple" />
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Accesos Rápidos de Dirección" />
          <ul className="quick-links">
            <li><a href="/reportes">Reportes y Métricas Académicas de la Carrera</a></li>
            <li><a href="/cierre-gestion">Verificación de Actas y Cierre de Gestión</a></li>
            <li><a href="/historial">Auditoría de Historial Académico de Estudiantes</a></li>
          </ul>
        </div>
      </div>
    );
  }

  // 3. VISTA DOCENTE (Materias Asignadas y Alertas)
  if (rol === "DOCENTE") {
    const misParalelos = data.paralelos.filter(
      (p) => p.id_docente === session?.id_persona && p.id_gestion === gestionActiva?.id_gestion
    );

    return (
      <div>
        <SectionHeader title={`Panel Docente — ${session?.nombreCompleto}`} subtitle={`Gestión Activa: ${gestionActiva?.periodo || "I/2026"}`} />
        <div className="stats-grid">
          <StatCard icon="📚" label="Materias / Paralelos a mi cargo" value={misParalelos.length} tone="blue" />
          <StatCard icon="🔔" label="Notas pendientes de publicar" value={misParalelos.length > 0 ? "1 pendiente" : "0"} tone="yellow" />
        </div>

        <div className="page-card" style={{ marginTop: 20 }}>
          <SectionHeader title="Mis asignaturas dictadas esta gestión" />
          {misParalelos.length === 0 ? (
            <p className="empty-state">No tiene paralelos asignados en la gestión activa.</p>
          ) : (
            <table className="table">
              <thead>
                <tr><th>Materia</th><th>Paralelo</th><th>Estudiantes</th><th>Estado Planilla</th><th>Acción</th></tr>
              </thead>
              <tbody>
                {misParalelos.map((p) => {
                  const materia = data.getMateria(p.id_materia);
                  return (
                    <tr key={`${p.id_materia}-${p.id_paralelo}`}>
                      <td><strong>{materia?.sigla}</strong> — {materia?.nombre}</td>
                      <td>Paralelo {p.nombre}</td>
                      <td>{p.cupo_actual} inscritos</td>
                      <td><Badge>Borrador en curso</Badge></td>
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
    ? Math.round((aprobadas.reduce((acc, h) => acc + h.nota_final, 0) / aprobadas.length) * 100) / 100
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
