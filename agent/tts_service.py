"""
Chatterbox TTS microservice.
Exposes POST /api/tts { "text": "..." } -> audio/wav bytes,
synthesized in the voice cloned from voice_samples/my_voice.wav.

Wire this into chat_server.py by importing `tts_bp` and registering it:
    from agent.tts_service import tts_bp
    app.register_blueprint(tts_bp)

Or call synthesize_speech(text) directly after generating the assistant's
final response text, and stream/save the returned bytes to the client.
"""
import io
import os
from flask import Blueprint, request, send_file, jsonify

tts_bp = Blueprint("tts", __name__)

VOICE_SAMPLE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "voice_samples", "my_voice.wav"
)

_model = None

def _get_model():
    global _model
    if _model is None:
        from chatterbox.tts import ChatterboxTTS
        _model = ChatterboxTTS.from_pretrained(device="cpu")
    return _model

def synthesize_speech(text: str) -> bytes:
    """Returns WAV audio bytes for the given text, in the cloned voice."""
    if not os.path.exists(VOICE_SAMPLE_PATH):
        raise FileNotFoundError(
            f"No voice sample found at {VOICE_SAMPLE_PATH}. "
            "Record one first (see record_voice_sample.sh)."
        )
    model = _get_model()
    wav = model.generate(text, audio_prompt_path=VOICE_SAMPLE_PATH)

    buf = io.BytesIO()
    import torchaudio
    torchaudio.save(buf, wav, model.sr, format="wav")
    buf.seek(0)
    return buf.read()

@tts_bp.route("/api/tts", methods=["POST"])
def tts_endpoint():
    data = request.get_json(force=True) or {}
    text = data.get("text", "").strip()
    if not text:
        return jsonify({"error": "text is required"}), 400
    try:
        audio_bytes = synthesize_speech(text)
    except FileNotFoundError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": f"TTS failed: {e}"}), 500

    return send_file(
        io.BytesIO(audio_bytes),
        mimetype="audio/wav",
        as_attachment=False,
        download_name="response.wav",
    )
