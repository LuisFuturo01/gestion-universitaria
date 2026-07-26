// src/data/materias.js

// Colores base para inicializar (puedes ajustarlos luego si lo deseas)
const COLOR_BLOQUEADO = "#d1d5db";

// Función auxiliar para generar posiciones verticales automáticamente y no escribir una por una
const yPos = (index) => 50 + (index * 110);

export const nodosIniciales = [
  // --- CONTENEDORES DE SEMESTRES ---
  { id: "sem-1", type: "group", position: { x: 0, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-2", type: "group", position: { x: 300, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-3", type: "group", position: { x: 600, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-4", type: "group", position: { x: 900, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-5", type: "group", position: { x: 1200, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-6", type: "group", position: { x: 1500, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-7", type: "group", position: { x: 1800, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-8", type: "group", position: { x: 2100, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  { id: "sem-9", type: "group", position: { x: 2400, y: 0 }, style: { width: 280, height: 750, border: "2px dashed #94a3b8", backgroundColor: "transparent" } },
  
  // Contenedor gigante horizontal en la parte inferior para la bolsa de optativas
  { id: "grupo-optativas", type: "group", position: { x: 0, y: 800 }, style: { width: 2680, height: 350, border: "3px dashed #64748b", backgroundColor: "#f8fafc" } },

  // --- MATERIAS POR SEMESTRE ---
  // Primer Semestre[cite: 2]
  { id: "inf-111", parentId: "sem-1", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "INF-111 | Prog. I", estado: "Disponible" }, style: { backgroundColor: "#FFD200" } },
  { id: "inf-112", parentId: "sem-1", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "INF-112 | Fund. digitales", estado: "Disponible" }, style: { backgroundColor: "#FFD200" } },
  { id: "inf-113", parentId: "sem-1", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "INF-113 | Prog. web I", estado: "Disponible" }, style: { backgroundColor: "#FFD200" } },
  { id: "inf-114", parentId: "sem-1", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "INF-114 | Álgebra", estado: "Disponible" }, style: { backgroundColor: "#FFD200" } },
  { id: "inf-115", parentId: "sem-1", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "INF-115 | Cálculo I", estado: "Disponible" }, style: { backgroundColor: "#FFD200" } },
  { id: "inf-117", parentId: "sem-1", extent: "parent", position: { x: 15, y: yPos(5) }, data: { label: "INF-117 | Mat. discreta", estado: "Disponible" }, style: { backgroundColor: "#FFD200" } },

  // Segundo Semestre[cite: 2]
  { id: "inf-121", parentId: "sem-2", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "INF-121 | Prog. II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-122", parentId: "sem-2", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "INF-122 | Prog. web II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-123", parentId: "sem-2", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "INF-123 | Electrónica I", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-124", parentId: "sem-2", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "INF-124 | Estadística I", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-125", parentId: "sem-2", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "INF-125 | Álgebra lineal", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-126", parentId: "sem-2", extent: "parent", position: { x: 15, y: yPos(5) }, data: { label: "INF-126 | Cálculo II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Tercer Semestre[cite: 2]
  { id: "inf-131", parentId: "sem-3", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "INF-131 | Prog. III", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-132", parentId: "sem-3", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "INF-132 | Base de datos I", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-133", parentId: "sem-3", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "INF-133 | Prog. web III", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-134", parentId: "sem-3", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "INF-134 | Estadística II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-135", parentId: "sem-3", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "DAT-135 | Cálculo III", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "tra-136", parentId: "sem-3", extent: "parent", position: { x: 15, y: yPos(5) }, data: { label: "TRA-136 | Met. investigación", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Cuarto Semestre[cite: 2]
  { id: "dat-241", parentId: "sem-4", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "DAT-241 | Prog. paralela", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-242", parentId: "sem-4", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "DAT-242 | Métodos num. I", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-243", parentId: "sem-4", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "INF-243 | Inv. Operativa I", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-244", parentId: "sem-4", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "INF-244 | Base de datos II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-245", parentId: "sem-4", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "DAT-245 | Intel. artificial", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-246", parentId: "sem-4", extent: "parent", position: { x: 15, y: yPos(5) }, data: { label: "DAT-246 | Mod. estadística", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Quinto Semestre[cite: 2]
  { id: "dat-251", parentId: "sem-5", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "DAT-251 | Base de Datos III", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-252", parentId: "sem-5", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "DAT-252 | Métodos num. II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-253", parentId: "sem-5", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "DAT-253 | Minería de Datos", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-254", parentId: "sem-5", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "DAT-254 | Inv. Operativa II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-255", parentId: "sem-5", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "DAT-255 | Machine Learning", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "tra-256", parentId: "sem-5", extent: "parent", position: { x: 15, y: yPos(5) }, data: { label: "TRA-256 | Legis. y ética", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Sexto Semestre[cite: 2]
  { id: "dat-261", parentId: "sem-6", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "DAT-261 | NLP", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-262", parentId: "sem-6", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "DAT-262 | Proc. estocásticos", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-263", parentId: "sem-6", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "DAT-263 | Análisis de datos", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-264", parentId: "sem-6", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "DAT-264 | Deep Learning", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-266", parentId: "sem-6", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "INF-266 | Taller Tec. Sup.", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "elec-1", parentId: "sem-6", extent: "parent", position: { x: 15, y: yPos(5) }, data: { label: "Electiva I [Vacío]", estado: "Bloqueado", esSlotOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Séptimo Semestre[cite: 2]
  { id: "dat-371", parentId: "sem-7", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "DAT-371 | Intel. Negocios", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "sis-372", parentId: "sem-7", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "SIS-372 | Comp. en la nube", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "tra-374", parentId: "sem-7", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "TRA-374 | Práctica prof.", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "elec-2", parentId: "sem-7", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "Electiva II [Vacío]", estado: "Bloqueado", esSlotOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "elec-3", parentId: "sem-7", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "Electiva III [Vacío]", estado: "Bloqueado", esSlotOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Octavo Semestre[cite: 2]
  { id: "dat-381", parentId: "sem-8", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "DAT-381 | Big Data", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-382", parentId: "sem-8", extent: "parent", position: { x: 15, y: yPos(1) }, data: { label: "DAT-382 | Visualización", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-384", parentId: "sem-8", extent: "parent", position: { x: 15, y: yPos(2) }, data: { label: "INF-384 | Taller Grad. I", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "elec-4", parentId: "sem-8", extent: "parent", position: { x: 15, y: yPos(3) }, data: { label: "Electiva IV [Vacío]", estado: "Bloqueado", esSlotOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "elec-5", parentId: "sem-8", extent: "parent", position: { x: 15, y: yPos(4) }, data: { label: "Electiva V [Vacío]", estado: "Bloqueado", esSlotOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // Noveno Semestre[cite: 2]
  { id: "inf-391", parentId: "sem-9", extent: "parent", position: { x: 15, y: yPos(0) }, data: { label: "INF-391 | Taller Grad. II", estado: "Bloqueado" }, style: { backgroundColor: COLOR_BLOQUEADO } },

  // --- BOLSA DE OPTATIVAS (Mención IA y Datos)[cite: 2]---
  { id: "dat-311", parentId: "grupo-optativas", extent: "parent", position: { x: 50, y: 50 }, data: { label: "DAT-311 | Cálculo IV", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-312", parentId: "grupo-optativas", extent: "parent", position: { x: 250, y: 50 }, data: { label: "DAT-312 | Mod. Generativos", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-313", parentId: "grupo-optativas", extent: "parent", position: { x: 450, y: 50 }, data: { label: "DAT-313 | Comercio y Mkt", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-314", parentId: "grupo-optativas", extent: "parent", position: { x: 650, y: 50 }, data: { label: "INF-314 | Inglés técnico", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-315", parentId: "grupo-optativas", extent: "parent", position: { x: 850, y: 50 }, data: { label: "INF-315 | Prep. proyectos", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-316", parentId: "grupo-optativas", extent: "parent", position: { x: 1050, y: 50 }, data: { label: "INF-316 | Info. forense", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-317", parentId: "grupo-optativas", extent: "parent", position: { x: 1250, y: 50 }, data: { label: "INF-317 | IoT", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  
  { id: "dat-318", parentId: "grupo-optativas", extent: "parent", position: { x: 50, y: 150 }, data: { label: "DAT-318 | Sim. sistemas", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-319", parentId: "grupo-optativas", extent: "parent", position: { x: 250, y: 150 }, data: { label: "DAT-319 | Prog. móviles I", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-320", parentId: "grupo-optativas", extent: "parent", position: { x: 450, y: 150 }, data: { label: "INF-320 | Auditoría sist.", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "dat-321", parentId: "grupo-optativas", extent: "parent", position: { x: 650, y: 150 }, data: { label: "DAT-321 | Seguridad Info.", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-325", parentId: "grupo-optativas", extent: "parent", position: { x: 850, y: 150 }, data: { label: "INF-325 | Derecho inf.", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-336", parentId: "grupo-optativas", extent: "parent", position: { x: 1050, y: 150 }, data: { label: "INF-336 | Visión artificial", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } },
  { id: "inf-337", parentId: "grupo-optativas", extent: "parent", position: { x: 1250, y: 150 }, data: { label: "INF-337 | Emprendimiento", estado: "Bloqueado", esOptativa: true }, style: { backgroundColor: COLOR_BLOQUEADO } }
];

// Helper para crear aristas repetitivas (semestres vencidos)
const crearAristasMultiples = (sources, targets) => {
  let edges = [];
  targets.forEach(target => {
    sources.forEach(source => {
      edges.push({
        id: `edge-${source}-${target}`, source: source, target: target, animated: true, style: { stroke: "#9ca3af", strokeWidth: 1 }
      });
    });
  });
  return edges;
};

// Listas de materias por semestre para la lógica de "Semestre Vencido"[cite: 2]
const sem3_nodos = ["inf-131", "inf-132", "inf-133", "inf-134", "dat-135", "tra-136"];
const sem5_nodos = ["dat-251", "dat-252", "dat-253", "dat-254", "dat-255", "tra-256"];
const sem6_nodos = ["dat-261", "dat-262", "dat-263", "dat-264", "inf-266"];
const sem7_nodos = ["dat-371", "sis-372", "tra-374"];
const sem8_nodos = ["dat-381", "dat-382", "inf-384"];
const optativas_pool = ["dat-311", "dat-312", "dat-313", "inf-314", "inf-315", "inf-316", "inf-317", "dat-318", "dat-319", "inf-320", "dat-321", "inf-325", "inf-336", "inf-337"];

export const aristasIniciales = [
  // Semestre 2[cite: 2]
  { id: "e-111-121", source: "inf-111", target: "inf-121", animated: true },
  { id: "e-113-122", source: "inf-113", target: "inf-122", animated: true },
  { id: "e-112-123", source: "inf-112", target: "inf-123", animated: true },
  { id: "e-114-124", source: "inf-114", target: "inf-124", animated: true },
  { id: "e-117-124", source: "inf-117", target: "inf-124", animated: true },
  { id: "e-114-125", source: "inf-114", target: "inf-125", animated: true },
  { id: "e-115-126", source: "inf-115", target: "inf-126", animated: true },

  // Semestre 3[cite: 2]
  { id: "e-121-131", source: "inf-121", target: "inf-131", animated: true },
  { id: "e-121-132", source: "inf-121", target: "inf-132", animated: true },
  { id: "e-122-132", source: "inf-122", target: "inf-132", animated: true },
  { id: "e-111-133", source: "inf-111", target: "inf-133", animated: true },
  { id: "e-122-133", source: "inf-122", target: "inf-133", animated: true },
  { id: "e-124-134", source: "inf-124", target: "inf-134", animated: true },
  { id: "e-126-135", source: "inf-126", target: "dat-135", animated: true },
  { id: "e-124-136", source: "inf-124", target: "tra-136", animated: true },
  { id: "e-125-136", source: "inf-125", target: "tra-136", animated: true },

  // Semestre 4[cite: 2]
  { id: "e-131-241", source: "inf-131", target: "dat-241", animated: true },
  { id: "e-135-242", source: "dat-135", target: "dat-242", animated: true },
  { id: "e-134-243", source: "inf-134", target: "inf-243", animated: true },
  { id: "e-132-244", source: "inf-132", target: "inf-244", animated: true },
  { id: "e-123-245", source: "inf-123", target: "dat-245", animated: true },
  { id: "e-125-245", source: "inf-125", target: "dat-245", animated: true },
  { id: "e-134-246", source: "inf-134", target: "dat-246", animated: true },

  // Semestre 5[cite: 2]
  { id: "e-244-251", source: "inf-244", target: "dat-251", animated: true },
  { id: "e-242-252", source: "dat-242", target: "dat-252", animated: true },
  { id: "e-246-253", source: "dat-246", target: "dat-253", animated: true },
  { id: "e-243-254", source: "inf-243", target: "dat-254", animated: true },
  { id: "e-246-255", source: "dat-246", target: "dat-255", animated: true },
  ...crearAristasMultiples(sem3_nodos, ["tra-256"]), // Tercer semestre vencido[cite: 2]

  // Semestre 6[cite: 2]
  { id: "e-251-261", source: "dat-251", target: "dat-261", animated: true },
  { id: "e-134-262", source: "inf-134", target: "dat-262", animated: true },
  { id: "e-135-262", source: "dat-135", target: "dat-262", animated: true },
  { id: "e-253-263", source: "dat-253", target: "dat-263", animated: true },
  { id: "e-254-263", source: "dat-254", target: "dat-263", animated: true },
  { id: "e-255-264", source: "dat-255", target: "dat-264", animated: true },
  ...crearAristasMultiples(sem5_nodos, ["inf-266", "elec-1"]), // Quinto semestre vencido[cite: 2]

  // Semestre 7[cite: 2]
  { id: "e-254-371", source: "dat-254", target: "dat-371", animated: true },
  { id: "e-264-371", source: "dat-264", target: "dat-371", animated: true },
  { id: "e-261-372", source: "dat-261", target: "sis-372", animated: true },
  ...crearAristasMultiples(sem5_nodos, ["tra-374", "elec-2", "elec-3"]), // Quinto semestre vencido[cite: 2]

  // Semestre 8[cite: 2]
  { id: "e-371-381", source: "dat-371", target: "dat-381", animated: true },
  { id: "e-263-382", source: "dat-263", target: "dat-382", animated: true },
  ...crearAristasMultiples(sem7_nodos, ["inf-384"]), // Séptimo semestre vencido[cite: 2]
  ...crearAristasMultiples(sem6_nodos, ["elec-4", "elec-5"]), // Sexto semestre vencido[cite: 2]

  // Semestre 9[cite: 2]
  ...crearAristasMultiples(sem8_nodos, ["inf-391"]), // Octavo semestre vencido[cite: 2]

  // Dependencias de la Bolsa de Optativas (Todas requieren Sexto Semestre Vencido)[cite: 2]
  ...crearAristasMultiples(sem5_nodos, optativas_pool)
];