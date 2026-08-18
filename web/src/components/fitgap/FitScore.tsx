import { cn } from "@/lib/utils";
import type { SkillComparison } from "@/types";

interface FitScoreProps {
  comparisons: SkillComparison[];
  roleTitle?: string;
}

function getReadinessLabel(pct: number): { label: string; sub: string; color: string; ring: string } {
  if (pct >= 80) return { label: "Ready to Hire", sub: "Meets or exceeds most requirements", color: "text-green-700", ring: "ring-green-500" };
  if (pct >= 60) return { label: "Conditional", sub: "Meets most requirements with minor gaps", color: "text-amber-700", ring: "ring-amber-500" };
  return { label: "Not Recommended", sub: "Significant skill gaps for this role", color: "text-red-700", ring: "ring-red-500" };
}

export default function FitScore({ comparisons, roleTitle }: FitScoreProps) {
  const total        = comparisons.length;
  const matchCount   = comparisons.filter((c) => c.result === "match").length;
  const exceedCount  = comparisons.filter((c) => c.result === "exceed").length;
  const gapCount     = comparisons.filter((c) => c.result === "gap").length;
  const naCount      = comparisons.filter((c) => c.result === "not_assessed").length;

  const pct = total > 0 ? Math.round(((matchCount + exceedCount) / total) * 100) : 0;
  const { label, sub, color, ring } = getReadinessLabel(pct);

  // Segment widths
  const exceedPct = total > 0 ? (exceedCount / total) * 100 : 0;
  const matchPct  = total > 0 ? (matchCount  / total) * 100 : 0;
  const gapPct    = total > 0 ? (gapCount    / total) * 100 : 0;
  const naPct     = total > 0 ? (naCount     / total) * 100 : 0;

  return (
    <div className={cn("rounded-lg border p-4 space-y-3 ring-1", ring)}>
      <div className="flex items-start justify-between gap-4">
        <div>
          {roleTitle && (
            <p className="text-xs text-muted-foreground mb-0.5">Fit assessment for</p>
          )}
          <h2 className="font-semibold text-sm">{roleTitle ?? "Fit Score"}</h2>
        </div>

        {/* Score badge */}
        <div className="text-right shrink-0">
          <span className={cn("text-3xl font-bold leading-none", color)}>{pct}%</span>
          <p className={cn("text-xs font-medium mt-0.5", color)}>{label}</p>
        </div>
      </div>

      {/* Stacked progress bar */}
      <div className="w-full h-2.5 rounded-full bg-neutral-100 overflow-hidden flex">
        {exceedPct > 0 && (
          <div className="h-full bg-green-500 transition-all" style={{ width: `${exceedPct}%` }} title={`Exceeds: ${exceedCount}`} />
        )}
        {matchPct > 0 && (
          <div className="h-full bg-teal-400 transition-all" style={{ width: `${matchPct}%` }} title={`Match: ${matchCount}`} />
        )}
        {gapPct > 0 && (
          <div className="h-full bg-amber-400 transition-all" style={{ width: `${gapPct}%` }} title={`Gap: ${gapCount}`} />
        )}
        {naPct > 0 && (
          <div className="h-full bg-neutral-300 transition-all" style={{ width: `${naPct}%` }} title={`Not assessed: ${naCount}`} />
        )}
      </div>

      {/* Legend */}
      <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
        {exceedCount > 0 && <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-green-500 inline-block" />Exceeds: {exceedCount}</span>}
        {matchCount > 0  && <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-teal-400 inline-block" />Match: {matchCount}</span>}
        {gapCount > 0    && <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-amber-400 inline-block" />Gap: {gapCount}</span>}
        {naCount > 0     && <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-neutral-300 inline-block" />Not assessed: {naCount}</span>}
        <span className="ml-auto italic">{sub}</span>
      </div>
    </div>
  );
}
