import { useState, useRef, useCallback } from "react";

const BACKEND = import.meta.env.VITE_AGENT_BACKEND_URL || "https://omega-agent-backend-v2.onrender.com";

// Starts a background job, streams its steps live via SSE, and exposes
// state for SandboxPanel to render. Falls back to polling /api/job/<id>
// if the EventSource connection drops, since Render/Cloudflare tunnels
// can kill idle SSE connections despite the heartbeat comments.
export function useSandboxStream() {
  const [steps, setSteps] = useState([]);
  const [jobId, setJobId] = useState(null);
  const [status, setStatus] = useState("idle"); // idle | queued | running | done | failed
  const esRef = useRef(null);

  const stop = useCallback(() => {
    if (esRef.current) {
      esRef.current.close();
      esRef.current = null;
    }
  }, []);

  const start = useCallback(async (message, maxSteps = 100) => {
    setSteps([]);
    setStatus("queued");

    const res = await fetch(`${BACKEND}/api/job/start`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message, max_steps: maxSteps }),
    });
    const data = await res.json();
    if (!data.job_id) {
      setStatus("failed");
      return null;
    }
    setJobId(data.job_id);

    stop(); // close any prior stream first
    const es = new EventSource(`${BACKEND}/api/job/stream/${data.job_id}`);
    esRef.current = es;
    setStatus("running");

    es.onmessage = (evt) => {
      const payload = JSON.parse(evt.data);
      if (payload.done) {
        setStatus((s) => (s === "failed" ? s : "done"));
        stop();
        return;
      }
      setSteps((prev) => [...prev, payload]);
    };

    es.onerror = () => {
      // EventSource auto-reconnects on transient errors; only treat it as
      // failed if the job itself already reported failure via polling.
      fetch(`${BACKEND}/api/job/${data.job_id}`)
        .then((r) => r.json())
        .then((job) => {
          if (job.status === "failed" || job.status === "done") {
            setStatus(job.status);
            setSteps(job.transcript || []);
            stop();
          }
        })
        .catch(() => {});
    };

    return data.job_id;
  }, [stop]);

  return { steps, jobId, status, start, stop, isLive: status === "running" || status === "queued" };
}
