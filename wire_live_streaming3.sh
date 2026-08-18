#!/data/data/com.termux/files/usr/bin/bash
set -x

python3 - << 'PYEOF'
path = "/data/data/com.termux/files/home/omega-agent-v2/src/pages/Home.jsx"
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

old3a = '''          },
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
new3a = '''          },
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
n3 = c.count(old3a)

print(f"state={n1}, reset={n2}, onStep_pair={n3}")

if n1 == 1:
    c = c.replace(old1, new1)
    print("state applied")
else:
    print("SKIPPED state - not exactly 1 match")

if n2 == 1:
    c = c.replace(old2, new2)
    print("reset applied")
else:
    print("SKIPPED reset - not exactly 1 match")

if n3 == 1:
    c = c.replace(old3a, new3a)
    print("onStep pair applied")
else:
    print("SKIPPED onStep pair - not exactly 1 match")

with open(path, "w") as f:
    f.write(c)
print("File written with whatever applied above")
PYEOF

echo ""
echo "=== Final verification: all liveTranscript references ==="
grep -n "liveTranscript" /data/data/com.termux/files/home/omega-agent-v2/src/pages/Home.jsx
echo ""
echo "=== Final verification: onStep wiring ==="
grep -n "onStep:" /data/data/com.termux/files/home/omega-agent-v2/src/pages/Home.jsx
echo ""
echo "=== Confirm WorkspacePanel terminal patch (using -F for literal match) ==="
grep -nF "omegaagent$" /data/data/com.termux/files/home/omega-agent-v2/src/components/omega/WorkspacePanel.jsx
