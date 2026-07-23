import React, { useState, useRef, useEffect } from "react";
import { Send, Globe, Code, Brain, Zap, Paperclip } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

const MODES = [
  { id: "chat", label: "Chat", icon: Zap, color: "text-white" },
  { id: "research", label: "Deep Research", icon: Globe, color: "text-teal-400" },
  { id: "code", label: "Code", icon: Code, color: "text-blue-400" },
  { id: "self_improve", label: "Self-Improve", icon: Brain, color: "text-purple-400" },
];

export default function ChatInput({ onSend, disabled }) {
  const [text, setText] = useState("");
  const [mode, setMode] = useState("chat");
  const [showModes, setShowModes] = useState(false);
  const textareaRef = useRef(null);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
      textareaRef.current.style.height = Math.min(textareaRef.current.scrollHeight, 160) + "px";
    }
  }, [text]);

  const handleSend = () => {
    if (!text.trim() || disabled) return;
    onSend(text.trim(), mode);
    setText("");
    setMode("chat");
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const currentMode = MODES.find((m) => m.id === mode);
  const ModeIcon = currentMode.icon;

  return (
    <div className="relative">
      {/* Mode selector */}
      <AnimatePresence>
        {showModes && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 8 }}
            className="absolute bottom-full mb-2 left-0 bg-black border border-white/10 rounded-xl p-1 flex gap-1"
          >
            {MODES.map((m) => {
              const Icon = m.icon;
              return (
                <button
                  key={m.id}
                  onClick={() => { setMode(m.id); setShowModes(false); }}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs transition-all ${
                    mode === m.id
                      ? "bg-white/10 text-white"
                      : "text-white/40 hover:text-white hover:bg-white/5"
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  {m.label}
                </button>
              );
            })}
          </motion.div>
        )}
      </AnimatePresence>

      <div className="bg-white/[0.03] border border-white/10 rounded-2xl overflow-hidden focus-within:border-teal-500/40 transition-colors">
        <div className="flex items-end gap-2 p-3">
          {/* Mode toggle */}
          <button
            onClick={() => setShowModes(!showModes)}
            className={`p-2 rounded-lg transition-colors shrink-0 ${
              mode !== "chat" ? "bg-teal-500/10 text-teal-400" : "text-white/30 hover:text-white/60"
            }`}
            title="Switch mode"
          >
            <ModeIcon className="w-5 h-5" />
          </button>

          {/* Textarea */}
          <textarea
            ref={textareaRef}
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={
              mode === "research"
                ? "Ask Omega to research anything..."
                : mode === "code"
                ? "Describe what you want Omega to build..."
                : mode === "self_improve"
                ? "Ask Omega to analyze and improve itself..."
                : "Message Omega..."
            }
            className="flex-1 bg-transparent text-white text-sm resize-none outline-none placeholder:text-white/20 min-h-[24px] max-h-[160px] py-1"
            rows={1}
            disabled={disabled}
          />

          {/* Send */}
          <button
            onClick={handleSend}
            disabled={!text.trim() || disabled}
            className={`p-2 rounded-lg shrink-0 transition-all ${
              text.trim() && !disabled
                ? "bg-teal-500 text-black hover:bg-teal-400"
                : "text-white/10"
            }`}
          >
            <Send className="w-5 h-5" />
          </button>
        </div>

        {/* Mode indicator bar */}
        {mode !== "chat" && (
          <div className="px-4 pb-2">
            <span className={`text-[10px] font-mono tracking-wider uppercase ${currentMode.color}`}>
              {currentMode.label} Mode Active
            </span>
          </div>
        )}
      </div>
    </div>
  );
}