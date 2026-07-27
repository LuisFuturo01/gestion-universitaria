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
      .map((e) => {
        const estReal = data.getEstudiante ? data.getEstudiante(e.id_persona) : e;
        return { ...estReal, persona: data.getPersona(e.id_persona) };
      })
      .filter((e) => {
        const q = busqueda.toLowerCase();
        return !q || `${e.persona.nombres} ${e.persona.apellidos} ${e.persona.ci || ''} ${e.ru || ''}`.toLowerCase().includes(q);
      });
  }, [data, busqueda]);

  const estudianteIdActual = esEstudiante
    ? session?.id_persona
    : (idEstudiante || data.estudiantes[0]?.id_persona);

  const estudianteActivo = data.getEstudiante ? data.getEstudiante(estudianteIdActual) : { id_persona: estudianteIdActual, ru: `RU-${estudianteIdActual}`, anio_ingreso: 2021 };
  const personaActiva = data.getPersona(estudianteIdActual);
  const historial = data.getHistorialEstudiante(estudianteIdActual);

  const promedioGeneral = useMemo(() => {
    const aprobadas = historial.filter((h) => h.estado === "Aprobado" || Number(h.nota_final) >= 51);
    if (aprobadas.length === 0) return 0;
    return Math.round((aprobadas.reduce((acc, h) => acc + Number(h.nota_final || 0), 0) / aprobadas.length) * 100) / 100;
  }, [historial]);

  const exportarPDF = () => {
    generarHistorialPDF({ persona: personaActiva, estudiante: estudianteActivo, historial, promedio: promedioGeneral });
  };

  return (
    <div>
      <SectionHeader
        title={esEstudiante ? "Mi Kárdex Académico Personal" : "Buscador de Historial Académico"}
        subtitle={esEstudiante ? "Registro oficial de materias cursadas y promedio ponderado" : "Búsqueda global por RU o Cédula de Identidad (CI)"}
        actions={
          <>
            {!esEstudiante && (
              <>
                <input className="search-input" placeholder="Buscar por Nombre, CI o RU..." value={busqueda} onChange={(e) => setBusqueda(e.target.value)} />
                <select value={estudianteIdActual || ""} onChange={(e) => setIdEstudiante(Number(e.target.value))}>
                  {listaEstudiantes.map((e) => (
                    <option key={e.id_persona} value={e.id_persona}>{e.persona.nombres} {e.persona.apellidos} — CI: {e.persona.ci} (RU: {e.ru})</option>
                  ))}
                </select>
              </>
            )}
            <button className="primary-button small" onClick={exportarPDF}>⬇ Exportar Kárdex PDF</button>
          </>
        }
      />

      {personaActiva && (
        <div className="page-card" style={{ marginBottom: 16 }}>
          <div className="student-row-header">
            <strong>{personaActiva.nombres} {personaActiva.apellidos}</strong>
            <span className="activity-meta">CI: {personaActiva.ci} · RU: {estudianteActivo?.ru || `RU-${estudianteActivo?.id_persona}`}</span>
            <span className="activity-meta">Promedio Ponderado Aprobado: <strong>{promedioGeneral} pts</strong></span>
          </div>
        </div>
      )}

      <div className="page-card">
        {historial.length === 0 ? (
          <EmptyState text="Sin registros académicos oficiales." />
        ) : (
          <table className="table">
            <thead><tr><th>Gestión</th><th>Materia</th><th>Estado</th><th>Nota Final</th></tr></thead>
            <tbody>
              {historial.map((h) => (
                <tr key={h.id_detalle}>
                  <td>{h.gestion?.periodo || "I/2026"}</td>
                  <td><strong>{h.materia?.sigla}</strong> — {h.materia?.nombre}</td>
                  <td><Badge>{h.estado}</Badge></td>
                  <td><strong>{h.nota_final} pts</strong></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
