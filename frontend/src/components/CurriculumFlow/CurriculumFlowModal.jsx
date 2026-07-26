import React, { useState, useMemo, useRef } from "react";

const COLORES = {
  aprobado: { bg: "#dcfce7", border: "#16a34a", text: "#14532d", badge: "✅ Aprobado" },
  disponible: { bg: "#fef9c3", border: "#eab308", text: "#713f12", badge: "⭐ Disponible" },
  bloqueado: { bg: "#f1f5f9", border: "#cbd5e1", text: "#64748b", badge: "🔒 Bloqueado" }
};

// Layout constants — generous spacing so arrows are clearly visible
const CARD_W = 220;
const CARD_H = 130;
const COL_GAP = 100;   // horizontal gap BETWEEN columns (room for arrows)
const ROW_GAP = 20;    // vertical gap between cards
const COL_TOTAL = CARD_W + COL_GAP;
const HEADER_H = 44;
const PAD_TOP = HEADER_H + 20;
const PAD_LEFT = 20;

export default function CurriculumFlowModal({ plan, data, estudiante, onClose }) {
  const [nodoSeleccionado, setNodoSeleccionado] = useState(null);
  const [zoom, setZoom] = useState(0.85);
  const containerRef = useRef(null);

  const idPlan = plan?.id_plan || 1;
  const idEstudiante = estudiante?.id_persona;

  const aprobadasIds = useMemo(() => {
    if (!idEstudiante) return [];
    return data.getMateriasAprobadas(idEstudiante).map(Number);
  }, [data, idEstudiante]);

  const pensumConEstado = useMemo(() => {
    const pmLista = data.getPensumPlan(idPlan);
    return pmLista.map((pm) => {
      const idMat = Number(pm.id_materia);
      const esAprobada = aprobadasIds.includes(idMat);
      const evalInscripcion = data.puedeInscribirse(idEstudiante || 0, idPlan, idMat);
      let estado = "bloqueado";
      if (esAprobada) estado = "aprobado";
      else if (evalInscripcion.ok) estado = "disponible";
      return { ...pm, id_materia: idMat, estado, motivoBloqueo: evalInscripcion.motivo || "" };
    });
  }, [data, idPlan, idEstudiante, aprobadasIds]);

  const semestresMap = useMemo(() => {
    const map = new Map();
    pensumConEstado.forEach((pm) => {
      const sem = pm.semestre || 1;
      if (!map.has(sem)) map.set(sem, []);
      map.get(sem).push(pm);
    });
    return Array.from(map.entries()).sort((a, b) => a[0] - b[0]);
  }, [pensumConEstado]);

  // Pixel position of each node's center, keyed by id_materia
  const posicionesNodos = useMemo(() => {
    const pos = new Map();
    semestresMap.forEach(([_sem, materias], semIdx) => {
      materias.forEach((pm, itemIdx) => {
        const cx = PAD_LEFT + semIdx * COL_TOTAL + CARD_W / 2;
        const cy = PAD_TOP + itemIdx * (CARD_H + ROW_GAP) + CARD_H / 2;
        pos.set(Number(pm.id_materia), { cx, cy });
      });
    });
    return pos;
  }, [semestresMap]);

  const relacionesPrerequisitos = useMemo(() => {
    const rels = [];
    pensumConEstado.forEach((target) => {
      const reqs = data.getPrerrequisitos(idPlan, target.id_materia);
      reqs.forEach((reqId) => {
        const source = pensumConEstado.find((p) => Number(p.id_materia) === Number(reqId));
        if (source) {
          rels.push({
            id: `e-${source.id_materia}-${target.id_materia}`,
            srcId: Number(source.id_materia),
            tgtId: Number(target.id_materia)
          });
        }
      });
    });
    return rels;
  }, [data, idPlan, pensumConEstado]);

  // Stats
  const total = pensumConEstado.length;
  const aprobadas = pensumConEstado.filter((p) => p.estado === "aprobado").length;
  const disponibles = pensumConEstado.filter((p) => p.estado === "disponible").length;
  const pct = total > 0 ? Math.round((aprobadas / total) * 100) : 0;

  // Which edges light up when a node is clicked
  const aristasActivas = useMemo(() => {
    if (!nodoSeleccionado) return new Set();
    const s = new Set();
    relacionesPrerequisitos.forEach((r) => {
      if (r.srcId === nodoSeleccionado || r.tgtId === nodoSeleccionado) s.add(r.id);
    });
    return s;
  }, [nodoSeleccionado, relacionesPrerequisitos]);

  // Canvas dimensions
  const canvasW = PAD_LEFT + semestresMap.length * COL_TOTAL + 40;
  const maxRows = Math.max(...semestresMap.map(([_, m]) => m.length), 1);
  const canvasH = PAD_TOP + maxRows * (CARD_H + ROW_GAP) + 60;

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 9999, background: "rgba(15,23,42,0.85)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ width: "96vw", maxWidth: 1500, height: "94vh", display: "flex", flexDirection: "column", borderRadius: 16, overflow: "hidden", background: "#f8fafc", boxShadow: "0 25px 50px -12px rgba(0,0,0,0.5)" }}>

        {/* ── Header ── */}
        <div style={{ background: "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)", color: "#fff", padding: "14px 24px", display: "flex", alignItems: "center", justifyContent: "space-between", flexShrink: 0 }}>
          <div>
            <h3 style={{ margin: 0, fontSize: "1.2rem", fontWeight: 800 }}>
              🗺️ Flujo de Malla Curricular
              <span style={{ color: "#38bdf8", fontSize: "0.9rem", fontWeight: 600, marginLeft: 10 }}>{plan?.nombre || "Informática"}</span>
            </h3>
            <p style={{ margin: "2px 0 0", fontSize: "0.8rem", color: "#94a3b8" }}>Estructura de dependencias entre materias — Haga clic en un nodo para resaltar sus conexiones</p>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ display: "flex", alignItems: "center", background: "#334155", borderRadius: 8, padding: "2px 6px", gap: 2 }}>
              <button type="button" onClick={() => setZoom((z) => Math.max(0.4, z - 0.1))} style={{ background: "none", border: "none", color: "#fff", cursor: "pointer", fontSize: "1rem", padding: "2px 6px" }}>−</button>
              <span style={{ fontSize: "0.78rem", color: "#cbd5e1", minWidth: 38, textAlign: "center" }}>{Math.round(zoom * 100)}%</span>
              <button type="button" onClick={() => setZoom((z) => Math.min(1.6, z + 0.1))} style={{ background: "none", border: "none", color: "#fff", cursor: "pointer", fontSize: "1rem", padding: "2px 6px" }}>+</button>
            </div>
            <button onClick={onClose} style={{ background: "#ef4444", color: "#fff", border: "none", borderRadius: 8, padding: "7px 14px", fontWeight: 700, cursor: "pointer", fontSize: "0.85rem" }}>Cerrar ✕</button>
          </div>
        </div>

        {/* ── Progress bar + legend ── */}
        <div style={{ background: "#fff", padding: "10px 24px", borderBottom: "1px solid #e2e8f0", display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 12, flexShrink: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div>
              <div style={{ fontSize: "0.72rem", color: "#64748b", textTransform: "uppercase", fontWeight: 700, letterSpacing: "0.05em" }}>Avance</div>
              <div style={{ fontSize: "1rem", fontWeight: 800, color: "#0f172a" }}>{aprobadas}/{total} ({pct}%)</div>
            </div>
            <div style={{ width: 120, height: 8, background: "#e2e8f0", borderRadius: 4, overflow: "hidden" }}>
              <div style={{ width: `${pct}%`, height: "100%", background: "#16a34a", transition: "width 0.3s" }} />
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 14, fontSize: "0.78rem", fontWeight: 700, flexWrap: "wrap" }}>
            {[
              { label: `Aprobada (${aprobadas})`, c: COLORES.aprobado },
              { label: `Disponible (${disponibles})`, c: COLORES.disponible },
              { label: `Bloqueada (${total - aprobadas - disponibles})`, c: COLORES.bloqueado }
            ].map((l) => (
              <span key={l.label} style={{ display: "flex", alignItems: "center", gap: 5 }}>
                <span style={{ width: 12, height: 12, borderRadius: 3, background: l.c.bg, border: `2px solid ${l.c.border}` }} />
                {l.label}
              </span>
            ))}
            <span style={{ display: "inline-flex", alignItems: "center", gap: 5, color: "#64748b" }}>
              <svg width="28" height="10"><line x1="0" y1="5" x2="20" y2="5" stroke="#94a3b8" strokeWidth="2" strokeDasharray="4 3" /><polygon points="20,1 28,5 20,9" fill="#94a3b8" /></svg>
              Prerrequisito
            </span>
            <span style={{ display: "inline-flex", alignItems: "center", gap: 5, color: "#2563eb" }}>
              <svg width="28" height="10"><line x1="0" y1="5" x2="20" y2="5" stroke="#2563eb" strokeWidth="3" /><polygon points="20,1 28,5 20,9" fill="#2563eb" /></svg>
              Seleccionado
            </span>
          </div>
        </div>

        {/* ── Canvas ── */}
        <div ref={containerRef} style={{ flex: 1, overflow: "auto", background: "radial-gradient(circle at 50% 0%, #e0e7ff 0%, #f1f5f9 60%)", position: "relative" }}>
          <div style={{ position: "relative", width: canvasW, height: canvasH, transform: `scale(${zoom})`, transformOrigin: "top left", transition: "transform 0.15s ease" }}>

            {/* SVG edges layer */}
            <svg style={{ position: "absolute", inset: 0, width: canvasW, height: canvasH, pointerEvents: "none", zIndex: 1 }}>
              <defs>
                <marker id="ah-n" markerWidth="10" markerHeight="10" refX="9" refY="5" orient="auto"><polygon points="0 1, 10 5, 0 9" fill="#94a3b8" /></marker>
                <marker id="ah-a" markerWidth="12" markerHeight="12" refX="11" refY="6" orient="auto"><polygon points="0 1, 12 6, 0 11" fill="#2563eb" /></marker>
              </defs>
              {relacionesPrerequisitos.map((rel) => {
                const s = posicionesNodos.get(rel.srcId);
                const t = posicionesNodos.get(rel.tgtId);
                if (!s || !t) return null;

                const x1 = s.cx + CARD_W / 2 + 4;   // right edge of source
                const y1 = s.cy;
                const x2 = t.cx - CARD_W / 2 - 4;   // left edge of target
                const y2 = t.cy;
                const active = aristasActivas.has(rel.id);

                // Bezier control points: horizontal offset proportional to gap
                const dx = Math.abs(x2 - x1);
                const cp = dx * 0.45;
                const d = `M${x1},${y1} C${x1 + cp},${y1} ${x2 - cp},${y2} ${x2},${y2}`;

                return (
                  <path
                    key={rel.id}
                    d={d}
                    fill="none"
                    stroke={active ? "#2563eb" : "#94a3b8"}
                    strokeWidth={active ? 3.5 : 2}
                    strokeDasharray={active ? "none" : "8 5"}
                    strokeOpacity={active ? 1 : 0.6}
                    markerEnd={active ? "url(#ah-a)" : "url(#ah-n)"}
                    style={{ transition: "all 0.2s ease" }}
                  />
                );
              })}
            </svg>

            {/* HTML nodes layer */}
            <div style={{ position: "relative", zIndex: 2, display: "flex", gap: COL_GAP, paddingLeft: PAD_LEFT }}>
              {semestresMap.map(([sem, materias]) => (
                <div key={sem} style={{ width: CARD_W, flexShrink: 0, display: "flex", flexDirection: "column", gap: ROW_GAP }}>
                  {/* Semester header */}
                  <div style={{
                    height: HEADER_H,
                    background: "linear-gradient(135deg, #1e293b, #334155)",
                    color: "#fff",
                    borderRadius: 10,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: 800,
                    fontSize: "0.88rem",
                    boxShadow: "0 4px 8px rgba(0,0,0,0.15)",
                    letterSpacing: "0.03em"
                  }}>
                    Semestre {sem}
                  </div>

                  {/* Subject cards */}
                  {materias.map((pm) => {
                    const c = COLORES[pm.estado] || COLORES.bloqueado;
                    const sel = nodoSeleccionado === pm.id_materia;
                    // Is this node connected to the selected node?
                    const connected = nodoSeleccionado && relacionesPrerequisitos.some(
                      (r) => (r.srcId === nodoSeleccionado && r.tgtId === pm.id_materia) || (r.tgtId === nodoSeleccionado && r.srcId === pm.id_materia)
                    );

                    return (
                      <div
                        key={pm.id_materia}
                        onClick={() => setNodoSeleccionado(sel ? null : pm.id_materia)}
                        style={{
                          minHeight: CARD_H,
                          background: sel ? "#dbeafe" : connected ? "#ede9fe" : c.bg,
                          border: `2.5px solid ${sel ? "#2563eb" : connected ? "#7c3aed" : c.border}`,
                          borderRadius: 14,
                          padding: "10px 14px",
                          cursor: "pointer",
                          boxShadow: sel
                            ? "0 0 0 4px rgba(37,99,235,0.25), 0 8px 16px rgba(37,99,235,0.15)"
                            : connected
                            ? "0 0 0 3px rgba(124,58,237,0.2)"
                            : "0 2px 6px rgba(0,0,0,0.06)",
                          transition: "all 0.15s ease",
                          display: "flex",
                          flexDirection: "column",
                          justifyContent: "center",
                          position: "relative",
                          overflow: "hidden"
                        }}
                      >
                        {/* Subtle connection dot on left/right edges */}
                        <div style={{ position: "absolute", left: -5, top: "50%", transform: "translateY(-50%)", width: 10, height: 10, borderRadius: "50%", background: sel ? "#2563eb" : connected ? "#7c3aed" : c.border, border: "2px solid #fff" }} />
                        <div style={{ position: "absolute", right: -5, top: "50%", transform: "translateY(-50%)", width: 10, height: 10, borderRadius: "50%", background: sel ? "#2563eb" : connected ? "#7c3aed" : c.border, border: "2px solid #fff" }} />

                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                          <span style={{ fontWeight: 900, fontSize: "0.88rem", color: sel ? "#1d4ed8" : c.text }}>{pm.materia?.sigla}</span>
                          <span style={{ fontSize: "0.68rem", fontWeight: 800, padding: "1px 7px", borderRadius: 10, background: sel ? "#2563eb" : c.border, color: "#fff" }}>{c.badge}</span>
                        </div>
                        <div style={{ fontSize: "0.78rem", fontWeight: 600, color: "#334155", lineHeight: 1.3 }}>
                          {pm.materia?.nombre}
                        </div>
                        {pm.estado === "bloqueado" && pm.motivoBloqueo && (
                          <div style={{ fontSize: "0.7rem", color: "#e11d48", fontWeight: 600, marginTop: 4, lineHeight: 1.3, background: "#ffe4e6", padding: "4px 6px", borderRadius: 6 }}>
                            ⚠ {pm.motivoBloqueo}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
