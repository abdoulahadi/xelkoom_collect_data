import os
import uuid
import librosa
import ffmpeg
import soundfile as sf
import numpy as np
from typing import Tuple, Optional
from fastapi import UploadFile, HTTPException
from app.core.config import settings
import logging
import subprocess
import shutil

logger = logging.getLogger(__name__)

def _check_ffmpeg_availability():
    """Check if FFmpeg is available in the system"""
    try:
        # First try to use static_ffmpeg if available
        try:
            import static_ffmpeg
            static_ffmpeg.add_paths()
            return True
        except Exception:
            pass
        
        # Fallback: check if ffmpeg is in PATH
        return shutil.which('ffmpeg') is not None
    except Exception:
        return False

# Check FFmpeg availability at module load
FFMPEG_AVAILABLE = _check_ffmpeg_availability()

logger = logging.getLogger(__name__)

class AudioProcessor:
    """Service for processing audio files"""
    
    def __init__(self):
        self.target_sample_rate = 16000
        self.target_channels = 1  # Mono
        self.max_duration = 30  # Maximum 30 seconds
        self.min_duration = 1   # Minimum 1 second
    
    async def process_audio_upload(
        self, 
        file: UploadFile, 
        user_id: str
    ) -> Tuple[str, dict]:
        """
        Process uploaded audio file
        Returns: (filepath, metadata)
        """
        # Validate file
        if not file.filename.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg')):
            raise HTTPException(
                status_code=400, 
                detail="Unsupported audio format. Please use WAV, MP3, M4A, or OGG."
            )
        
        # Check file size
        content = await file.read()
        file_size_mb = len(content) / (1024 * 1024)
        
        if file_size_mb > settings.MAX_AUDIO_SIZE_MB:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Maximum size is {settings.MAX_AUDIO_SIZE_MB}MB."
            )
        
        # Generate unique filename
        file_id = str(uuid.uuid4())
        temp_filename = f"temp_{file_id}.{file.filename.split('.')[-1]}"
        processed_filename = f"{user_id}_{file_id}.wav"
        
        temp_filepath = os.path.join(settings.AUDIO_STORAGE_PATH, temp_filename)
        final_filepath = os.path.join(settings.AUDIO_STORAGE_PATH, processed_filename)
        
        try:
            # Save temporary file
            with open(temp_filepath, "wb") as temp_file:
                temp_file.write(content)
            
            # Process audio
            metadata = await self._process_audio_file(temp_filepath, final_filepath)
            metadata.update({
                "original_filename": file.filename,
                "file_size_mb": file_size_mb
            })
            
            # Clean up temp file
            if os.path.exists(temp_filepath):
                os.remove(temp_filepath)
            
            return processed_filename, metadata
            
        except Exception as e:
            # Clean up on error
            for filepath in [temp_filepath, final_filepath]:
                if os.path.exists(filepath):
                    os.remove(filepath)
            
            logger.error(f"Audio processing error: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail="Audio processing failed"
            )
    
    async def _process_audio_file(self, input_path: str, output_path: str) -> dict:
        """Process audio file using FFmpeg and librosa"""
        
        if not FFMPEG_AVAILABLE:
            logger.warning("FFmpeg not available, using librosa-only processing")
            return await self._process_audio_librosa_only(input_path, output_path)
        
        # First, use FFmpeg to normalize the input to a standard format
        temp_wav_path = input_path.replace(os.path.splitext(input_path)[1], '_temp.wav')
        
        try:
            # Convert to WAV using FFmpeg first
            logger.info(f"Converting {input_path} to WAV format")
            (
                ffmpeg
                .input(input_path)
                .output(temp_wav_path, acodec='pcm_s16le', ar=self.target_sample_rate, ac=self.target_channels)
                .overwrite_output()
                .run(quiet=True)
            )
            
            # Now load the converted WAV file with librosa
            logger.info(f"Loading converted audio with librosa")
            audio, original_sr = librosa.load(temp_wav_path, sr=None)
            duration = len(audio) / original_sr
            
            # Clean up temp WAV file
            if os.path.exists(temp_wav_path):
                os.remove(temp_wav_path)
            
            # Validate duration
            if duration < self.min_duration:
                raise HTTPException(
                    status_code=400,
                    detail=f"Audio too short. Minimum duration is {self.min_duration} seconds."
                )
            
            if duration > self.max_duration:
                raise HTTPException(
                    status_code=400,
                    detail=f"Audio too long. Maximum duration is {self.max_duration} seconds."
                )
            
            # Resample if necessary (should not be needed since we already converted)
            if original_sr != self.target_sample_rate:
                audio = librosa.resample(audio, orig_sr=original_sr, target_sr=self.target_sample_rate)
            
            # Normalize audio
            audio = self._normalize_audio(audio)
            
            # Trim silence
            audio = self._trim_silence(audio)
            
            # Calculate quality metrics
            quality_score = self._calculate_quality_score(audio)
            
            # Save processed audio using FFmpeg
            await self._save_audio_ffmpeg(audio, output_path)
            
            return {
                "duration": float(len(audio) / self.target_sample_rate),  # Convert to Python float
                "sample_rate": int(self.target_sample_rate),  # Ensure it's Python int
                "channels": int(self.target_channels),  # Ensure it's Python int
                "quality_score": quality_score  # Already converted to float in _calculate_quality_score
            }
            
        except ffmpeg.Error as e:
            logger.error(f"FFmpeg conversion error: {str(e)}")
            if os.path.exists(temp_wav_path):
                os.remove(temp_wav_path)
            raise HTTPException(
                status_code=400,
                detail="Unsupported audio format or corrupted file"
            )
        except Exception as e:
            logger.error(f"Audio processing error: {str(e)}")
            if os.path.exists(temp_wav_path):
                os.remove(temp_wav_path)
            raise
    
    async def _process_audio_librosa_only(self, input_path: str, output_path: str) -> dict:
        """Process audio file using librosa only (fallback when FFmpeg is not available)"""
        try:
            # Load audio directly with librosa
            logger.info(f"Loading audio with librosa (no FFmpeg available)")
            audio, original_sr = librosa.load(input_path, sr=self.target_sample_rate, mono=True)
            duration = len(audio) / self.target_sample_rate
            
            # Validate duration
            if duration < self.min_duration:
                raise HTTPException(
                    status_code=400,
                    detail=f"Audio too short. Minimum duration is {self.min_duration} seconds."
                )
            
            if duration > self.max_duration:
                raise HTTPException(
                    status_code=400,
                    detail=f"Audio too long. Maximum duration is {self.max_duration} seconds."
                )
            
            # Normalize audio
            audio = self._normalize_audio(audio)
            
            # Trim silence
            audio = self._trim_silence(audio)
            
            # Calculate quality metrics
            quality_score = self._calculate_quality_score(audio)
            
            # Save processed audio using soundfile
            sf.write(output_path, audio, self.target_sample_rate)
            
            return {
                "duration": float(len(audio) / self.target_sample_rate),  # Convert to Python float
                "sample_rate": int(self.target_sample_rate),  # Ensure it's Python int
                "channels": int(self.target_channels),  # Ensure it's Python int
                "quality_score": quality_score  # Already converted to float in _calculate_quality_score
            }
            
        except Exception as e:
            logger.error(f"Audio processing error (librosa-only): {str(e)}")
            raise HTTPException(
                status_code=400,
                detail="Audio processing failed. Please ensure the file is a valid audio format."
            )

    def _normalize_audio(self, audio: np.ndarray) -> np.ndarray:
        """Normalize audio to -20dB"""
        # RMS normalization
        rms = np.sqrt(np.mean(audio**2))
        if rms > 0:
            target_rms = 0.1  # -20dB
            audio = audio * (target_rms / rms)
        
        # Prevent clipping
        max_val = np.max(np.abs(audio))
        if max_val > 0.95:
            audio = audio * (0.95 / max_val)
        
        return audio
    
    def _trim_silence(self, audio: np.ndarray, top_db: int = 20) -> np.ndarray:
        """Trim silence from beginning and end"""
        try:
            trimmed, _ = librosa.effects.trim(audio, top_db=top_db)
            return trimmed if len(trimmed) > 0 else audio
        except Exception:
            return audio
    
    def _calculate_quality_score(self, audio: np.ndarray) -> float:
        """Calculate a simple quality score (0-1)"""
        try:
            # Signal-to-noise ratio estimation
            signal_power = np.mean(audio**2)
            
            # Zero crossing rate
            zcr = librosa.feature.zero_crossing_rate(audio)[0]
            zcr_mean = np.mean(zcr)
            
            # Spectral centroid
            spectral_centroid = librosa.feature.spectral_centroid(y=audio, sr=self.target_sample_rate)[0]
            sc_mean = np.mean(spectral_centroid)
            
            # Simple quality score based on signal characteristics
            quality = min(1.0, signal_power * 10)  # Penalize very quiet recordings
            quality *= min(1.0, max(0.5, 1.0 - zcr_mean * 2))  # Penalize noisy recordings
            
            # Convert NumPy types to Python float for database compatibility
            return float(max(0.0, min(1.0, quality)))
            
        except Exception:
            return 0.5  # Default score if calculation fails
    
    async def _save_audio_ffmpeg(self, audio: np.ndarray, output_path: str):
        """Save audio using FFmpeg or fallback to soundfile"""
        if not FFMPEG_AVAILABLE:
            # Fallback to soundfile
            sf.write(output_path, audio, self.target_sample_rate)
            return
        
        try:
            # Convert to 16-bit PCM
            audio_int16 = (audio * 32767).astype(np.int16)
            
            process = (
                ffmpeg
                .input('pipe:', format='s16le', acodec='pcm_s16le', ac=1, ar=self.target_sample_rate)
                .output(output_path, acodec='pcm_s16le', ac=1, ar=self.target_sample_rate)
                .overwrite_output()
                .run_async(pipe_stdin=True, quiet=True)
            )
            
            process.stdin.write(audio_int16.tobytes())
            process.stdin.close()
            process.wait()  # Remove await here since process.wait() is not a coroutine
            
        except Exception as e:
            logger.error(f"FFmpeg save error: {str(e)}")
            # Fallback: save using soundfile
            sf.write(output_path, audio, self.target_sample_rate)

# Global audio processor instance
audio_processor = AudioProcessor()
