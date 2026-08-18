import React, { useState, useRef, useEffect } from "react";
import { Send, Globe, Code, Brain, Zap, Paperclip, Camera, Image as ImageIcon, X } from "lucide-react";
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
  const [showAttach, setShowAttach] = useState(false);
  const [attachments, setAttachments] = useState([]); // { id, url, file }
  const textareaRef = useRef(null);
  const galleryInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
      textareaRef.current.style.height = Math.min(textareaRef.current.scrollHeight, 160) + "px";
    }
  }, [text]);

  const handleSend = () => {
    if ((!text.trim() && attachments.length === 0) || disabled) return;
    onSend(text.trim(), mode, attachments);
    setText("");
    setMode("chat");
    attachments.forEach((a) => URL.revokeObjectURL(a.url));
    setAttachments([]);
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleFiles = (fileList) => {
    const files = Array.from(fileList || []).filter((f) => f.type.startsWith("image/"));
    const next = files.map((file) => ({
      id: Math.random().toString(36).slice(2),
      url: URL.createObjectURL(file),
      file,
    }));
    setAttachments((prev) => [...prev, ...next]);
    setShowAttach(false);
  };

  const removeAttachment = (id) => {
    setAttachments((prev) => {
      const found = prev.find((a) => a.id === id);
      if (found) URL.revokeObjectURL(found.url);
      return prev.filter((a) => a.id !== id);
    });
  };

  const currentMode = MODES.find((m) => m.id === mode);
  const ModeIcon = currentMode.icon;

  return (
    <div className="relative">
      {/* Hidden file inputs */}
      <input
        ref={galleryInputRef}
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={(e) => handleFiles(e.target.files)}
      />
      <input
        ref={cameraInputRef}
        type="file"
        accept="image/*"
        capture="environment"
        className="hidden"
        onChange={(e) => handleFiles(e.target.files)}
      />

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

      {/* Attach selector */}
      <AnimatePresence>
        {showAttach && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 8 }}
            className="absolute bottom-full mb-2 left-10 bg-black border border-white/10 rounded-xl p-1 flex gap-1 z-10"
          >
            <button
              onClick={() => cameraInputRef.current?.click()}
              className="flex items-center gap-2 px-3 py-2 rounded-lg text-xs text-white/40 hover:text-white hover:bg-white/5 transition-all"
            >
              <Camera className="w-3.5 h-3.5" />
              Take Photo
            </button>
            <button
              onClick={() => galleryInputRef.current?.click()}
              className="flex items-center gap-2 px-3 py-2 rounded-lg text-xs text-white/40 hover:text-white hover:bg-white/5 transition-all"
            >
              <ImageIcon className="w-3.5 h-3.5" />
              Upload Photo
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      <div className="bg-white/[0.03] border border-white/10 rounded-2xl overflow-hidden focus-within:border-teal-500/40 transition-colors">
        {/* Attachment thumbnails */}
        {attachments.length > 0 && (
          <div className="flex gap-2 px-3 pt-3 flex-wrap">
            {attachments.map((a) => (
              <div key={a.id} className="relative w-14 h-14 rounded-lg overflow-hidden border border-white/10 shrink-0">
                <img src={a.url} alt="attachment" className="w-full h-full object-cover" />
                <button
                  onClick={() => removeAttachment(a.id)}
                  className="absolute top-0.5 right-0.5 w-4 h-4 rounded-full bg-black/70 text-white/80 flex items-center justify-center hover:bg-black hover:text-white transition-colors"
                >
                  <X className="w-2.5 h-2.5" />
                </button>
              </div>
            ))}
          </div>
        )}

        <div className="flex items-end gap-2 p-3">
          {/* Mode toggle */}
          <button
            onClick={() => { setShowModes(!showModes); setShowAttach(false); }}
            className={`p-2 rounded-lg transition-colors shrink-0 ${
              mode !== "chat" ? "bg-teal-500/10 text-teal-400" : "text-white/30 hover:text-white/60"
            }`}
            title="Switch mode"
          >
            <ModeIcon className="w-5 h-5" />
          </button>

          {/* Attach toggle */}
          <button
            onClick={() => { setShowAttach(!showAttach); setShowModes(false); }}
            className={`p-2 rounded-lg transition-colors shrink-0 ${
              showAttach || attachments.length > 0 ? "bg-teal-500/10 text-teal-400" : "text-white/30 hover:text-white/60"
            }`}
            title="Attach photo"
          >
            <Paperclip className="w-5 h-5" />
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
            disabled={(!text.trim() && attachments.length === 0) || disabled}
            className={`p-2 rounded-lg shrink-0 transition-all ${
              (text.trim() || attachments.length > 0) && !disabled
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
