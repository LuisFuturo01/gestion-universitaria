import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

const HEADER_COLOR = [13, 39, 72];

function encabezado(doc, titulo, subtitulo) {
  doc.setFillColor(...HEADER_COLOR);
  doc.rect(0, 0, doc.internal.pageSize.getWidth(), 26, "F");
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(14);
  doc.text("Sistema Académico Universitario", 14, 11);
  doc.setFontSize(11);
  doc.text(titulo, 14, 19);
  doc.setTextColor(30, 30, 30);
  doc.setFontSize(9);
  if (subtitulo) doc.text(subtitulo, 14, 33);
  return subtitulo ? 40 : 32;
}

function piePagina(doc) {
  const fecha = new Date().toLocaleString("es-BO");
  const pageCount = doc.internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFontSize(8);
    doc.setTextColor(120, 120, 120);
    doc.text(`Generado: ${fecha}`, 14, doc.internal.pageSize.getHeight() - 8);
    doc.text(`Página ${i} de ${pageCount}`, doc.internal.pageSize.getWidth() - 30, doc.internal.pageSize.getHeight() - 8);
  }
}

export function generarHistorialPDF({ persona, estudiante, historial, promedio }) {
  const doc = new jsPDF();
  const y = encabezado(
    doc,
    "Historial Académico",
    `${persona.nombres} ${persona.apellidos}  |  RU: ${estudiante.ru}  |  Promedio: ${promedio}`
  );

  autoTable(doc, {
    startY: y,
    head: [["Gestión", "Materia", "Estado", "Nota Final"]],
    body: historial.map((h) => [h.gestion.periodo, `${h.materia.sigla} - ${h.materia.nombre}`, h.estado, h.nota_final]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });

  piePagina(doc);
  doc.save(`historial_${estudiante.ru}.pdf`);
}

export function generarReporteEstudiantesPorCarrera({ carreraNombre, filas }) {
  const doc = new jsPDF();
  const y = encabezado(doc, `Estudiantes inscritos — ${carreraNombre}`, `Total: ${filas.length} estudiantes`);
  autoTable(doc, {
    startY: y,
    head: [["RU", "Nombre completo", "Año ingreso", "Materias cursando", "Promedio"]],
    body: filas.map((f) => [f.ru, f.nombre, f.anio_ingreso, f.cursando, f.promedio]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });
  piePagina(doc);
  doc.save("reporte_estudiantes_por_carrera.pdf");
}

export function generarReporteCargaDocente({ filas }) {
  const doc = new jsPDF();
  const y = encabezado(doc, "Carga Horaria Docente", `Gestión activa — ${filas.length} docentes`);
  autoTable(doc, {
    startY: y,
    head: [["Docente", "Grado académico", "Paralelos a cargo", "Total estudiantes"]],
    body: filas.map((f) => [f.nombre, f.grado, f.paralelos, f.totalEstudiantes]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });
  piePagina(doc);
  doc.save("reporte_carga_docente.pdf");
}

export function generarReporteRendimiento({ filas }) {
  const doc = new jsPDF();
  const y = encabezado(doc, "Rendimiento Académico General", `${filas.length} materias evaluadas`);
  autoTable(doc, {
    startY: y,
    head: [["Materia", "Aprobados", "Reprobados", "En curso", "% Aprobación"]],
    body: filas.map((f) => [f.materia, f.aprobados, f.reprobados, f.cursando, `${f.porcentaje}%`]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });
  piePagina(doc);
  doc.save("reporte_rendimiento_academico.pdf");
}

export function generarReporteCierreGestion({ periodo, filas, resumen }) {
  const doc = new jsPDF();
  const y = encabezado(
    doc,
    `Cierre de Gestión — ${periodo}`,
    `Aprobados: ${resumen.aprobados}  |  Reprobados: ${resumen.reprobados}  |  Total: ${resumen.total}`
  );
  autoTable(doc, {
    startY: y,
    head: [["Estudiante", "RU", "Materia", "Nota Final", "Estado"]],
    body: filas.map((f) => [f.estudiante, f.ru, f.materia, f.nota_final, f.estado]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 8 },
  });
  piePagina(doc);
  doc.save(`cierre_gestion_${periodo.replace("/", "-")}.pdf`);
}
