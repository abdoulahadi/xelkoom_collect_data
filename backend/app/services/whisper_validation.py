"""
Whisper-based audio validation service
Validates that recorded audio matches the expected text
"""
# import whisper  # Temporairement désactivé pour éviter les problèmes d'import
import tempfile
import os
import logging
from typing import Optional, Dict, Tuple
from difflib import SequenceMatcher
import asyncio
import functools
from app.core.config import settings

logger = logging.getLogger(__name__)

class WhisperValidationService:
    """Service for validating audio content against expected text using Whisper"""
    
    def __init__(self):
        self.model = None
        self.enabled = settings.ENABLE_WHISPER_VALIDATION
        if self.enabled:
            logger.warning("Whisper validation temporairement désactivé")
            self.enabled = False
        
        if not self.enabled:
            logger.info("Whisper validation disabled")
            return
            
        self.model = None
        self.model_name = settings.WHISPER_MODEL
        
        # Désactiver whisper pour le moment
        # if self.enabled:
        #     self._load_model()
    
    def _load_model(self):
        """Load Whisper model"""
        if not self.enabled:
            return
            
        try:
            logger.info(f"Loading Whisper model: {self.model_name}")
            # self.model = whisper.load_model(self.model_name)  # Désactivé temporairement
            logger.info("Whisper model loading skipped (temporarily disabled)")
        except Exception as e:
            logger.error(f"Failed to load Whisper model: {e}")
            self.enabled = False
    
    async def validate_audio_text_match(
        self, 
        audio_path: str, 
        expected_text: str,
        threshold: float = 0.8
    ) -> Dict[str, any]:
        """
        Validate that audio content matches expected text
        Returns validation results with confidence score
        """
        if not self.enabled or not self.model:
            return {
                "is_valid": True,  # Assume valid if validation disabled
                "confidence": 1.0,
                "transcribed_text": None,
                "similarity_score": 1.0,
                "error": "Whisper validation disabled"
            }
        
        try:
            # Run transcription in thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, 
                functools.partial(self._transcribe_audio, audio_path)
            )
            
            if result is None:
                return {
                    "is_valid": False,
                    "confidence": 0.0,
                    "transcribed_text": None,
                    "similarity_score": 0.0,
                    "error": "Failed to transcribe audio"
                }
            
            transcribed_text = result["text"].strip().lower()
            expected_text_clean = expected_text.strip().lower()
            
            # Calculate similarity score
            similarity = self._calculate_similarity(transcribed_text, expected_text_clean)
            
            # Determine if validation passes
            is_valid = similarity >= threshold
            
            return {
                "is_valid": is_valid,
                "confidence": result.get("confidence", 0.0),
                "transcribed_text": transcribed_text,
                "expected_text": expected_text_clean,
                "similarity_score": similarity,
                "threshold": threshold,
                "error": None
            }
            
        except Exception as e:
            logger.error(f"Whisper validation failed: {e}")
            return {
                "is_valid": False,
                "confidence": 0.0,
                "transcribed_text": None,
                "similarity_score": 0.0,
                "error": str(e)
            }
    
    def _transcribe_audio(self, audio_path: str) -> Optional[Dict]:
        """Transcribe audio using Whisper model"""
        try:
            result = self.model.transcribe(
                audio_path,
                language="wo",  # Wolof language code
                task="transcribe",
                fp16=False  # For better compatibility
            )
            return result
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            return None
    
    def _calculate_similarity(self, text1: str, text2: str) -> float:
        """Calculate similarity between two texts"""
        # Use sequence matcher for similarity
        similarity = SequenceMatcher(None, text1, text2).ratio()
        
        # Additional fuzzy matching could be added here
        # For Wolof, we might need language-specific rules
        
        return similarity
    
    async def batch_validate_recordings(
        self, 
        recordings: list, 
        progress_callback=None
    ) -> Dict[str, Dict]:
        """Batch validate multiple recordings"""
        results = {}
        total = len(recordings)
        
        for i, recording in enumerate(recordings):
            try:
                result = await self.validate_audio_text_match(
                    recording["audio_path"],
                    recording["expected_text"]
                )
                results[recording["id"]] = result
                
                if progress_callback:
                    progress_callback(i + 1, total)
                    
            except Exception as e:
                logger.error(f"Batch validation failed for recording {recording['id']}: {e}")
                results[recording["id"]] = {
                    "is_valid": False,
                    "error": str(e)
                }
        
        return results

class AudioQualityAnalyzer:
    """Advanced audio quality analysis"""
    
    @staticmethod
    def analyze_audio_quality(audio_path: str) -> Dict[str, float]:
        """Analyze audio quality metrics"""
        try:
            import librosa
            import numpy as np
            
            # Load audio
            y, sr = librosa.load(audio_path, sr=16000)
            
            # Calculate various quality metrics
            
            # 1. Signal-to-Noise Ratio estimation
            signal_power = np.mean(y**2)
            noise_floor = np.percentile(np.abs(y), 10)  # Estimate noise floor
            snr = 10 * np.log10(signal_power / (noise_floor**2 + 1e-10))
            
            # 2. Dynamic Range
            dynamic_range = np.max(np.abs(y)) - np.min(np.abs(y))
            
            # 3. Zero Crossing Rate (speech quality indicator)
            zcr = librosa.feature.zero_crossing_rate(y)[0]
            zcr_mean = np.mean(zcr)
            zcr_std = np.std(zcr)
            
            # 4. Spectral features
            spectral_centroid = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
            spectral_rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr)[0]
            
            # 5. MFCCs (voice quality)
            mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
            mfcc_mean = np.mean(mfccs, axis=1)
            
            # 6. Chroma features
            chroma = librosa.feature.chroma_stft(y=y, sr=sr)
            chroma_mean = np.mean(chroma, axis=1)
            
            # Calculate overall quality score
            quality_score = min(1.0, max(0.0, (
                min(snr / 20, 1.0) * 0.3 +  # SNR contribution
                min(dynamic_range * 2, 1.0) * 0.2 +  # Dynamic range
                (1.0 - min(zcr_mean * 5, 1.0)) * 0.2 +  # ZCR (lower is better for speech)
                min(np.mean(spectral_centroid) / 4000, 1.0) * 0.3  # Spectral centroid
            )))
            
            return {
                "overall_quality": quality_score,
                "snr_db": float(snr),
                "dynamic_range": float(dynamic_range),
                "zcr_mean": float(zcr_mean),
                "zcr_std": float(zcr_std),
                "spectral_centroid_mean": float(np.mean(spectral_centroid)),
                "spectral_rolloff_mean": float(np.mean(spectral_rolloff)),
                "mfcc_features": mfcc_mean.tolist(),
                "chroma_features": chroma_mean.tolist()
            }
            
        except Exception as e:
            logger.error(f"Audio quality analysis failed: {e}")
            return {
                "overall_quality": 0.5,
                "error": str(e)
            }

# Global instances
whisper_service = WhisperValidationService()
quality_analyzer = AudioQualityAnalyzer()

# Export for compatibility
whisper_validator = whisper_service
