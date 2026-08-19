import { useState } from "react";

/**
 * Voice on/off toggle. When on, the parent should call speakText(text)
 * after each assistant response finishes (see hook below).
 */
export default function VoiceToggle({ enabled, onToggle }) {
  return (
    <button
      onClick={() => onToggle(!enabled)}
      className={`flex items-center gap-1.5 px-2 py-1 rounded-md text-xs border transition-colors ${
        enabled
          ? "border-teal-400 text-teal-300 bg-teal-500/10"
          : "border-white/10 text-white/40"
      }`}
      title={enabled ? "Voice: on" : "Voice: off"}
    >
      {enabled ? "🔊" : "🔇"}
    </button>
  );
}
