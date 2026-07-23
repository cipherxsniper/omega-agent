import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import { RefreshCw, CheckCircle, XCircle, Clock, Loader2, ListTodo } from "lucide-react";

export default function JobsPanel({ onClose }) {
  const [jobs, setJobs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadJobs();
  }, []);

  const loadJobs = async () => {
    setLoading(true);
    const data = await base44.entities.Job.list("-created_date", 50);
    setJobs(data);
    setLoading(false);
  };

  const statusIcon = {
    queued: <Clock className="w-4 h-4 text-white/40" />,
    running: <Loader2 className="w-4 h-4 text-teal-400 animate-spin" />,
    completed: <CheckCircle className="w-4 h-4 text-green-400" />,
    failed: <XCircle className="w-4 h-4 text-red-400" />,
  };

  const statusColor = {
    queued: "border-white/10",
    running: "border-teal-500/30",
    completed: "border-green-500/20",
    failed: "border-red-500/20",
  };

  return (
    <div className="h-full flex flex-col bg-black">
      <div className="p-4 border-b border-white/5 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <ListTodo className="w-5 h-5 text-teal-400" />
          <h2 className="text-white font-bold">Job Queue</h2>
        </div>
        <button onClick={loadJobs} className="text-white/30 hover:text-white/60 transition-colors">
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-6 h-6 text-teal-400 animate-spin" />
          </div>
        ) : jobs.length === 0 ? (
          <div className="text-center py-12">
            <ListTodo className="w-8 h-8 text-white/10 mx-auto mb-3" />
            <p className="text-white/30 text-sm">No jobs yet</p>
            <p className="text-white/15 text-xs mt-1">Omega creates jobs automatically during tasks</p>
          </div>
        ) : (
          jobs.map((job) => (
            <motion.div
              key={job.id}
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              className={`p-3 rounded-xl border ${statusColor[job.status]} bg-white/[0.02]`}
            >
              <div className="flex items-start gap-3">
                <div className="mt-0.5">{statusIcon[job.status]}</div>
                <div className="flex-1 min-w-0">
                  <p className="text-white text-sm font-medium truncate">{job.title}</p>
                  {job.description && (
                    <p className="text-white/30 text-xs mt-0.5 line-clamp-2">{job.description}</p>
                  )}
                  <div className="flex items-center gap-2 mt-2">
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-white/5 text-white/40 uppercase tracking-wider font-mono">
                      {job.type}
                    </span>
                    <span className="text-[10px] text-white/20 font-mono">{job.status}</span>
                  </div>
                  {job.status === "running" && (
                    <div className="mt-2 w-full h-1 bg-white/5 rounded-full overflow-hidden">
                      <motion.div
                        className="h-full bg-teal-400"
                        animate={{ width: `${job.progress}%` }}
                      />
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}