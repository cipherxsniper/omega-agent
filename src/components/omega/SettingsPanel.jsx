import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import {
  Cpu, Loader2, Terminal, Shield, Bell, Link2, Link2Off,
  CheckCircle, XCircle, Power, Zap,
} from "lucide-react";

export default function SettingsPanel() {
  const [sandboxEnabled, setSandboxEnabled] = useState(false);
  const [sandboxSession, setSandboxSession] = useState(null);
  const [gmailConnected, setGmailConnected] = useState(false);
  const [githubConnected, setGithubConnected] = useState(false);
  const [dropboxConnected, setDropboxConnected] = useState(false);
  const [checkingGmail, setCheckingGmail] = useState(true);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSettings();
    checkGmail();
  }, []);

  const loadSettings = async () => {
    const sessions = await base44.entities.SandboxSession.list("-created_date", 1);
    if (sessions.length > 0) {
      setSandboxSession(sessions[0]);
      setSandboxEnabled(sessions[0].status === "active");
    }
    setLoading(false);
  };

  const checkGmail = async () => {
    try {
      await base44.functions.invoke("gmailActions", { action: "list", max: 1 });
      setGmailConnected(true);
    } catch {
      setGmailConnected(false);
    }
    setCheckingGmail(false);
  };

  const toggleSandbox = async () => {
    const newStatus = sandboxEnabled ? "idle" : "active";
    setSandboxEnabled(!sandboxEnabled);
    if (sandboxSession) {
      const updated = await base44.entities.SandboxSession.update(sandboxSession.id, {
        status: newStatus,
        auto_execute: !sandboxEnabled,
        capabilities: !sandboxEnabled
          ? ["terminal", "file_ops", "job_creation", "web_research", "code_execution"]
          : [],
      });
      setSandboxSession(updated);
    } else {
      const session = await base44.entities.SandboxSession.create({
        status: newStatus,
        auto_execute: !sandboxEnabled,
        capabilities: !sandboxEnabled
          ? ["terminal", "file_ops", "job_creation", "web_research", "code_execution"]
          : [],
      });
      setSandboxSession(session);
    }
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
        <Cpu className="w-5 h-5 text-teal-400" />
        <h2 className="text-white font-bold">Settings</h2>
      </div>

      <div className="p-4 space-y-4">
        {/* Sandbox Environment Toggle */}
        <div className="p-4 rounded-xl border border-white/5 bg-white/[0.02]">
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-2">
              <Terminal className="w-4 h-4 text-teal-400" />
              <div>
                <h3 className="text-white text-sm font-medium">Sandbox Environment</h3>
                <p className="text-white/30 text-[11px] mt-0.5">
                  Connect Omega to its own autonomous backend environment
                </p>
              </div>
            </div>
            <button
              onClick={toggleSandbox}
              className={`relative w-11 h-6 rounded-full transition-colors ${
                sandboxEnabled ? "bg-teal-500" : "bg-white/10"
              }`}
            >
              <motion.div
                animate={{ x: sandboxEnabled ? 22 : 2 }}
                transition={{ type: "spring", stiffness: 500, damping: 30 }}
                className="absolute top-0.5 w-5 h-5 rounded-full bg-white"
              />
            </button>
          </div>
          {sandboxEnabled ? (
            <div className="space-y-2">
              <div className="flex items-center gap-1.5">
                <Power className="w-3 h-3 text-teal-400" />
                <span className="text-[11px] text-teal-400 font-mono">SANDBOX ACTIVE</span>
              </div>
              <div className="flex flex-wrap gap-1">
                {(sandboxSession?.capabilities || []).map((cap) => (
                  <span key={cap} className="text-[9px] px-1.5 py-0.5 rounded bg-teal-500/10 text-teal-400 font-mono">
                    {cap}
                  </span>
                ))}
              </div>
              <p className="text-[10px] text-white/20 mt-1">
                Omega can autonomously execute commands, manage files, create jobs, and run multi-step plans without per-step confirmation.
              </p>
            </div>
          ) : (
            <p className="text-[10px] text-white/20">
              When enabled, Omega operates in an autonomous backend sandbox — executing commands, managing files, and running multi-step plans independently.
            </p>
          )}
        </div>

        {/* Connectors */}
        <div>
          <p className="text-[10px] text-white/30 uppercase tracking-wider font-mono mb-2 flex items-center gap-1">
            <Link2 className="w-3 h-3" /> Connectors
          </p>
          <div className="space-y-2">
            <ConnectorRow
              name="Gmail"
              icon="✉"
              connected={gmailConnected}
              checking={checkingGmail}
              scopes="read + send"
            />
            <ConnectorRow
              name="GitHub"
              icon="🐙"
              connected={githubConnected}
              checking={false}
              scopes="repo, issues, checks"
              note="Not connected — request access in chat"
            />
            <ConnectorRow
              name="Dropbox"
              icon="📁"
              connected={dropboxConnected}
              checking={false}
              scopes="files read + write"
              note="Not connected — request access in chat"
            />
          </div>
        </div>

        {/* Verification */}
        <div className="p-4 rounded-xl border border-white/5 bg-white/[0.02]">
          <div className="flex items-center gap-2 mb-2">
            <Shield className="w-4 h-4 text-teal-400" />
            <h3 className="text-white text-sm font-medium">Response Verification</h3>
          </div>
          <p className="text-[11px] text-white/30">
            Every multi-step response is audited before delivery: factual claims are traced to context, reasoning steps are checked for logical validity, and completeness is verified. Failed checks trigger automatic re-processing.
          </p>
          <div className="flex items-center gap-1.5 mt-2">
            <CheckCircle className="w-3 h-3 text-teal-400" />
            <span className="text-[10px] text-teal-400 font-mono">ALWAYS ON</span>
          </div>
        </div>

        {/* Smart Notifications */}
        <div className="p-4 rounded-xl border border-white/5 bg-white/[0.02]">
          <div className="flex items-center gap-2 mb-2">
            <Bell className="w-4 h-4 text-teal-400" />
            <h3 className="text-white text-sm font-medium">Smart Notifications</h3>
          </div>
          <p className="text-[11px] text-white/30">
            Event-driven alerts from connected sources. Gmail push notifications are live; GitHub and Dropbox use scheduled polling. Each rule has deduplication to prevent duplicate alerts.
          </p>
        </div>

        {/* Correlation Engine */}
        <div className="p-4 rounded-xl border border-white/5 bg-white/[0.02]">
          <div className="flex items-center gap-2 mb-2">
            <Zap className="w-4 h-4 text-teal-400" />
            <h3 className="text-white text-sm font-medium">Cross-Connector Correlation</h3>
          </div>
          <p className="text-[11px] text-white/30">
            Events from Gmail, GitHub, and Dropbox are embedded and compared for semantic similarity. Auto-links above 0.8; surfaces 0.6–0.8 as "possibly related" for confirmation.
          </p>
        </div>
      </div>
    </div>
  );
}

function ConnectorRow({ name, icon, connected, checking, scopes, note }) {
  return (
    <div className="flex items-center justify-between p-3 rounded-lg border border-white/5 bg-white/[0.02]">
      <div className="flex items-center gap-2">
        <span className="text-lg">{icon}</span>
        <div>
          <p className="text-white/70 text-xs font-medium">{name}</p>
          <p className="text-white/20 text-[10px]">{scopes}</p>
        </div>
      </div>
      {checking ? (
        <Loader2 className="w-3.5 h-3.5 text-white/30 animate-spin" />
      ) : connected ? (
        <div className="flex items-center gap-1">
          <CheckCircle className="w-3.5 h-3.5 text-teal-400" />
          <span className="text-[10px] text-teal-400 font-mono">CONNECTED</span>
        </div>
      ) : (
        <div>
          <div className="flex items-center gap-1">
            <XCircle className="w-3.5 h-3.5 text-white/20" />
            <span className="text-[10px] text-white/30 font-mono">OFFLINE</span>
          </div>
          {note && <p className="text-[9px] text-white/15 mt-0.5">{note}</p>}
        </div>
      )}
    </div>
  );
}