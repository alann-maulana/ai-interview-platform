import { LEVEL_LABELS, FIT_GAP_RESULT_LABELS, FIT_GAP_RESULT_CLASSES } from "@/utils/constants";
import { cn } from "@/lib/utils";
import type { SkillComparison } from "@/types";

interface ComparisonTableProps {
  comparisons: SkillComparison[];
}

const CONFIDENCE_CLASSES: Record<string, string> = {
  high:   "bg-green-50 text-green-700",
  medium: "bg-amber-50 text-amber-700",
  low:    "bg-red-50  text-red-700",
};

function ConfidenceChip({ confidence }: { confidence?: string }) {
  if (!confidence) return null;
  return (
    <span className={cn("text-[10px] px-1.5 py-0.5 rounded font-medium leading-none", CONFIDENCE_CLASSES[confidence] ?? "bg-neutral-100 text-neutral-600")}>
      {confidence}
    </span>
  );
}

function ResultBadge({ comparison }: { comparison: SkillComparison }) {
  const label   = FIT_GAP_RESULT_LABELS[comparison.result];
  const classes = FIT_GAP_RESULT_CLASSES[comparison.result];

  let icon = "";
  let suffix = "";
  if (comparison.result === "match")   icon = "✅";
  else if (comparison.result === "exceed") { icon = "⭐"; suffix = comparison.delta ? ` +${comparison.delta}` : ""; }
  else if (comparison.result === "gap")    { icon = "⚠"; suffix = comparison.delta ? ` ${comparison.delta}` : ""; }
  else icon = "—";

  return (
    <span className={cn("inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded", classes)}>
      {icon} {label}{suffix}
    </span>
  );
}

// Sort: gaps first → not_assessed → matches → exceeds
const RESULT_ORDER: Record<string, number> = { gap: 0, not_assessed: 1, match: 2, exceed: 3 };

export default function ComparisonTable({ comparisons }: ComparisonTableProps) {
  const sorted = [...comparisons].sort(
    (a, b) => (RESULT_ORDER[a.result] ?? 4) - (RESULT_ORDER[b.result] ?? 4)
  );

  const matchCount    = comparisons.filter((c) => c.result === "match").length;
  const gapCount      = comparisons.filter((c) => c.result === "gap").length;
  const exceedCount   = comparisons.filter((c) => c.result === "exceed").length;
  const naCount       = comparisons.filter((c) => c.result === "not_assessed").length;

  return (
    <div className="space-y-3">
      <div className="overflow-x-auto rounded-lg border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b bg-muted/50">
              <th className="text-left px-4 py-2.5 font-medium">Skill</th>
              <th className="text-center px-4 py-2.5 font-medium">Required</th>
              <th className="text-center px-4 py-2.5 font-medium">Candidate</th>
              <th className="text-center px-4 py-2.5 font-medium">Confidence</th>
              <th className="text-center px-4 py-2.5 font-medium">Result</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((c, i) => (
              <tr key={i} className="border-b last:border-0">
                <td className="px-4 py-2.5">{c.skill_label}</td>

                {/* P0 fix: was c.required_level — always undefined. Now c.expected_level. */}
                <td className="px-4 py-2.5 text-center text-muted-foreground">
                  {LEVEL_LABELS[c.expected_level] ?? "—"}
                </td>

                <td className="px-4 py-2.5 text-center">
                  {c.candidate_level != null ? (
                    <span className="inline-flex items-center gap-1">
                      {LEVEL_LABELS[c.candidate_level]}
                      {/* P0 fix: is_override is now guaranteed boolean from API */}
                      {c.is_override && <span className="text-xs text-muted-foreground" title="Human override applied">✏</span>}
                    </span>
                  ) : (
                    <span className="text-muted-foreground">—</span>
                  )}
                </td>

                <td className="px-4 py-2.5 text-center">
                  <ConfidenceChip confidence={c.confidence} />
                </td>

                <td className="px-4 py-2.5 text-center">
                  <ResultBadge comparison={c} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Summary */}
      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
        {matchCount  > 0 && <span>✅ Match: {matchCount} skill{matchCount !== 1 ? "s" : ""}</span>}
        {gapCount    > 0 && <span>⚠ Gap: {gapCount} skill{gapCount !== 1 ? "s" : ""}</span>}
        {exceedCount > 0 && <span>⭐ Exceeds: {exceedCount} skill{exceedCount !== 1 ? "s" : ""}</span>}
        {naCount     > 0 && <span>— Not assessed: {naCount} skill{naCount !== 1 ? "s" : ""}</span>}
        <span className="ml-auto">✏ = human override applied</span>
      </div>
    </div>
  );
}
