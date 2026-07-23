import React, { useState } from "react";
import { motion } from "framer-motion";
import { ChevronDown, ChevronUp, ExternalLink, Brain, Clock } from "lucide-react";

export default function MessageBubble({ message }) {
  const [showReasoning, setShowReasoning] = useState(false);
  const [showSources, setShowSources] = useState(false);
  const isUser = message.role === "user";
  const isSystem = message.role === "system";

  if (isSystem) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className={`flex ${isUser ? "justify-end" : "justify-start"} mb-4`}
    >
      <div className={`max-w-[80%] ${isUser ? "order-1" : "order-1"}`}>
        {/* Avatar + Name */}
        <div className={`flex items-center gap-2 mb-1 ${isUser ? "justify-end" : "justify-start"}`}>
          {!isUser && (
            <div className="w-6 h-6 rounded-full bg-teal-500 flex items-center justify-center">
              <span className="text-black text-xs font-black">Ω</span>
            </div>
          )}
          <span className="text-xs text-white/40 font-mono">
            {isUser ? "You" : "Omega"}
          </span>
          {message.metadata?.response_time_ms && (
            <span className="text-xs text-white/20 flex items-center gap-1">
              <Clock className="w-3 h-3" />
              {(message.metadata.response_time_ms / 1000).toFixed(1)}s
            </span>
          )}
        </div>

        {/* Message bubble */}
        <div
          className={`rounded-2xl px-4 py-3 ${
            isUser
              ? "bg-teal-500 text-black rounded-br-sm"
              : "bg-white/5 text-white border border-white/10 rounded-bl-sm"
          }`}
        >
          <div className="whitespace-pre-wrap text-sm leading-relaxed">
            {message.content}
          </div>
        </div>

        {/* Reasoning Chain */}
        {message.reasoning_chain && !isUser && (
          <button
            onClick={() => setShowReasoning(!showReasoning)}
            className="mt-2 flex items-center gap-1 text-xs text-teal-400/60 hover:text-teal-400 transition-colors"
          >
            <Brain className="w-3 h-3" />
            Reasoning Chain
            {showReasoning ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
          </button>
        )}
        {showReasoning && message.reasoning_chain && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            className="mt-1 px-3 py-2 bg-white/[0.02] border border-white/5 rounded-lg text-xs text-white/40 font-mono whitespace-pre-wrap"
          >
            {message.reasoning_chain}
          </motion.div>
        )}

        {/* Sources */}
        {message.sources?.length > 0 && !isUser && (
          <>
            <button
              onClick={() => setShowSources(!showSources)}
              className="mt-2 flex items-center gap-1 text-xs text-teal-400/60 hover:text-teal-400 transition-colors"
            >
              <ExternalLink className="w-3 h-3" />
              {message.sources.length} Sources
              {showSources ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
            </button>
            {showSources && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: "auto", opacity: 1 }}
                className="mt-1 space-y-1"
              >
                {message.sources.map((s, i) => (
                  <a
                    key={i}
                    href={s.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block px-3 py-2 bg-white/[0.02] border border-white/5 rounded-lg text-xs hover:border-teal-500/30 transition-colors"
                  >
                    <span className="text-teal-400">{s.title}</span>
                    {s.snippet && <p className="text-white/30 mt-0.5">{s.snippet}</p>}
                  </a>
                ))}
              </motion.div>
            )}
          </>
        )}

        {/* Mode badge */}
        {message.metadata?.mode && message.metadata.mode !== "chat" && !isUser && (
          <div className="mt-2">
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-teal-500/10 text-teal-400 border border-teal-500/20 uppercase tracking-wider font-mono">
              {message.metadata.mode}
            </span>
          </div>
        )}
      </div>
    </motion.div>
  );
}