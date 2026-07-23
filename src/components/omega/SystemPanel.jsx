import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import { Cpu, RefreshCw, Loader2, Save, History } from "lucide-react";
import { OMEGA_IDENTITY, BASE_SYSTEM_PROMPT } from "@/lib/omega-system";

export default function SystemPanel() {
  const [prompts, setPrompts] = useState([]);
  const [activePrompt, setActivePrompt] = useState(null);
  const [editContent, setEditContent] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadPrompts();
  }, []);

  const loadPrompts = async () => {
    setLoading(true);
    const data = await base44.entities.SystemPrompt.list("-version", 20);
    setPrompts(data);
    if (data.length > 0) {
      const active = data.find((p) => p.is_active) || data[0];
      setActivePrompt(active);
      setEditContent(active.content);
    } else {
      setEditContent(BASE_SYSTEM_PROMPT);
    }
    setLoading(false);
  };

  const savePrompt = async () => {
    setSaving(true);
    if (activePrompt) {
      // Deactivate old
      await base44.entities.SystemPrompt.update(activePrompt.id, { is_active: false });
    }
    const newPrompt = await base44.entities.SystemPrompt.create({
      content: editContent,
      version: (activePrompt?.version || 0) + 1,
      is_active: true,
      improvement_notes: "Manual edit",
    });
    setActivePrompt(newPrompt);
    setPrompts((prev) => [newPrompt, ...prev]);
    setSaving(false);
  };

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-black">
        <Loader2 className="w-6 h-6 text-teal-400 animate-spin" />
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-black">
      <div className="p-4 border-b border-white/5 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Cpu className="w-5 h-5 text-teal-400" />
          <h2 className="text-white font-bold">System Core</h2>
        </div>
        <span className="text-xs font-mono text-white/20">
          v{activePrompt?.version || 1}
        </span>
      </div>

      <div className="p-4 space-y-4">
        {/* Identity card */}
        <div className="p-4 rounded-xl border border-white/5 bg-white/[0.02]">
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div>
              <p className="text-white/30 uppercase tracking-wider font-mono mb-1">Model</p>
              <p className="text-teal-400 font-mono">{OMEGA_IDENTITY.model}</p>
            </div>
            <div>
              <p className="text-white/30 uppercase tracking-wider font-mono mb-1">Creator</p>
              <p className="text-white">{OMEGA_IDENTITY.creator}</p>
            </div>
            <div>
              <p className="text-white/30 uppercase tracking-wider font-mono mb-1">Version</p>
              <p className="text-white font-mono">{OMEGA_IDENTITY.version}</p>
            </div>
            <div>
              <p className="text-white/30 uppercase tracking-wider font-mono mb-1">Prompt Version</p>
              <p className="text-white font-mono">{activePrompt?.version || 1}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 px-4 pb-4 flex flex-col min-h-0">
        <div className="flex items-center justify-between mb-2">
          <p className="text-xs text-white/30 uppercase tracking-wider font-mono">System Prompt</p>
          <button
            onClick={savePrompt}
            disabled={saving}
            className="flex items-center gap-1 text-xs text-teal-400 hover:text-teal-300 transition-colors disabled:opacity-50"
          >
            <Save className="w-3 h-3" />
            {saving ? "Saving..." : "Save New Version"}
          </button>
        </div>
        <textarea
          value={editContent}
          onChange={(e) => setEditContent(e.target.value)}
          className="flex-1 w-full bg-white/[0.02] border border-white/5 rounded-xl p-3 text-white/70 text-xs font-mono outline-none resize-none focus:border-teal-500/30 transition-colors"
        />
      </div>

      {/* Version history */}
      {prompts.length > 1 && (
        <div className="border-t border-white/5 p-4">
          <p className="text-xs text-white/30 uppercase tracking-wider font-mono mb-2 flex items-center gap-1">
            <History className="w-3 h-3" /> Previous Versions
          </p>
          <div className="space-y-1 max-h-32 overflow-y-auto">
            {prompts.filter((p) => p.id !== activePrompt?.id).map((p) => (
              <button
                key={p.id}
                onClick={() => { setActivePrompt(p); setEditContent(p.content); }}
                className="w-full text-left px-3 py-1.5 rounded-lg text-xs text-white/30 hover:text-white/60 hover:bg-white/[0.02] transition-colors font-mono"
              >
                v{p.version} — {p.improvement_notes || "No notes"}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}