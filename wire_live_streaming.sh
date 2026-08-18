#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=~/omega-agent-v2
TS=$(date +%s)

cp "$FRONTEND/src/lib/localEntities.js" "$FRONTEND/src/lib/localEntities.js.bak_$TS"
cp "$FRONTEND/src/pages/Home.jsx" "$FRONTEND/src/pages/Home.jsx.bak_$TS"
cp "$FRONTEND/src/components/omega/WorkspacePanel.jsx" "$FRONTEND/src/components/omega/WorkspacePanel.jsx.bak_$TS"

python3 - << 'PYEOF'
base = "/data/data/com.termux/files/home/omega-agent-v2"

# ---------- 1. localEntities.js: add streaming path ----------
path = f"{base}/src/lib/localEntities.js"
with open(path) as f:
    c = f.read()

old = '''const callAgentBackend = async ({ prompt }) => {
  try {
    const res = await fetch(`${AGENT_BACKEND_URL}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: prompt }),
    });

    if (!res.ok) {
      const err = await res.text();
      return { data: { error: `Agent backend error: ${err}` } };
    }

    const json = await res.json();
    return { data: { result: json.response, transcript: json.transcript } };
  } catch (e) {
    return { data: { error: `Could not reach agent backend at ${AGENT_BACKEND_URL}: ${e.message}` } };
  }
};

export const functions = {
  invoke: async (fnName, payload) => {
    if (fnName === "groqComplete") {
      return callAgentBackend(payload || {});
    }
    console.warn(`[local mode] functions.invoke("${fnName}") skipped — no backend connected.`);
    return { data: { error: `Function "${fnName}" is not available in local mode.` } };
  },
};'''

new = '''const callAgentBackend = async ({ prompt }) => {
  try {
    const res = await fetch(`${AGENT_BACKEND_URL}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: prompt }),
    });

    if (!res.ok) {
      const err = await res.text();
      return { data: { error: `Agent backend error: ${err}` } };
    }

    const json = await res.json();
    return { data: { result: json.response, transcript: json.transcript } };
  } catch (e) {
    return { data: { error: `Could not reach agent backend at ${AGENT_BACKEND_URL}: ${e.message}` } };
  }
};

// Live-streaming path — uses the job/start + job/stream SSE pipeline so the
// caller gets each transcript step as it happens (for driving WorkspacePanel
// in real time) instead of waiting for the whole task to finish.
const streamAgentBackend = ({ prompt, onStep }) => {
  return new Promise(async (resolve) => {
    try {
      const startRes = await fetch(`${AGENT_BACKEND_URL}/api/job/start`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: prompt }),
      });
      if (!startRes.ok) {
        const err = await startRes.text();
        resolve({ data: { error: `Agent backend error: ${err}` } });
        return;
      }
      const { job_id } = await startRes.json();
      if (!job_id) {
        resolve({ data: { error: "Agent backend did not return a job_id" } });
        return;
      }

      const transcript = [];
      const es = new EventSource(`${AGENT_BACKEND_URL}/api/job/stream/${job_id}`);

      es.onmessage = (event) => {
        const step = JSON.parse(event.data);
        if (step.done) {
          es.close();
          const finalEntry = [...transcript].reverse().find((e) => e.final);
          const finalText = finalEntry ? finalEntry.content : "(no final response — see transcript)";
          resolve({ data: { result: finalText, transcript } });
          return;
        }
        transcript.push(step);
        if (onStep) onStep(step);
      };

      es.onerror = () => {
        es.close();
        resolve({ data: { error: "Lost connection to agent backend stream." } });
      };
    } catch (e) {
      resolve({ data: { error: `Could not reach agent backend at ${AGENT_BACKEND_URL}: ${e.message}` } });
    }
  });
};

export const functions = {
  invoke: async (fnName, payload) => {
    if (fnName === "groqComplete") {
      const p = payload || {};
      if (p.onStep) {
        const { onStep, ...rest } = p;
        return streamAgentBackend({ ...rest, onStep });
      }
      return callAgentBackend(p);
    }
    console.warn(`[local mode] functions.invoke("${fnName}") skipped — no backend connected.`);
    return { data: { error: `Function "${fnName}" is not available in local mode.` } };
  },
};'''

n = c.count(old)
print(f"localEntities.js matches: {n}")
if n == 1:
    with open(path, "w") as f:
        f.write(c.replace(old, new))
    print("localEntities.js patched")
else:
    print("ABORTED localEntities.js — expected exactly 1 match")

# ---------- 2. Home.jsx: add liveTranscript state, wire onStep, feed panel ----------
path = f"{base}/src/pages/Home.jsx"
with open(path) as f:
    c = f.read()

old1 = '  const messagesEndRef = useRef(null);'
new1 = '  const messagesEndRef = useRef(null);\n  const [liveTranscript, setLiveTranscript] = useState([]);'
n1 = c.count(old1)

old2 = '''    setMessages((prev) => [...prev, userMsg]);
    setIsThinking(true);

    const startTime = Date.now();'''
new2 = '''    setMessages((prev) => [...prev, userMsg]);
    setIsThinking(true);
    setLiveTranscript([]);

    const startTime = Date.now();'''
n2 = c.count(old2)

old3 = '''      response = await base44.functions.invoke("groqComplete", {
        prompt: userPrompt,
        add_context_from_internet: true,
        response_json_schema: {
          type: "object",
          properties: {
            reasoning: { type: "string" },
            response: { type: "string" },
            sources: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  title: { type: "string" },
                  url: { type: "string" },
                  snippet: { type: "string" },
                },
              },
            },
          },
        },
      });
      response = response.data || response;
    } else {
      response = await base44.functions.invoke("groqComplete", {
        prompt: userPrompt,
        response_json_schema: {
          type: "object",
          properties: {
            reasoning: { type: "string" },
            response: { type: "string" },
          },
        },
      });
      response = response.data || response;
    }'''
new3 = '''      response = await base44.functions.invoke("groqComplete", {
        prompt: userPrompt,
        add_context_from_internet: true,
        response_json_schema: {
          type: "object",
          properties: {
            reasoning: { type: "string" },
            response: { type: "string" },
            sources: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  title: { type: "string" },
                  url: { type: "string" },
                  snippet: { type: "string" },
                },
              },
            },
          },
        },
        onStep: (step) => setLiveTranscript((prev) => [...prev, step]),
      });
      response = response.data || response;
    } else {
      response = await base44.functions.invoke("groqComplete", {
        prompt: userPrompt,
        response_json_schema: {
          type: "object",
          properties: {
            reasoning: { type: "string" },
            response: { type: "string" },
          },
        },
        onStep: (step) => setLiveTranscript((prev) => [...prev, step]),
      });
      response = response.data || response;
    }'''
n3 = c.count(old3)

old4 = '''            <WorkspacePanel
              conversationId={activeConversationId}
              isThinking={isThinking}
              transcript={[...messages].reverse().find((m) => m.role === "assistant" && m.transcript)?.transcript}
            />'''
new4 = '''            <WorkspacePanel
              conversationId={activeConversationId}
              isThinking={isThinking}
              transcript={
                isThinking && liveTranscript.length > 0
                  ? liveTranscript
                  : [...messages].reverse().find((m) => m.role === "assistant" && m.transcript)?.transcript
              }
            />'''
n4 = c.count(old4)

print(f"Home.jsx matches: state={n1}, reset={n2}, onStep={n3}, panel={n4}")
if n1 == 1 and n2 == 1 and n3 == 1 and n4 == 1:
    c = c.replace(old1, new1).replace(old2, new2).replace(old3, new3).replace(old4, new4)
    with open(path, "w") as f:
        f.write(c)
    print("Home.jsx patched")
else:
    print("ABORTED Home.jsx — one or more blocks didn't match exactly once")

# ---------- 3. WorkspacePanel.jsx: omegaagent$ prompt, show ALL steps in terminal ----------
path = f"{base}/src/components/omega/WorkspacePanel.jsx"
with open(path) as f:
    c = f.read()

old = '''            {activeTab === "terminal" && (
              <motion.div key="terminal" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="h-full">
                <div className="h-full bg-black font-mono text-xs p-3 overflow-y-auto">
                  <div className="text-white/20 mb-2">Omega Terminal — omega@workspace:~$</div>
                  {steps.filter((s) => s.tool === "terminal").length === 0 ? (
                    <p className="text-white/20">$ waiting for command...</p>
                  ) : (
                    steps.filter((s) => s.tool === "terminal").map((s) => (
                      <div key={s.id} className="mb-2">
                        <div className="text-teal-400">$ {s.title}</div>
                        {s.tool_output && (
                          <pre className="text-white/50 whitespace-pre-wrap mt-0.5">{s.tool_output}</pre>
                        )}
                      </div>
                    ))
                  )}
                  {isThinking && runningStep?.tool === "terminal" && (
                    <div className="text-teal-400 flex items-center gap-1">
                      $ <span className="animate-pulse">█</span>
                    </div>
                  )}
                </div>
              </motion.div>
            )}'''

new = '''            {activeTab === "terminal" && (
              <motion.div key="terminal" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="h-full">
                <div className="h-full bg-black font-mono text-xs p-3 overflow-y-auto">
                  <div className="text-white/20 mb-2">Omega Terminal — omegaagent$</div>
                  {steps.length === 0 ? (
                    <p className="text-white/20">omegaagent$ waiting for command...</p>
                  ) : (
                    steps.map((s) => (
                      <div key={s.id} className="mb-2">
                        <div className="text-teal-400">
                          omegaagent$ <span className="text-white/70">{s.title}</span>
                          {s.description && <span className="text-white/30"> — {s.description}</span>}
                        </div>
                        {s.tool_output && (
                          <pre className="text-white/50 whitespace-pre-wrap mt-0.5">{s.tool_output}</pre>
                        )}
                      </div>
                    ))
                  )}
                  {isThinking && runningStep && (
                    <div className="text-teal-400 flex items-center gap-1">
                      omegaagent$ <span className="animate-pulse">█</span>
                    </div>
                  )}
                </div>
              </motion.div>
            )}'''

n = c.count(old)
print(f"WorkspacePanel.jsx matches: {n}")
if n == 1:
    with open(path, "w") as f:
        f.write(c.replace(old, new))
    print("WorkspacePanel.jsx patched")
else:
    print("ABORTED WorkspacePanel.jsx — expected exactly 1 match")
PYEOF

echo ""
echo "=== Verifying all three files ==="
grep -n "streamAgentBackend\|onStep" "$FRONTEND/src/lib/localEntities.js" | head -5
grep -n "liveTranscript" "$FRONTEND/src/pages/Home.jsx"
grep -n "omegaagent\$" "$FRONTEND/src/components/omega/WorkspacePanel.jsx"
