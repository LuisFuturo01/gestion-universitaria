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

function applyAutoTable(doc, options) {
  try {
    if (typeof autoTable === "function") {
      autoTable(doc, options);
      return;
    }
  } catch (e) {
    /* fallback a doc.autoTable */
  }

  try {
    if (typeof doc.autoTable === "function") {
      doc.autoTable(options);
      return;
    }
  } catch (e2) {
    /* fallback manual */
  }

  // Fallback simple formateado si jspdf-autotable no se acopla dinámicamente
  let currentY = options.startY || 40;
  doc.setFontSize(9);
  doc.setFont("helvetica", "bold");
  if (options.head && options.head[0]) {
    doc.text(options.head[0].join("   |   "), 14, currentY);
    currentY += 8;
  }
  doc.setFont("helvetica", "normal");
  (options.body || []).forEach((row) => {
    if (currentY > doc.internal.pageSize.getHeight() - 20) {
      doc.addPage();
      currentY = 20;
    }
    const linea = row.map(val => String(val !== null && val !== undefined ? val : '')).join("   |   ");
    doc.text(linea.slice(0, 110), 14, currentY);
    currentY += 6;
  });
}

export function generarHistorialPDF({ persona, estudiante, historial, promedio }) {
  const doc = new jsPDF();
  const y = encabezado(
    doc,
    "Historial Académico",
    `${persona.nombres} ${persona.apellidos}  |  RU: ${estudiante.ru}  |  Promedio: ${promedio}`
  );

  applyAutoTable(doc, {
    startY: y,
    head: [["Gestión", "Materia", "Estado", "Nota Final"]],
    body: (historial || []).map((h) => [
      h.gestion?.periodo || "I/2026",
      `${h.materia?.sigla || ''} - ${h.materia?.nombre || ''}`,
      h.estado || "Inscrito",
      `${h.nota_final || 0} pts`
    ]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });

  piePagina(doc);
  doc.save(`historial_${estudiante?.ru || 'estudiante'}.pdf`);
}

export function generarReporteEstudiantesPorCarrera({ carreraNombre, filas }) {
  const doc = new jsPDF();
  const y = encabezado(doc, `Estudiantes inscritos — ${carreraNombre}`, `Total: ${(filas || []).length} estudiantes`);
  applyAutoTable(doc, {
    startY: y,
    head: [["RU", "Nombre completo", "Año ingreso", "Materias cursando", "Promedio"]],
    body: (filas || []).map((f) => [f.ru, f.nombre, f.anio_ingreso, f.cursando, f.promedio]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });
  piePagina(doc);
  doc.save("reporte_estudiantes_por_carrera.pdf");
}

export function generarReporteCargaDocente({ filas }) {
  const doc = new jsPDF();
  const y = encabezado(doc, "Carga Horaria Docente", `Gestión activa — ${(filas || []).length} docentes`);
  applyAutoTable(doc, {
    startY: y,
    head: [["Docente", "Grado académico", "Paralelos a cargo", "Total estudiantes"]],
    body: (filas || []).map((f) => [f.nombre, f.grado, f.paralelos, f.totalEstudiantes]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });
  piePagina(doc);
  doc.save("reporte_carga_docente.pdf");
}

export function generarReporteRendimiento({ filas }) {
  const doc = new jsPDF();
  const y = encabezado(doc, "Rendimiento Académico General", `${(filas || []).length} materias evaluadas`);
  applyAutoTable(doc, {
    startY: y,
    head: [["Materia", "Aprobados", "Reprobados", "En curso", "% Aprobación"]],
    body: (filas || []).map((f) => [f.materia, f.aprobados, f.reprobados, f.cursando, `${f.porcentaje}%`]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 9 },
  });
  piePagina(doc);
  doc.save("reporte_rendimiento_academico.pdf");
}

export function generarReporteCierreGestion({ periodo, filas, resumen }) {
  const doc = new jsPDF();
  const res = resumen || {};
  const list = filas || [];
  const y = encabezado(
    doc,
    `Acta Oficial de Cierre de Gestión — ${periodo || '2026'}`,
    `Aprobados: ${res.aprobados || 0}  |  Reprobados: ${res.reprobados || 0}  |  Total Evaluados: ${res.total || list.length}`
  );
  applyAutoTable(doc, {
    startY: y,
    head: [["Estudiante", "RU", "Materia", "Nota Final", "Estado"]],
    body: list.map((f) => [f.estudiante, f.ru, f.materia, `${f.nota_final || 0} pts`, f.estado]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 8 },
  });
  piePagina(doc);
  doc.save(`acta_cierre_gestion_${(periodo || '2026').replace("/", "-")}.pdf`);
}

export function generarReporteGeneralEstadisticasPDF({ carreraNombre, periodoActivo, docentesCount, estudiantesCount, rendimiento, cargaDocente }) {
  const doc = new jsPDF();
  const y = encabezado(
    doc,
    `Reporte Estadístico e Indicadores — ${carreraNombre}`,
    `Gestión Activa: ${periodoActivo}  |  Estudiantes: ${estudiantesCount}  |  Docentes: ${docentesCount}`
  );

  let currentY = y;
  doc.setFontSize(11);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(...HEADER_COLOR);
  doc.text("1. Resumen de Rendimiento Académico por Asignatura", 14, currentY);
  currentY += 6;

  applyAutoTable(doc, {
    startY: currentY,
    head: [["Materia / Sigla", "Aprobados", "Reprobados", "En Curso", "% Aprobación"]],
    body: (rendimiento || []).map((r) => [r.materia, r.aprobados, r.reprobados, r.cursando, `${r.porcentaje}%`]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 8 },
  });

  const finalY = doc.lastAutoTable ? doc.lastAutoTable.finalY + 12 : currentY + 40;

  if (finalY < doc.internal.pageSize.getHeight() - 50) {
    currentY = finalY;
  } else {
    doc.addPage();
    currentY = 20;
  }

  doc.setFontSize(11);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(...HEADER_COLOR);
  doc.text("2. Distribución y Carga Horaria Docente", 14, currentY);
  currentY += 6;

  applyAutoTable(doc, {
    startY: currentY,
    head: [["Docente", "Grado Académico", "Paralelos Asignados", "Estudiantes a Cargo"]],
    body: (cargaDocente || []).map((c) => [c.nombre, c.grado, c.paralelos, c.totalEstudiantes]),
    headStyles: { fillColor: HEADER_COLOR },
    styles: { fontSize: 8 },
  });

  piePagina(doc);
  doc.save(`reporte_estadisticas_${carreraNombre.toLowerCase().replace(/\s+/g, "_")}.pdf`);
}
