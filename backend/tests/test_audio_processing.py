#!/usr/bin/env python3
"""
Test script for audio processing functionality
"""
import os
import sys
import asyncio
import numpy as np
import soundfile as sf
from fastapi import UploadFile
from io import BytesIO

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from app.services.audio_processing import audio_processor, FFMPEG_AVAILABLE

async def create_test_audio_file():
    """Create a simple test audio file"""
    # Generate a simple sine wave (1 second, 440Hz)
    sample_rate = 16000
    duration = 2.0  # 2 seconds
    frequency = 440  # A4 note
    
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    audio_data = 0.5 * np.sin(2 * np.pi * frequency * t)
    
    # Save to a temporary WAV file
    test_file_path = "test_audio.wav"
    sf.write(test_file_path, audio_data, sample_rate)
    
    return test_file_path

async def test_audio_processing():
    """Test the audio processing pipeline"""
    print(f"FFmpeg available: {FFMPEG_AVAILABLE}")
    
    # Create test audio file
    test_file_path = await create_test_audio_file()
    print(f"Created test audio file: {test_file_path}")
    
    try:
        # Read the test file as bytes
        with open(test_file_path, "rb") as f:
            file_content = f.read()
        
        # Create a mock UploadFile
        class MockUploadFile:
            def __init__(self, filename, content):
                self.filename = filename
                self._content = content
            
            async def read(self):
                return self._content
        
        mock_file = MockUploadFile("test_audio.wav", file_content)
        
        # Test audio processing
        print("Testing audio processing...")
        processed_filename, metadata = await audio_processor.process_audio_upload(
            mock_file, "test_user"
        )
        
        print(f"Processing successful!")
        print(f"Processed filename: {processed_filename}")
        print(f"Metadata: {metadata}")
        
        # Check if the processed file exists
        from app.core.config import settings
        processed_path = os.path.join(settings.AUDIO_STORAGE_PATH, processed_filename)
        if os.path.exists(processed_path):
            print(f"Processed file exists: {processed_path}")
            file_size = os.path.getsize(processed_path)
            print(f"File size: {file_size} bytes")
        else:
            print("Warning: Processed file not found")
        
    except Exception as e:
        print(f"Error during processing: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Clean up
        if os.path.exists(test_file_path):
            os.remove(test_file_path)

if __name__ == "__main__":
    asyncio.run(test_audio_processing())
