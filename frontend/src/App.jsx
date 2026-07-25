import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import "./App.css";

import LoginPage from "./pages/Auth/LoginPage";
import DashboardPage from "./pages/Dashboard/DashboardPage";
import UsersPage from "./pages/Users/UsersPage";
import EnrollmentPage from "./pages/Enrollment/EnrollmentPage";
import AcademicOfferPage from "./pages/AcademicOffer/AcademicOfferPage";
import GradesPage from "./pages/Grades/GradesPage";
import HistoryPage from "./pages/History/HistoryPage";
import ReportsPage from "./pages/Reports/ReportsPage";
import GestionClosePage from "./pages/GestionClose/GestionClosePage";

import AppLayout from "./components/Layout/AppLayout";
import ProtectedRoute from "./routes/ProtectedRoute";
import { AuthProvider } from "./context/AuthContext";
import { DataProvider } from "./context/DataContext";

function App() {
  return (
    <AuthProvider>
      <DataProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />

            <Route
              element={
                <ProtectedRoute>
                  <AppLayout />
                </ProtectedRoute>
              }
            >
              <Route path="/dashboard" element={<DashboardPage />} />
              <Route
                path="/usuarios"
                element={
                  <ProtectedRoute roles={["ADMIN"]}>
                    <UsersPage />
                  </ProtectedRoute>
                }
              />
              <Route path="/oferta-academica" element={<AcademicOfferPage />} />
              <Route
                path="/inscripcion"
                element={
                  <ProtectedRoute roles={["ADMIN", "ESTUDIANTE"]}>
                    <EnrollmentPage />
                  </ProtectedRoute>
                }
              />
              <Route path="/notas" element={<GradesPage />} />
              <Route path="/historial" element={<HistoryPage />} />
              <Route
                path="/reportes"
                element={
                  <ProtectedRoute roles={["ADMIN", "DIRECTOR"]}>
                    <ReportsPage />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/cierre-gestion"
                element={
                  <ProtectedRoute roles={["ADMIN", "DIRECTOR"]}>
                    <GestionClosePage />
                  </ProtectedRoute>
                }
              />
            </Route>

            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </DataProvider>
    </AuthProvider>
  );
}

export default App;
