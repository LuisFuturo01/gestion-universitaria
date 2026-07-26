import { createContext, useContext, useState, useCallback } from "react";

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((message, type = "info", duration = 3500) => {
    const id = Date.now() + Math.random();
    setToasts((prev) => [...prev, { id, message, type }]);

    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, duration);
  }, []);

  const removeToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const showSuccess = useCallback((msg) => addToast(msg, "success"), [addToast]);
  const showError = useCallback((msg) => addToast(msg, "error"), [addToast]);
  const showWarning = useCallback((msg) => addToast(msg, "warning"), [addToast]);
  const showInfo = useCallback((msg) => addToast(msg, "info"), [addToast]);

  return (
    <ToastContext.Provider value={{ addToast, removeToast, showSuccess, showError, showWarning, showInfo }}>
      {children}
      <div className="toast-container" style={{
        position: "fixed",
        bottom: 24,
        right: 24,
        zIndex: 9999,
        display: "flex",
        flexDirection: "column",
        gap: 10,
        pointerEvents: "none"
      }}>
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`toast toast-${t.type}`}
            style={{
              pointerEvents: "auto",
              padding: "12px 18px",
              borderRadius: "10px",
              background: t.type === "success" ? "#0f5132" : t.type === "error" ? "#842029" : t.type === "warning" ? "#664d03" : "#055160",
              color: "#ffffff",
              boxShadow: "0 10px 25px rgba(0,0,0,0.25)",
              display: "flex",
              alignItems: "center",
              gap: 12,
              fontSize: "0.9rem",
              fontWeight: 500,
              minWidth: 280,
              maxWidth: 420,
              animation: "toastSlideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1)"
            }}
          >
            <span style={{ fontSize: "1.1rem" }}>
              {t.type === "success" && "✅"}
              {t.type === "error" && "⚠️"}
              {t.type === "warning" && "🔔"}
              {t.type === "info" && "ℹ️"}
            </span>
            <span style={{ flex: 1 }}>{t.message}</span>
            <button
              onClick={() => removeToast(t.id)}
              style={{
                background: "transparent",
                border: "none",
                color: "rgba(255,255,255,0.7)",
                cursor: "pointer",
                fontSize: "1rem",
                padding: "0 4px"
              }}
            >
              ✕
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    return {
      addToast: () => {},
      removeToast: () => {},
      showSuccess: (msg) => console.log("[TOAST SUCCESS]", msg),
      showError: (msg) => console.error("[TOAST ERROR]", msg),
      showWarning: (msg) => console.warn("[TOAST WARN]", msg),
      showInfo: (msg) => console.log("[TOAST INFO]", msg)
    };
  }
  return context;
};
