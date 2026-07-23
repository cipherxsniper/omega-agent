import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import { Brain, Trash2, Loader2, Star } from "lucide-react";

const CATEGORY_COLORS = {
  fact: "bg-blue-500/10 text-blue-400 border-blue-500/20",
  preference: "bg-purple-500/10 text-purple-400 border-purple-500/20",
  context: "bg-teal-500/10 text-teal-400 border-teal-500/20",
  skill: "bg-amber-500/10 text-amber-400 border-amber-500/20",
  self_improvement: "bg-green-500/10 text-green-400 border-green-500/20",
};

export default function MemoryPanel() {
  const [memories, setMemories] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMemories();
  }, []);

  const loadMemories = async () => {
    setLoading(true);
    const data = await base44.entities.Memory.list("-importance", 100);
    setMemories(data);
    setLoading(false);
  };

  const deleteMemory = async (id) => {
    await base44.entities.Memory.delete(id);
    setMemories((prev) => prev.filter((m) => m.id !== id));
  };

  return (
    <div className="h-full flex flex-col bg-black">
      <div className="p-4 border-b border-white/5 flex items-center gap-2">
        <Brain className="w-5 h-5 text-teal-400" />
        <h2 className="text-white font-bold">Context Memory</h2>
        <span className="ml-auto text-xs text-white/20 font-mono">{memories.length} memories</span>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-6 h-6 text-teal-400 animate-spin" />
          </div>
        ) : memories.length === 0 ? (
          <div className="text-center py-12">
            <Brain className="w-8 h-8 text-white/10 mx-auto mb-3" />
            <p className="text-white/30 text-sm">No memories stored</p>
            <p className="text-white/15 text-xs mt-1">Omega learns and remembers as you chat</p>
          </div>
        ) : (
          memories.map((mem) => (
            <motion.div
              key={mem.id}
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-3 rounded-xl border border-white/5 bg-white/[0.02] group"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <p className="text-white text-sm font-medium">{mem.key}</p>
                  <p className="text-white/40 text-xs mt-1">{mem.value}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className={`text-[10px] px-2 py-0.5 rounded-full border ${CATEGORY_COLORS[mem.category]} uppercase tracking-wider font-mono`}>
                      {mem.category}
                    </span>
                    <div className="flex items-center gap-0.5">
                      {Array.from({ length: Math.min(mem.importance || 5, 10) }).map((_, i) => (
                        <Star key={i} className="w-2.5 h-2.5 text-teal-400/40 fill-teal-400/40" />
                      ))}
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => deleteMemory(mem.id)}
                  className="text-white/10 hover:text-red-400 transition-colors opacity-0 group-hover:opacity-100"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}