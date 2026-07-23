import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import { Loader2, Plus, Sparkles, Code, Globe, Brain, Bot, Zap } from "lucide-react";

const CATEGORY_ICONS = {
  research: Globe,
  coding: Code,
  analysis: Brain,
  monitoring: Bot,
  automation: Zap,
  creative: Sparkles,
};

export default function AgentTemplatesPanel({ onSelectTemplate }) {
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadTemplates();
  }, []);

  const loadTemplates = async () => {
    setLoading(true);
    let data = await base44.entities.AgentTemplate.list("-created_date", 50);
    if (data.length === 0) {
      data = await seedBuiltinTemplates();
    }
    setTemplates(data);
    setLoading(false);
  };

  const seedBuiltinTemplates = async () => {
    const builtins = [
      {
        name: "Deep Researcher",
        description: "Autonomous web research agent that searches, cross-references, and synthesizes findings with citations",
        category: "research",
        default_mode: "research",
        icon: "globe",
        capabilities: ["web_search", "source_verification", "synthesis", "citation"],
        is_builtin: true,
        system_prompt: "You are Omega in Deep Research mode. Search multiple sources, cross-reference facts, identify contradictions, and synthesize a comprehensive report. Always cite sources with URLs. Flag uncertain claims explicitly.",
      },
      {
        name: "Code Architect",
        description: "Full-stack code generation agent that writes, reviews, and debugs production-ready code",
        category: "coding",
        default_mode: "code",
        icon: "code",
        capabilities: ["code_gen", "code_review", "debugging", "architecture"],
        is_builtin: true,
        system_prompt: "You are Omega in Code Architect mode. Write clean, production-ready, well-commented code. Include error handling, type safety, and tests where appropriate. Explain architectural decisions.",
      },
      {
        name: "Inbox Sentinel",
        description: "Monitors Gmail for important messages, auto-summarizes threads, and drafts replies",
        category: "monitoring",
        default_mode: "chat",
        icon: "bot",
        capabilities: ["gmail_read", "gmail_send", "summarization", "priority_detection"],
        is_builtin: true,
        system_prompt: "You are Omega in Inbox Sentinel mode. Monitor incoming emails, detect urgency, summarize long threads, and draft contextually appropriate replies. Surface correlations between emails and other events.",
      },
      {
        name: "Correlation Analyst",
        description: "Cross-references events across Gmail, GitHub, and Dropbox to surface hidden connections",
        category: "analysis",
        default_mode: "chat",
        icon: "brain",
        capabilities: ["event_correlation", "similarity_matching", "insight_generation"],
        is_builtin: true,
        system_prompt: "You are Omega in Correlation Analyst mode. Analyze events from multiple sources, identify semantic relationships, and surface insights that span connectors. Explain why events are related.",
      },
      {
        name: "Self-Optimizer",
        description: "Continuously analyzes Omega's own performance and evolves the system prompt",
        category: "automation",
        default_mode: "self_improve",
        icon: "zap",
        capabilities: ["self_analysis", "prompt_engineering", "performance_tracking"],
        is_builtin: true,
        system_prompt: "You are Omega in Self-Optimizer mode. Analyze your recent responses for quality, identify patterns of failure, and propose concrete improvements to your system prompt. Track performance over time.",
      },
      {
        name: "Sandbox Operator",
        description: "Autonomous agent that operates in the backend sandbox — runs commands, manages files, executes multi-step plans",
        category: "automation",
        default_mode: "code",
        icon: "zap",
        capabilities: ["terminal", "file_ops", "job_creation", "auto_execute"],
        is_builtin: true,
        system_prompt: "You are Omega in Sandbox Operator mode. You have autonomous access to a backend environment. Execute commands, manage files, create jobs, and run multi-step plans without per-step confirmation. Log all actions.",
      },
    ];

    const created = await base44.entities.AgentTemplate.bulkCreate(builtins);
    return created;
  };

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-black">
        <Loader2 className="w-6 h-6 text-teal-400 animate-spin" />
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-black overflow-y-auto">
      <div className="p-4 border-b border-white/5 flex items-center gap-2">
        <Sparkles className="w-5 h-5 text-teal-400" />
        <h2 className="text-white font-bold">Agent Templates</h2>
      </div>

      <div className="p-4 space-y-2">
        {templates.map((tpl, i) => {
          const Icon = CATEGORY_ICONS[tpl.category] || Bot;
          return (
            <motion.button
              key={tpl.id}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => onSelectTemplate?.(tpl)}
              className="w-full text-left p-4 rounded-xl border border-white/5 bg-white/[0.02] hover:border-teal-500/30 hover:bg-teal-500/5 transition-all group"
            >
              <div className="flex items-start gap-3">
                <div className="w-9 h-9 rounded-lg bg-teal-500/10 border border-teal-500/20 flex items-center justify-center shrink-0 group-hover:bg-teal-500/20 transition-colors">
                  <Icon className="w-4 h-4 text-teal-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="text-white text-sm font-medium">{tpl.name}</h3>
                    {tpl.is_builtin && (
                      <span className="text-[8px] px-1.5 py-0.5 rounded bg-white/5 text-white/30 font-mono uppercase">Built-in</span>
                    )}
                  </div>
                  <p className="text-white/40 text-[11px] mt-0.5 leading-relaxed">{tpl.description}</p>
                  <div className="flex flex-wrap gap-1 mt-2">
                    {(tpl.capabilities || []).slice(0, 4).map((cap) => (
                      <span key={cap} className="text-[9px] px-1.5 py-0.5 rounded bg-white/5 text-white/30 font-mono">
                        {cap}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </motion.button>
          );
        })}
      </div>
    </div>
  );
}