#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=~/omega-agent-v2

python3 - << 'PYEOF'
base = "/data/data/com.termux/files/home/omega-agent-v2"

# ---------- Home.jsx ----------
path = f"{base}/src/pages/Home.jsx"
with open(path) as f:
    c = f.read()

old4 = '''          <WorkspacePanel
            conversationId={activeConversationId}
            isThinking={isThinking}
            transcript={[...messages].reverse().find((m) => m.role === "assistant" && m.transcript)?.transcript}
          />'''
new4 = '''          <WorkspacePanel
            conversationId={activeConversationId}
            isThinking={isThinking}
            transcript={
              isThinking && liveTranscript.length > 0
                ? liveTranscript
                : [...messages].reverse().find((m) => m.role === "assistant" && m.transcript)?.transcript
            }
          />'''

n4 = c.count(old4)
print(f"Home.jsx panel matches: {n4}")
if n4 == 1:
    c = c.replace(old4, new4)
    with open(path, "w") as f:
        f.write(c)
    print("Home.jsx patched (panel wiring)")
else:
    print("ABORTED Home.jsx panel wiring — not exactly 1 match")

# ---------- WorkspacePanel.jsx ----------
path = f"{base}/src/components/omega/WorkspacePanel.jsx"
with open(path) as f:
    c = f.read()

old = '''          {activeTab === "terminal" && (
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

new = '''          {activeTab === "terminal" && (
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
    print("ABORTED WorkspacePanel.jsx — not exactly 1 match")
PYEOF

echo ""
echo "=== Verifying ==="
grep -n "liveTranscript" "$FRONTEND/src/pages/Home.jsx"
grep -n "omegaagent\$" "$FRONTEND/src/components/omega/WorkspacePanel.jsx"
