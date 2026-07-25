import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

// roles: lista de roles permitidos para esta ruta. Vacío/omitido = cualquier usuario autenticado.
export default function ProtectedRoute({ roles = [], children }) {
  const { session, loading } = useAuth();

  if (loading) return null;
  if (!session) return <Navigate to="/login" replace />;

  if (roles.length > 0 && !session.roles.some((r) => roles.includes(r))) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}
