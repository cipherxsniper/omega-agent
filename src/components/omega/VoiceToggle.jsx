/**
 * Voice on/off toggle. When on, the parent calls speakText(text) after
 * each assistant response finishes (see src/hooks/useVoice.js).
 */
export default function VoiceToggle({ enabled, onToggle }) {
  return (
    <button
      onClick={() => onToggle(!enabled)}
      className={`flex items-center justify-center h-7 w-7 rounded-md border transition-colors ${
        enabled
          ? "border-teal-300/20 bg-teal-300 text-black"
          : "border-teal-300/15 text-teal-200/45"
      }`}
      title={enabled ? "Voice: on" : "Voice: off"}
    >
      <span className="text-xs font-bold">{enabled ? "ON" : "OFF"}</span>
    </button>
  );
}
