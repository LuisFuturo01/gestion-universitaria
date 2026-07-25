import { useMemo } from "react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts";
import { useData } from "../../context/DataContext";
import { SectionHeader, StatCard } from "../../components/Common/Common";
import {
  generarReporteEstudiantesPorCarrera,
  generarReporteCargaDocente,
  generarReporteRendimiento,
} from "../../utils/pdfReports";

const COLORS = ["#1f9d55", "#e64545", "#f4b740"];

export default function ReportsPage() {
  const data = useData();
  const gestionActiva = data.getGestionActiva();

  const estudiantesPorCarrera = useMemo(() => {
    return data.carreras.map((c) => {
      const planesCarrera = data.planes.filter((p) => p.id_carrera === c.id_carrera).map((p) => p.id_plan);
      const estudiantesCarrera = data.estudiantes.filter((e) => planesCarrera.includes(e.id_plan));
      return { nombre: c.nombre, cantidad: estudiantesCarrera.length, carrera: c, estudiantesCarrera };
    });
  }, [data]);

  const cargaDocente = useMemo(() => {
    return data.docentes.map((d) => {
      const persona = data.getPersona(d.id_persona);
      const paralelosDocente = data.paralelos.filter((p) => p.id_docente === d.id_persona && p.id_gestion === gestionActiva?.id_gestion);
      const totalEstudiantes = paralelosDocente.reduce((acc, p) => acc + p.cupo_actual, 0);
      return { nombre: `${persona.nombres} ${persona.apellidos}`, grado: d.grado_academico, paralelos: paralelosDocente.length, totalEstudiantes };
    });
  }, [data, gestionActiva]);

  const rendimiento = useMemo(() => {
    return data.materias
      .map((m) => {
        const registros = data.detalle.filter((d) => d.id_materia === m.id_materia);
        const aprobados = registros.filter((r) => r.estado === "Aprobado").length;
        const reprobados = registros.filter((r) => r.estado === "Reprobado").length;
        const cursando = registros.filter((r) => r.estado === "Inscrito").length;
        const total = aprobados + reprobados;
        const porcentaje = total > 0 ? Math.round((aprobados / total) * 100) : 0;
        return { materia: `${m.sigla}`, aprobados, reprobados, cursando, porcentaje };
      })
      .filter((r) => r.aprobados + r.reprobados + r.cursando > 0);
  }, [data]);

  const totalesGenerales = useMemo(() => {
    const aprobados = data.detalle.filter((d) => d.estado === "Aprobado").length;
    const reprobados = data.detalle.filter((d) => d.estado === "Reprobado").length;
    const cursando = data.detalle.filter((d) => d.estado === "Inscrito").length;
    return [
      { name: "Aprobados", value: aprobados },
      { name: "Reprobados", value: reprobados },
      { name: "Cursando", value: cursando },
    ];
  }, [data]);

  return (
    <div>
      <SectionHeader title="Reportes y Estadísticas" subtitle="Panel analítico para la toma de decisiones" />

      <div className="stats-grid">
        <StatCard icon="👥" label="Estudiantes totales" value={data.estudiantes.length} tone="blue" />
        <StatCard icon="🎓" label="Docentes activos" value={data.docentes.length} tone="green" />
        <StatCard icon="📚" label="Paralelos gestión activa" value={data.paralelos.filter((p) => p.id_gestion === gestionActiva?.id_gestion).length} tone="purple" />
        <StatCard icon="✅" label="% aprobación histórico" value={`${rendimiento.length ? Math.round(rendimiento.reduce((a, r) => a + r.porcentaje, 0) / rendimiento.length) : 0}%`} tone="yellow" />
      </div>

      <div className="report-grid">
        <div className="page-card">
          <SectionHeader
            title="Estudiantes inscritos por carrera"
            actions={<button className="link-button" onClick={() => {
              const c = estudiantesPorCarrera[0];
              const filas = c.estudiantesCarrera.map((e) => {
                const persona = data.getPersona(e.id_persona);
                const hist = data.getHistorialEstudiante(e.id_persona);
                const cursando = hist.filter((h) => h.estado === "Inscrito").length;
                const aprobadas = hist.filter((h) => h.estado === "Aprobado");
                const promedio = aprobadas.length ? Math.round(aprobadas.reduce((a, h) => a + h.nota_final, 0) / aprobadas.length) : 0;
                return { ru: e.ru, nombre: `${persona.nombres} ${persona.apellidos}`, anio_ingreso: e.anio_ingreso, cursando, promedio };
              });
              generarReporteEstudiantesPorCarrera({ carreraNombre: c.nombre, filas });
            }}>⬇ PDF</button>}
          />
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={estudiantesPorCarrera}>
              <XAxis dataKey="nombre" tick={{ fontSize: 11 }} />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Bar dataKey="cantidad" fill="#1a5fb4" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="page-card">
          <SectionHeader
            title="Estado general de inscripciones"
            actions={<button className="link-button" onClick={() => generarReporteCargaDocente({ filas: cargaDocente })}>⬇ PDF carga docente</button>}
          />
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie data={totalesGenerales} dataKey="value" nameKey="name" outerRadius={85} label>
                {totalesGenerales.map((entry, i) => (
                  <Cell key={entry.name} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Legend />
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="page-card" style={{ marginTop: 20 }}>
        <SectionHeader
          title="Rendimiento académico por materia"
          actions={<button className="link-button" onClick={() => generarReporteRendimiento({ filas: rendimiento })}>⬇ PDF rendimiento</button>}
        />
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={rendimiento}>
            <XAxis dataKey="materia" tick={{ fontSize: 11 }} />
            <YAxis allowDecimals={false} />
            <Tooltip />
            <Legend />
            <Bar dataKey="aprobados" fill="#1f9d55" name="Aprobados" />
            <Bar dataKey="reprobados" fill="#e64545" name="Reprobados" />
            <Bar dataKey="cursando" fill="#f4b740" name="Cursando" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="page-card" style={{ marginTop: 20 }}>
        <SectionHeader title="Carga horaria docente — gestión activa" />
        <table className="table">
          <thead><tr><th>Docente</th><th>Grado</th><th>Paralelos</th><th>Estudiantes a cargo</th></tr></thead>
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
  );
}
