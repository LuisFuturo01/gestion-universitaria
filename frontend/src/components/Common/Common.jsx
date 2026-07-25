export function StatCard({ icon, label, value, tone = "blue" }) {
  return (
    <div className={`stat-card tone-${tone}`}>
      <span className="stat-icon" aria-hidden="true">{icon}</span>
      <div>
        <p className="stat-value">{value}</p>
        <p className="stat-label">{label}</p>
      </div>
    </div>
  );
}

const BADGE_TONE = {
  Aprobado: "badge-green",
  Cursando: "badge-yellow",
  Inscrito: "badge-yellow",
  Reprobado: "badge-red",
  Abandono: "badge-gray",
  Pendiente: "badge-blue",
  Activa: "badge-green",
  Cerrada: "badge-gray",
};

export function Badge({ children }) {
  return <span className={`badge ${BADGE_TONE[children] || "badge-blue"}`}>{children}</span>;
}

export function EmptyState({ text }) {
  return <div className="empty-state">{text}</div>;
}

export function SectionHeader({ title, subtitle, actions }) {
  return (
    <div className="section-header">
      <div>
        <h2 className="section-title">{title}</h2>
        {subtitle && <p className="section-subtitle">{subtitle}</p>}
      </div>
      {actions && <div className="section-actions">{actions}</div>}
    </div>
  );
}
