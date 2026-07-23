import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import { Mail, Github, Box, Check, Loader2, AlertCircle, ArrowRight } from "lucide-react";

export default function ConnectorsPanel({ onNavigate }) {
  const [gmailStatus, setGmailStatus] = useState("checking");
  const [githubConfig, setGithubConfig] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkConnections();
  }, []);

  const checkConnections = async () => {
    setLoading(true);

    // Check Gmail
    try {
      await base44.functions.invoke("gmailActions", { action: "list", max: 1 });
      setGmailStatus("connected");
    } catch {
      setGmailStatus("disconnected");
    }

    // Check GitHub
    try {
      const configs = await base44.entities.GitHubSync.list("-created_date", 1);
      setGithubConfig(configs[0] || null);
    } catch {
      setGithubConfig(null);
    }

    setLoading(false);
  };

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-black">
        <Loader2 className="w-6 h-6 text-teal-400 animate-spin" />
      </div>
    );
  }

  const connectors = [
    {
      id: "gmail",
      name: "Gmail",
      icon: Mail,
      type: "OAuth · Shared",
      connected: gmailStatus === "connected",
      statusText: gmailStatus === "connected" ? "Connected" : "Not Connected",
      action: null,
    },
    {
      id: "github",
      name: "GitHub",
      icon: Github,
      type: "PAT Token Sync",
      connected: !!githubConfig,
      statusText: githubConfig?.sync_status === "success" ? "Synced" : githubConfig ? "Configured" : "Not Connected",
      action: () => onNavigate?.("github"),
      actionLabel: "Open Sync Panel",
    },
    {
      id: "dropbox",
      name: "Dropbox",
      icon: Box,
      type: "OAuth · App User",
      connected: false,
      statusText: "Setup Required",
      action: null,
      actionLabel: null,
    },
  ];

  return (
    <div className="h-full flex flex-col bg-black">
      <div className="p-4 border-b border-white/5 flex items-center gap-2">
        <Box className="w-5 h-5 text-teal-400" />
        <h2 className="text-white font-bold">Connectors</h2>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {connectors.map((c, i) => {
          const Icon = c.icon;
          return (
            <motion.div
              key={c.id}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="p-4 rounded-xl border border-white/5 bg-white/[0.02] space-y-3"
            >
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${
                  c.connected ? "bg-teal-500/10 border border-teal-500/20" : "bg-white/5 border border-white/10"
                }`}>
                  <Icon className={`w-5 h-5 ${c.connected ? "text-teal-400" : "text-white/30"}`} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-white text-sm font-medium">{c.name}</p>
                  <p className="text-white/30 text-xs">{c.type}</p>
                </div>
                <div className={`flex items-center gap-1.5 px-2 py-1 rounded-full text-xs shrink-0 ${
                  c.connected
                    ? "bg-teal-500/10 text-teal-400"
                    : "bg-white/5 text-white/30"
                }`}>
                  {c.connected ? (
                    <Check className="w-3 h-3" />
                  ) : (
                    <AlertCircle className="w-3 h-3" />
                  )}
                  {c.statusText}
                </div>
              </div>
              {c.action && c.actionLabel && (
                <button
                  onClick={c.action}
                  className="w-full py-2 rounded-lg bg-white/5 border border-white/10 text-white/70 text-xs hover:bg-white/10 hover:text-white transition-colors flex items-center justify-center gap-1.5"
                >
                  {c.actionLabel}
                  <ArrowRight className="w-3 h-3" />
                </button>
              )}
            </motion.div>
          );
        })}

        <div className="p-3 rounded-xl border border-white/5 bg-white/[0.01]">
          <p className="text-xs text-white/30 leading-relaxed">
            Gmail is connected via OAuth. GitHub uses a Personal Access Token for two-way code sync. Dropbox requires OAuth setup — ask in chat to connect it.
          </p>
        </div>
      </div>
    </div>
  );
}