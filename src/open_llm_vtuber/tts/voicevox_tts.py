import requests
from loguru import logger

from .tts_interface import TTSInterface


# VOICEVOX engine HTTP API: https://voicevox.github.io/voicevox_engine/api/
# Run the engine locally (default http://127.0.0.1:50021) before starting the server.


class TTSEngine(TTSInterface):
    def __init__(
        self,
        base_url="http://127.0.0.1:50021",
        speaker_id=8,
        speed_scale=1.0,
        pitch_scale=0.0,
        intonation_scale=1.0,
        volume_scale=1.0,
    ):
        self.base_url = base_url.rstrip("/")
        self.speaker_id = speaker_id
        self.speed_scale = speed_scale
        self.pitch_scale = pitch_scale
        self.intonation_scale = intonation_scale
        self.volume_scale = volume_scale
        self.file_extension = "wav"

    def generate_audio(self, text, file_name_no_ext=None):
        file_name = self.generate_cache_file_name(file_name_no_ext, self.file_extension)
        try:
            query = requests.post(
                f"{self.base_url}/audio_query",
                params={"text": text, "speaker": self.speaker_id},
                timeout=30,
            )
            query.raise_for_status()
            audio_query = query.json()
            audio_query["speedScale"] = self.speed_scale
            audio_query["pitchScale"] = self.pitch_scale
            audio_query["intonationScale"] = self.intonation_scale
            audio_query["volumeScale"] = self.volume_scale

            synthesis = requests.post(
                f"{self.base_url}/synthesis",
                params={"speaker": self.speaker_id},
                json=audio_query,
                timeout=60,
            )
            synthesis.raise_for_status()
            with open(file_name, "wb") as f:
                f.write(synthesis.content)
        except Exception as e:
            logger.critical(f"\nError: VOICEVOX unable to generate audio: {e}")
            logger.critical("Is the VOICEVOX engine running? (Start Miku.command starts it)")
            return None

        return file_name
