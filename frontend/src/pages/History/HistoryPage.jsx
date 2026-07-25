import { useMemo, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { useData } from "../../context/DataContext";
import { SectionHeader, Badge, EmptyState } from "../../components/Common/Common";
import { generarHistorialPDF } from "../../utils/pdfReports";

export default function HistoryPage() {
  const { session } = useAuth();
  const data = useData();
  const esEstudiante = session?.rolActivo === "ESTUDIANTE";

  const [idEstudiante, setIdEstudiante] = useState(null);
  const [busqueda, setBusqueda] = useState("");

  const listaEstudiantes = useMemo(() => {
    return data.estudiantes
      .map((e) => ({ ...e, persona: data.getPersona(e.id_persona) }))
      .filter((e) => {
        const q = busqueda.toLowerCase();
        return !q || `${e.persona.nombres} ${e.persona.apellidos} ${e.ru || ''}`.toLowerCase().includes(q);
      });
  }, [data, busqueda]);

  const estudianteIdActual = idEstudiante || (esEstudiante ? session?.estudiante?.id_persona : data.estudiantes[0]?.id_persona);
  const estudianteActivo = data.estudiantes.find((e) => e.id_persona === estudianteIdActual) || data.estudiantes[0];
  const personaActiva = estudianteActivo ? data.getPersona(estudianteActivo.id_persona) : null;
  const historial = estudianteActivo ? data.getHistorialEstudiante(estudianteActivo.id_persona) : [];

  const promedioGeneral = useMemo(() => {
    const aprobadas = historial.filter((h) => h.estado === "Aprobado");
    if (aprobadas.length === 0) return 0;
    return Math.round((aprobadas.reduce((acc, h) => acc + h.nota_final, 0) / aprobadas.length) * 100) / 100;
  }, [historial]);

  const exportarPDF = () => {
    generarHistorialPDF({ persona: personaActiva, estudiante: estudianteActivo, historial, promedio: promedioGeneral });
  };

  return (
    <div>
      <SectionHeader
        title="Historial Académico"
        subtitle={esEstudiante ? "Su registro de materias cursadas" : "Consulte el historial de cualquier estudiante"}
        actions={
          <>
            {!esEstudiante && (
              <>
                <input className="search-input" placeholder="Buscar estudiante o RU..." value={busqueda} onChange={(e) => setBusqueda(e.target.value)} />
                <select value={estudianteIdActual || ""} onChange={(e) => setIdEstudiante(Number(e.target.value))}>
                  {listaEstudiantes.map((e) => (
                    <option key={e.id_persona} value={e.id_persona}>{e.persona.nombres} {e.persona.apellidos} — {e.ru}</option>
                  ))}
                </select>
              </>
            )}
            <button className="primary-button small" onClick={exportarPDF}>⬇ Exportar PDF</button>
          </>
        }
      />

      {personaActiva && (
        <div className="page-card" style={{ marginBottom: 16 }}>
          <div className="student-row-header">
            <strong>{personaActiva.nombres} {personaActiva.apellidos}</strong>
            <span className="activity-meta">RU: {estudianteActivo?.ru || `RU-${estudianteActivo?.id_persona}`} · Ingreso: {estudianteActivo?.anio_ingreso || 2021}</span>
            <span className="activity-meta">Promedio (aprobadas): <strong>{promedioGeneral}</strong></span>
          </div>
        </div>
      )}

      <div className="page-card">
        {historial.length === 0 ? (
          <EmptyState text="Sin registros académicos todavía." />
        ) : (
          <table className="table">
            <thead><tr><th>Gestión</th><th>Materia</th><th>Estado</th><th>Nota final</th></tr></thead>
            <tbody>
              {historial.map((h) => (
                <tr key={h.id_detalle}>
                  <td>{h.gestion?.periodo || "—"}</td>
                  <td>{h.materia?.sigla} — {h.materia?.nombre}</td>
                  <td><Badge>{h.estado}</Badge></td>
                  <td>{h.nota_final}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
