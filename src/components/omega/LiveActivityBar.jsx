import { useState } from "react";

/**
 * Compact strip mirroring the same live step stream WorkspacePanel already
 * consumes (SSE from /api/job/stream/<id>). Tap to expand/collapse; onExpand
 * jumps into the full WorkspacePanel/Sandbox view.
 *
 * Props: steps: [{id, label, status: "running"|"done"|"error"}], isActive, onExpand
 */
export default function LiveActivityBar({ steps = [], isActive, onExpand }) {
  const [collapsed, setCollapsed] = useState(false);
  if (!isActive && steps.length === 0) return null;
  const latest = steps[steps.length - 1];

  return (
    <div className="w-full border border-teal-500/30 bg-black/90 rounded-lg mb-2 text-sm text-teal-300">
      <button className="w-full flex items-center justify-between px-3 py-2" onClick={() => setCollapsed((c) => !c)}>
        <span className="flex items-center gap-2 truncate">
          {isActive && <span className="inline-block h-2 w-2 rounded-full bg-teal-400 animate-pulse" />}
          <span className="truncate">{latest ? latest.label : "Omega is working..."}</span>
        </span>
        <span className="flex items-center gap-3 shrink-0">
          <span className="underline text-teal-400" onClick={(e) => { e.stopPropagation(); onExpand && onExpand(); }}>
            View sandbox
          </span>
          <span>{collapsed ? "▸" : "▾"}</span>
        </span>
      </button>
      {!collapsed && (
        <div className="px-3 pb-2 max-h-40 overflow-y-auto space-y-1">
          {steps.map((s) => (
            <div key={s.id} className="flex items-center gap-2 text-xs">
              <span>{s.status === "done" && "✅"}{s.status === "running" && "⏳"}{s.status === "error" && "❌"}</span>
              <span className="truncate">{s.label}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
