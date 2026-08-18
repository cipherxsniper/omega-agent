import React, { useState, useMemo } from "react";
import { X, Monitor, ChevronDown, SkipBack, SkipForward, FileEdit, Terminal } from "lucide-react";

// Maps a raw tool_call step into a display-friendly action descriptor.
function describeStep(step) {
  if (!step) return null;

  if (step.role === "assistant" && step.tool_calls) {
    const tc = step.tool_calls[0];
    const name = tc?.function?.name || "tool";
    let args = {};
    try { args = JSON.parse(tc?.function?.arguments || "{}"); } catch {}
    if (name === "write_file" || name === "edit_file") {
      return { kind: "editor", label: `Creating file: ${args.path || "?"}`, path: args.path, content: args.content };
    }
    if (name === "run_bash") {
      return { kind: "terminal", label: "Running command", command: args.command };
    }
    return { kind: "tool", label: `Using ${name}`, args };
  }

  if (step.role === "tool") {
    const out = step.result?.output || {};
    if (out.path) {
      return { kind: "editor", label: `Wrote: ${out.path}`, path: out.path, content: out.stdout || "" };
    }
    if (out.command) {
      return { kind: "terminal", label: "Command finished", command: out.command, stdout: out.stdout, stderr: out.stderr };
    }
  }

  return null;
}

export default function SandboxPanel({ steps = [], agentName = "Omega", onClose, live = true }) {
  const [index, setIndex] = useState(Math.max(0, steps.length - 1));
  const [tab, setTab] = useState("Modified");

  const descriptors = useMemo(() => steps.map(describeStep).filter(Boolean), [steps]);
  const current = descriptors[index] || descriptors[descriptors.length - 1];

  if (!current) return null;

  const goto = (delta) => setIndex((i) => Math.min(descriptors.length - 1, Math.max(0, i + delta)));

  return (
    <div className="fixed inset-0 bg-black z-50 flex flex-col text-white">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-white/10">
        <button onClick={onClose} className="p-1 text-white/60 hover:text-white">
          <X className="w-5 h-5" />
        </button>
        <span className="font-semibold text-sm">{agentName}'s computer</span>
        <button className="flex items-center gap-1 px-3 py-1.5 rounded-full border border-white/15 text-xs text-white/70">
          <Monitor className="w-4 h-4" />
          <ChevronDown className="w-3 h-3" />
        </button>
      </div>

      {/* File / command viewer */}
      <div className="flex-1 overflow-hidden p-4">
        <div className="border border-white/10 rounded-xl overflow-hidden h-full flex flex-col">
          <div className="px-3 py-2 text-xs text-white/40 border-b border-white/10 font-mono truncate">
            {current.kind === "editor" ? current.path : "terminal"}
          </div>
          <div className="flex-1 overflow-auto p-4 font-mono text-xs whitespace-pre-wrap text-white/80">
            {current.kind === "editor" ? current.content : (current.command + "\n" + (current.stdout || "") + (current.stderr || ""))}
          </div>
          {current.kind === "editor" && (
            <div className="flex justify-center gap-1 p-2 border-t border-white/10">
              {["Diff", "Original", "Modified"].map((t) => (
                <button
                  key={t}
                  onClick={() => setTab(t)}
                  className={`px-3 py-1.5 rounded-full text-xs ${tab === t ? "bg-white/10 text-white" : "text-white/40"}`}
                >
                  {t}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Action caption */}
      <div className="flex items-center gap-3 px-4 py-3">
        <div className="w-9 h-9 rounded-lg bg-white/5 flex items-center justify-center shrink-0">
          {current.kind === "editor" ? <FileEdit className="w-4 h-4" /> : <Terminal className="w-4 h-4" />}
        </div>
        <div className="min-w-0">
          <div className="text-sm font-medium">{agentName} is using {current.kind === "editor" ? "Editor" : "Terminal"}</div>
          <div className="text-xs text-white/50 truncate">{current.label}</div>
        </div>
      </div>

      {/* Scrubber */}
      <div className="px-4 pb-2">
        <input
          type="range"
          min={0}
          max={Math.max(0, descriptors.length - 1)}
          value={index}
          onChange={(e) => setIndex(Number(e.target.value))}
          className="w-full accent-teal-500"
        />
      </div>

      {/* Transport controls */}
      <div className="flex items-center justify-center gap-8 pb-6">
        <button onClick={() => goto(-1)} className="p-2 text-white/60 hover:text-white">
          <SkipBack className="w-5 h-5" />
        </button>
        <span className="flex items-center gap-1.5 text-xs">
          <span className={`w-2 h-2 rounded-full ${live ? "bg-green-400" : "bg-white/30"}`} />
          {live ? "Live" : "Paused"}
        </span>
        <button onClick={() => goto(1)} className="p-2 text-white/60 hover:text-white">
          <SkipForward className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
