import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import {
  Github, RefreshCw, CheckCircle, XCircle, Loader2,
  Download, Upload, Save, Link as LinkIcon, GitBranch,
} from "lucide-react";

const STATUS_ICON = {
  idle: <Github className="w-4 h-4 text-white/40" />,
  syncing: <Loader2 className="w-4 h-4 text-teal-400 animate-spin" />,
  success: <CheckCircle className="w-4 h-4 text-green-400" />,
  error: <XCircle className="w-4 h-4 text-red-400" />,
};

const STATUS_COLOR = {
  idle: "border-white/10",
  syncing: "border-teal-500/30",
  success: "border-green-500/20",
  error: "border-red-500/20",
};

export default function GitHubPanel() {
  const [record, setRecord] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [busyAction, setBusyAction] = useState(null);
  const [pulledFiles, setPulledFiles] = useState(null);
  const [localError, setLocalError] = useState("");

  const [repoUrl, setRepoUrl] = useState("");
  const [patToken, setPatToken] = useState("");
  const [branch, setBranch] = useState("main");
  const [autoSync, setAutoSync] = useState(false);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    setLoading(true);
    try {
      const rows = await base44.entities.GitHubSync.list("-created_date", 1);
      const existing = rows && rows.length > 0 ? rows[0] : null;
      setRecord(existing);
      if (existing) {
        setRepoUrl(existing.repo_url || "");
        setPatToken(existing.pat_token || "");
        setBranch(existing.branch || "main");
        setAutoSync(!!existing.auto_sync);
      }
    } finally {
      setLoading(false);
    }
  };

  const saveConfig = async () => {
    setLocalError("");
    if (!repoUrl || !patToken) {
      setLocalError("Repo URL and PAT token are required.");
      return;
    }
    setSaving(true);
    try {
      const payload = {
        repo_url: repoUrl,
        pat_token: patToken,
        branch: branch || "main",
        auto_sync: autoSync,
      };
      let updated;
      if (record) {
        updated = await base44.entities.GitHubSync.update(record.id, payload);
      } else {
        updated = await base44.entities.GitHubSync.create({
          ...payload,
          sync_status: "idle",
        });
      }
      setRecord(updated);
    } catch (err) {
      setLocalError(err.message || "Failed to save config");
    } finally {
      setSaving(false);
    }
  };

  const setStatus = async (updates) => {
    if (!record) return;
    const updated = await base44.entities.GitHubSync.update(record.id, updates);
    setRecord(updated);
  };

  const runPull = async () => {
    if (!record) {
      setLocalError("Save your config first.");
      return;
    }
    setLocalError("");
    setBusyAction("pull");
    setPulledFiles(null);
    await setStatus({ sync_status: "syncing" });
    try {
      const res = await base44.functions.invoke("githubSync", {
        action: "pull",
        repo_url: repoUrl,
        pat_token: patToken,
        branch,
      });
      const data = res.data || res;
      if (data.error) {
        await setStatus({ sync_status: "error", error_message: data.error });
        setLocalError(data.error);
      } else {
        setPulledFiles(data.files || []);
        await setStatus({
          sync_status: "success",
          last_sync_at: new Date().toISOString(),
          error_message: "",
        });
      }
    } catch (err) {
      await setStatus({ sync_status: "error", error_message: err.message });
      setLocalError(err.message || "Pull failed");
    } finally {
      setBusyAction(null);
    }
  };

  const runPush = async () => {
    if (!record) {
      setLocalError("Save your config first.");
      return;
    }
    setLocalError("");
    setBusyAction("push");
    await setStatus({ sync_status: "syncing" });
    try {
      const steps = await base44.entities.AgentStep.filter({ tool: "editor" }, "-created_date", 50);
      const files = steps
        .filter((s) => s.title && s.tool_output)
        .map((s) => ({ path: s.title, content: s.tool_output }));

      if (files.length === 0) {
        setLocalError("No generated files found to push yet.");
        await setStatus({ sync_status: "idle" });
        return;
      }

      const res = await base44.functions.invoke("githubSync", {
        action: "push",
        repo_url: repoUrl,
        pat_token: patToken,
        branch,
        files,
      });
      const data = res.data || res;
      if (data.error) {
        await setStatus({ sync_status: "error", error_message: data.error });
        setLocalError(data.error);
      } else {
        await setStatus({
          sync_status: "success",
          last_sync_at: new Date().toISOString(),
          error_message: "",
        });
      }
    } catch (err) {
      await setStatus({ sync_status: "error", error_message: err.message });
      setLocalError(err.message || "Push failed");
    } finally {
      setBusyAction(null);
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
    <div className="h-full flex flex-col bg-black">
      <div className="p-4 border-b border-white/5 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Github className="w-5 h-5 text-teal-400" />
          <h2 className="text-white font-bold">GitHub Sync</h2>
        </div>
        {record && (
          <div className={`flex items-center gap-1.5 px-2 py-1 rounded-full border ${STATUS_COLOR[record.sync_status || "idle"]}`}>
            {STATUS_ICON[record.sync_status || "idle"]}
            <span className="text-[10px] text-white/50 uppercase tracking-wider font-mono">
              {record.sync_status || "idle"}
            </span>
          </div>
        )}
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <div className="space-y-2">
          <label className="text-white/50 text-xs flex items-center gap-1.5">
            <LinkIcon className="w-3 h-3" /> Repository URL
          </label>
          <input
            type="text"
            value={repoUrl}
            onChange={(e) => setRepoUrl(e.target.value)}
            placeholder="https://github.com/owner/repo"
            className="w-full bg-white/[0.03] border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder-white/20 focus:outline-none focus:border-teal-500/40"
          />
        </div>

        <div className="space-y-2">
          <label className="text-white/50 text-xs">Personal Access Token</label>
          <input
            type="password"
            value={patToken}
            onChange={(e) => setPatToken(e.target.value)}
            placeholder="ghp_xxxxxxxxxxxx"
            className="w-full bg-white/[0.03] border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder-white/20 focus:outline-none focus:border-teal-500/40"
          />
        </div>

        <div className="space-y-2">
          <label className="text-white/50 text-xs flex items-center gap-1.5">
            <GitBranch className="w-3 h-3" /> Branch
          </label>
          <input
            type="text"
            value={branch}
            onChange={(e) => setBranch(e.target.value)}
            placeholder="main"
            className="w-full bg-white/[0.03] border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder-white/20 focus:outline-none focus:border-teal-500/40"
          />
        </div>

        <label className="flex items-center gap-2 text-white/50 text-xs cursor-pointer">
          <input
            type="checkbox"
            checked={autoSync}
            onChange={(e) => setAutoSync(e.target.checked)}
            className="accent-teal-400"
          />
          Auto-sync after each task
        </label>

        {localError && (
          <div className="p-2.5 rounded-lg bg-red-500/10 border border-red-500/20 text-red-300 text-xs">
            {localError}
          </div>
        )}

        {record?.last_sync_at && (
          <p className="text-white/20 text-[10px] font-mono">
            Last sync: {new Date(record.last_sync_at).toLocaleString()}
          </p>
        )}

        <button
          onClick={saveConfig}
          disabled={saving}
          className="w-full flex items-center justify-center gap-2 py-2 rounded-lg bg-teal-500/10 border border-teal-500/20 text-teal-300 text-sm hover:bg-teal-500/20 transition-colors disabled:opacity-50"
        >
          {saving ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Save className="w-3.5 h-3.5" />}
          Save Config
        </button>

        <div className="grid grid-cols-2 gap-2 pt-2">
          <button
            onClick={runPull}
            disabled={busyAction !== null}
            className="flex items-center justify-center gap-1.5 py-2 rounded-lg border border-white/10 text-white/60 text-xs hover:border-teal-500/30 hover:text-white transition-colors disabled:opacity-50"
          >
            {busyAction === "pull" ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Download className="w-3.5 h-3.5" />}
            Pull
          </button>
          <button
            onClick={runPush}
            disabled={busyAction !== null}
            className="flex items-center justify-center gap-1.5 py-2 rounded-lg border border-white/10 text-white/60 text-xs hover:border-teal-500/30 hover:text-white transition-colors disabled:opacity-50"
          >
            {busyAction === "push" ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Upload className="w-3.5 h-3.5" />}
            Push
          </button>
        </div>

        {pulledFiles && (
          <div className="pt-2 space-y-1">
            <p className="text-white/30 text-[10px] uppercase tracking-wider font-mono">
              {pulledFiles.length} files in {branch}
            </p>
            {pulledFiles.slice(0, 30).map((f) => (
              <motion.div
                key={f.sha}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="text-[11px] text-white/40 font-mono truncate"
              >
                {f.path}
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
