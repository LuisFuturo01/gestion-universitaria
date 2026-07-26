import MapaMalla from "./components/MapaMalla";
import { nodosIniciales, aristasIniciales } from "./data/materias";
import { useState, useEffect } from "react";

const COLORES = {
  bloqueado: "#d1d5db",
  disponible: "#FFD200",
  aprobado: "#86efac"
};

export default function App() {
  const [misNodos, setMisNodos] = useState(nodosIniciales);

  const manejarClicEnNodo = (evento, nodoTocado) => {
    // Ignorar clics en contenedores y en los slots vacíos de electivas
    if (nodoTocado.type === "group" || nodoTocado.data?.esSlotOptativa) return;

    const nuevoEstado = nodoTocado.data.estado === "Aprobado" ? "Disponible" : "Aprobado";
    const nuevoColor = nodoTocado.data.estado === "Aprobado" ? COLORES.disponible : COLORES.aprobado;

    const nuevaListaDeNodos = misNodos.map((nodoActual) => {
      if (nodoActual.id === nodoTocado.id) {
        return {
          ...nodoActual,
          data: { ...nodoActual.data, estado: nuevoEstado },
          style: { ...nodoActual.style, backgroundColor: nuevoColor }
        }
      }
      return nodoActual;
    });
    
    setMisNodos(nuevaListaDeNodos);
  };

  useEffect(() => {
    // 1. Evaluación normal de prerrequisitos
    const nodosActualizados = misNodos.map((nodoHijo) => {
      if (nodoHijo.type === "group") return nodoHijo; 

      const flechasEntrantes = aristasIniciales.filter(
        (arista) => arista.target === nodoHijo.id
      );

      if (flechasEntrantes.length === 0) {
        if (nodoHijo.data.estado === "Aprobado") return nodoHijo;
        return {
          ...nodoHijo,
          data: { ...nodoHijo.data, estado: "Disponible" },
          style: { ...nodoHijo.style, backgroundColor: COLORES.disponible } 
        };
      }

      const todosLosPadresAprobados = flechasEntrantes.every((flecha) => {
        const nodoPadre = misNodos.find((n) => n.id === flecha.source);
        return nodoPadre && nodoPadre.data.estado === "Aprobado";
      });

      if (todosLosPadresAprobados) {
        if (nodoHijo.data.estado === "Aprobado") return nodoHijo;
        return {
          ...nodoHijo,
          data: { ...nodoHijo.data, estado: "Disponible" },
          style: { ...nodoHijo.style, backgroundColor: COLORES.disponible }
        };
      } else {
        return {
          ...nodoHijo,
          data: { ...nodoHijo.data, estado: "Bloqueado" },
          style: { ...nodoHijo.style, backgroundColor: COLORES.bloqueado }
        };
      }
    });

    // 2. Lógica de auto-rellenado de Electivas
    const optativasAprobadas = nodosActualizados.filter(
      n => n.data?.esOptativa && n.data?.estado === "Aprobado"
    ).length;
    
    let slotsUsados = 0;

    const nodosFinales = nodosActualizados.map(nodo => {
      if (nodo.data?.esSlotOptativa) {
        // Solo rellenamos si el semestre de la electiva ya se desbloqueó
        if (nodo.data.estado !== "Bloqueado") { 
           if (slotsUsados < optativasAprobadas) {
             slotsUsados++;
             return {
               ...nodo,
               data: { ...nodo.data, label: `Electiva Cubierta (${slotsUsados})`, estado: "Aprobado" },
               style: { ...nodo.style, backgroundColor: COLORES.aprobado }
             };
           } else {
             return {
               ...nodo,
               data: { ...nodo.data, label: "Electiva [Vacío]", estado: "Disponible" },
               style: { ...nodo.style, backgroundColor: COLORES.disponible }
             };
           }
        }
      }
      return nodo;
    });

    // 3. Verificación de renderizado
    const huboCambios = nodosFinales.some((nuevoNodo, index) => 
       nuevoNodo.data?.estado !== misNodos[index].data?.estado ||
       nuevoNodo.data?.label !== misNodos[index].data?.label
    );

    if (huboCambios) {
      setMisNodos(nodosFinales);
    }
  }, [misNodos]);

  const aprobarSemestreCompleto = (idSemestre) => {
    const nodosActualizados = misNodos.map((nodo) => {
      // Ignoramos los slots vacíos para no aprobarlos a la fuerza
      if (nodo.parentId === idSemestre && !nodo.data?.esSlotOptativa) {
        return {
          ...nodo,
          data: { ...nodo.data, estado: "Aprobado" },
          style: { ...nodo.style, backgroundColor: COLORES.aprobado }
        };
      }
      return nodo;
    });
    setMisNodos(nodosActualizados);
  };

  // Calculamos el total para pasarlo al frontend
  const cantidadOptativas = misNodos.filter(n => n.data?.esOptativa && n.data?.estado === "Aprobado").length;

  return (
    <>
      <MapaMalla 
        nodos={misNodos} 
        aristas={aristasIniciales} 
        onNodeClick={manejarClicEnNodo}
        onAprobarSemestre={aprobarSemestreCompleto}
        optativasAprobadas={cantidadOptativas} 
      />
    </>
  );
}