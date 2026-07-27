import { useMemo } from "react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { SectionHeader, StatCard } from "../../components/Common/Common";
import {
  generarReporteEstudiantesPorCarrera,
  generarReporteCargaDocente,
  generarReporteRendimiento,
  generarReporteGeneralEstadisticasPDF,
} from "../../utils/pdfReports";

const COLORS = ["#1f9d55", "#e64545", "#f4b740"];

export default function ReportsPage() {
  const { session } = useAuth();
  const data = useData();
  const esAdmin = session?.rolActivo === "ADMIN";
  const carrera = data.getCarrera(data.idCarreraActiva);
  const gestionActiva = data.getGestionActiva();

  const cargaDocente = useMemo(() => {
    return (data.docentes || []).map((d) => {
      const persona = data.getPersona(d.id_persona) || { nombres: "Docente", apellidos: `#${d.id_persona}` };
      const paralelosDocente = (data.paralelos || []).filter(
        (p) => Number(p.id_docente) === Number(d.id_persona) && (!gestionActiva || Number(p.id_gestion) === Number(gestionActiva.id_gestion))
      );
      
      const totalEstudiantes = paralelosDocente.reduce((acc, p) => {
        const inscritos = (data.detalle || []).filter(
          (det) => Number(det.id_materia) === Number(p.id_materia) && Number(det.id_paralelo) === Number(p.id_paralelo) && det.estado !== "Retirado" && det.estado !== "Abandono"
        ).length;
        return acc + (inscritos || p.cupo_actual || 0);
      }, 0);

      return {
        nombre: `${persona.nombres || ''} ${persona.apellidos || ''}`.trim() || `Docente ${d.id_persona}`,
        grado: d.grado_academico || "Lic.",
        paralelos: paralelosDocente.length,
        totalEstudiantes
      };
    });
  }, [data, gestionActiva]);

  const rendimiento = useMemo(() => {
    return (data.materias || []).map((m) => {
      const registros = (data.detalle || []).filter((d) => Number(d.id_materia) === Number(m.id_materia) && d.estado !== "Retirado" && d.estado !== "Abandono");
      let aprobados = 0;
      let reprobados = 0;
      let cursando = 0;

      registros.forEach((r) => {
        const nota = data.calcularNotaFinal(r.id_materia, r.id_paralelo, r.id_detalle);
        if (nota >= 51) {
          aprobados++;
        } else if (nota > 0) {
          reprobados++;
        } else {
          cursando++;
        }
      });

      const evaluados = aprobados + reprobados;
      const porcentaje = evaluados > 0 ? Math.round((aprobados / evaluados) * 100) : (aprobados > 0 ? 100 : 0);

      return {
        materia: m.sigla || `MAT-${m.id_materia}`,
        nombreCompleto: m.nombre,
        aprobados,
        reprobados,
        cursando,
        porcentaje
      };
    });
  }, [data]);

  const distribucionUsuarios = useMemo(() => {
    const totalEst = (data.estudiantes || []).length || (data.personas || []).length || 1;
    const totalDoc = (data.docentes || []).length || 1;
    return [
      { name: "Administradores", value: 1 },
      { name: "Directores", value: 1 },
      { name: "Docentes", value: totalDoc },
      { name: "Estudiantes", value: totalEst },
    ];
  }, [data]);

  const handleExportarPDFGeneral = () => {
    generarReporteGeneralEstadisticasPDF({
      carreraNombre: carrera.nombre,
      periodoActivo: gestionActiva?.periodo || "I/2026",
      docentesCount: data.docentes.length,
      estudiantesCount: data.estudiantes.length,
      rendimiento,
      cargaDocente,
    });
  };

  return (
    <div>
      <SectionHeader
        title={`Reportes e Indicadores — ${carrera.nombre}`}
        subtitle={
          esAdmin
            ? `Panel de métricas técnicas y usuarios en el ámbito de ${carrera.nombre}`
            : `Métricas académicas, rendimiento por mención y carga docente en ${carrera.nombre}`
        }
        actions={
          <button
            className="button primary"
            onClick={handleExportarPDFGeneral}
            style={{ display: "flex", alignItems: "center", gap: 8, fontWeight: 700 }}
          >
            <span>📄</span> Exportar Información en PDF
          </button>
        }
      />

      <div className="stats-grid">
        <StatCard icon="🏢" label="Carrera Activa" value={carrera.nombre} tone="blue" />
        <StatCard icon="👥" label="Estudiantes Carrera" value={data.estudiantes.length} tone="green" />
        <StatCard icon="🎓" label="Docentes Activos" value={data.docentes.length} tone="purple" />
        <StatCard icon="✅" label="% Aprobación Histórico" value="88%" tone="yellow" />
      </div>

      {esAdmin ? (
        // METRICAS DE AMBITO CARRERA (ADMIN)
        <div>
          <div className="report-grid">
            <div className="page-card">
              <SectionHeader title="Distribución de Usuarios por Rol" />
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={distribucionUsuarios}>
                  <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="value" fill="#1a5fb4" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="page-card">
              <SectionHeader title="Carga Horaria Docente en la Carrera" />
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={cargaDocente}>
                  <XAxis dataKey="nombre" tick={{ fontSize: 10 }} />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="totalEstudiantes" fill="#1f9d55" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      ) : (
        // METRICAS ACADEMICAS DE CARRERA (DIRECTOR)
        <div>
          <div className="page-card" style={{ marginTop: 20 }}>
            <SectionHeader
              title={`Rendimiento Académico por Asignatura (${carrera.nombre})`}
              actions={<button className="link-button" onClick={() => generarReporteRendimiento({ filas: rendimiento })}>⬇ Exportar PDF Rendimiento</button>}
            />
            <div style={{ width: "100%", overflowX: "auto", overflowY: "hidden", paddingBottom: 10 }}>
              <div style={{ minWidth: Math.max(800, rendimiento.length * 45), height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={rendimiento} margin={{ top: 10, right: 20, left: 10, bottom: 25 }}>
                    <XAxis dataKey="materia" tick={{ fontSize: 10 }} interval={0} angle={-35} textAnchor="end" />
                    <YAxis allowDecimals={false} />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="aprobados" fill="#1f9d55" name="Aprobados" />
                    <Bar dataKey="reprobados" fill="#e64545" name="Reprobados" />
                    <Bar dataKey="cursando" fill="#f4b740" name="Cursando" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          <div className="page-card" style={{ marginTop: 20 }}>
            <SectionHeader
              title={`Carga Horaria Docente — ${carrera.nombre}`}
              actions={<button className="link-button" onClick={() => generarReporteCargaDocente({ filas: cargaDocente })}>⬇ Exportar PDF Carga Docente</button>}
            />
            <table className="table">
              <thead><tr><th>Docente</th><th>Grado Académico</th><th>Paralelos Asignados</th><th>Estudiantes a Cargo</th></tr></thead>
              <tbody>
                {cargaDocente.map((d) => (
                  <tr key={d.nombre}>
                    <td>{d.nombre}</td>
                    <td>{d.grado}</td>
                    <td>{d.paralelos}</td>
                    <td>{d.totalEstudiantes}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
