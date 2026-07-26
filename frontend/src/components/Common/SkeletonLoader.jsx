export function SkeletonCard({ height = 120, count = 1 }) {
  return (
    <>
      {Array.from({ length: count }).map((_, idx) => (
        <div
          key={idx}
          className="skeleton-box"
          style={{
            height,
            borderRadius: 12,
            background: "linear-gradient(90deg, rgba(255,255,255,0.03) 25%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.03) 75%)",
            backgroundSize: "200% 100%",
            animation: "skeletonShimmer 1.5s infinite",
            marginBottom: 16
          }}
        />
      ))}
    </>
  );
}

export function SkeletonTable({ rows = 5, cols = 4 }) {
  return (
    <div style={{ width: "100%", overflow: "hidden" }}>
      {Array.from({ length: rows }).map((_, rIdx) => (
        <div
          key={rIdx}
          style={{
            display: "flex",
            gap: 16,
            padding: "12px 0",
            borderBottom: "1px solid rgba(255,255,255,0.05)"
          }}
        >
          {Array.from({ length: cols }).map((_, cIdx) => (
            <div
              key={cIdx}
              style={{
                flex: 1,
                height: 20,
                borderRadius: 6,
                background: "linear-gradient(90deg, rgba(255,255,255,0.03) 25%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.03) 75%)",
                backgroundSize: "200% 100%",
                animation: "skeletonShimmer 1.5s infinite"
              }}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
