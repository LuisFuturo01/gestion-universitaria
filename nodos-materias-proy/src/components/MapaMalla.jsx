import '@xyflow/react/dist/style.css';
import { ReactFlow, Background, Controls, Panel } from '@xyflow/react';

export default function MapaMalla({ nodos, aristas, onNodeClick, onAprobarSemestre, optativasAprobadas }) {
    return (
        <div style={{ width: '100vw', height: '100vh' }}>
            <ReactFlow 
                nodes={nodos} 
                edges={aristas} 
                fitView 
                minZoom={0.1}
                nodesDraggable={false}
                nodesConnectable={false}
                elementsSelectable={true}
                onNodeClick={onNodeClick}
            >
                <Background color='#ccc' gap={16} />
                <Controls />
                
                {/* Panel Izquierdo: Controles Rápidos */}
                <Panel position="top-left" style={{ display: 'flex', flexDirection: 'column', gap: '5px', maxHeight: '90vh', overflowY: 'auto' }}>
                    <div style={{ background: 'white', padding: '15px', borderRadius: '8px', border: '1px solid #cbd5e1' }}>
                        <h4 style={{ margin: '0 0 10px 0', fontFamily: 'sans-serif' }}>Aprobar Semestre</h4>
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
                            <button 
                                key={num} 
                                onClick={() => onAprobarSemestre(`sem-${num}`)}
                                style={{ display: 'block', width: '100%', marginBottom: '5px', cursor: 'pointer', padding: '5px' }}
                            >
                                Semestre {num}
                            </button>
                        ))}
                    </div>
                </Panel>

                {/* Panel Derecho: Progreso de Mención */}
                <Panel position="top-right">
                    <div style={{ background: 'white', padding: '15px', borderRadius: '8px', border: '2px solid #3b82f6', fontFamily: 'sans-serif', textAlign: 'center' }}>
                        <h3 style={{ margin: '0 0 5px 0', color: '#1e3a8a' }}>Mención Datos e IA</h3>
                        <p style={{ margin: 0, fontSize: '18px', fontWeight: 'bold' }}>
                            {optativasAprobadas} / 5 Electivas
                        </p>
                    </div>
                </Panel>

            </ReactFlow>
        </div>
    );
}