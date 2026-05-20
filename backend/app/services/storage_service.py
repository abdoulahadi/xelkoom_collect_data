"""
S3 Storage Service for audio files
Implements secure cloud storage with presigned URLs
"""
import boto3
import uuid
import os
import logging
from typing import Optional, Tuple
from botocore.exceptions import ClientError, NoCredentialsError
from fastapi import UploadFile, HTTPException
from app.core.config import settings

logger = logging.getLogger(__name__)

class S3StorageService:
    """S3 storage service for audio files"""
    
    def __init__(self):
        self.bucket_name = settings.AWS_BUCKET_NAME
        self.region = settings.AWS_REGION
        
        try:
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=self.region
            )
            
            # Test connection if credentials are provided
            if settings.AWS_ACCESS_KEY_ID and settings.AWS_BUCKET_NAME:
                self._test_connection()
                
        except NoCredentialsError:
            logger.warning("AWS credentials not found. Using local storage.")
            self.s3_client = None
        except Exception as e:
            logger.error(f"Failed to initialize S3 client: {e}")
            self.s3_client = None
    
    def _test_connection(self):
        """Test S3 connection and bucket access"""
        try:
            self.s3_client.head_bucket(Bucket=self.bucket_name)
            logger.info(f"Successfully connected to S3 bucket: {self.bucket_name}")
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                logger.error(f"S3 bucket '{self.bucket_name}' not found")
            elif error_code == '403':
                logger.error(f"Access denied to S3 bucket '{self.bucket_name}'")
            else:
                logger.error(f"S3 connection error: {e}")
            raise
    
    async def upload_audio_file(
        self, 
        file: UploadFile, 
        user_id: str, 
        sentence_id: str
    ) -> Tuple[str, str]:
        """
        Upload audio file to S3
        Returns: (s3_key, public_url)
        """
        if not self.s3_client or not self.bucket_name:
            raise HTTPException(
                status_code=500,
                detail="S3 storage not configured"
            )
        
        try:
            # Generate unique filename
            file_extension = os.path.splitext(file.filename)[1]
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            
            # Create S3 key with organized structure
            s3_key = f"audio/{user_id[:2]}/{user_id}/{sentence_id}/{unique_filename}"
            
            # Read file content
            content = await file.read()
            
            # Upload to S3 with metadata
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=s3_key,
                Body=content,
                ContentType='audio/wav',
                Metadata={
                    'user_id': user_id,
                    'sentence_id': sentence_id,
                    'original_filename': file.filename or 'unknown',
                    'upload_source': 'mobile_app'
                },
                ServerSideEncryption='AES256'  # Encrypt at rest
            )
            
            # Generate public URL (or use CloudFront if configured)
            public_url = f"https://{self.bucket_name}.s3.{self.region}.amazonaws.com/{s3_key}"
            
            logger.info(f"Successfully uploaded audio to S3: {s3_key}")
            return s3_key, public_url
            
        except ClientError as e:
            logger.error(f"S3 upload failed: {e}")
            raise HTTPException(
                status_code=500,
                detail="Failed to upload audio file to cloud storage"
            )
    
    def generate_presigned_url(
        self, 
        s3_key: str, 
        expiration: int = 3600
    ) -> Optional[str]:
        """Generate presigned URL for secure audio access"""
        if not self.s3_client:
            return None
        
        try:
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': self.bucket_name, 'Key': s3_key},
                ExpiresIn=expiration
            )
            return url
        except ClientError as e:
            logger.error(f"Failed to generate presigned URL: {e}")
            return None
    
    async def delete_audio_file(self, s3_key: str) -> bool:
        """Delete audio file from S3"""
        if not self.s3_client:
            return False
        
        try:
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            logger.info(f"Successfully deleted audio from S3: {s3_key}")
            return True
        except ClientError as e:
            logger.error(f"Failed to delete audio from S3: {e}")
            return False
    
    async def copy_to_validated_folder(self, s3_key: str) -> Optional[str]:
        """Copy validated audio to separate folder for TTS training"""
        if not self.s3_client:
            return None
        
        try:
            # Create new key in validated folder
            filename = os.path.basename(s3_key)
            validated_key = f"validated_audio/{filename}"
            
            # Copy object
            copy_source = {'Bucket': self.bucket_name, 'Key': s3_key}
            self.s3_client.copy_object(
                CopySource=copy_source,
                Bucket=self.bucket_name,
                Key=validated_key,
                MetadataDirective='COPY'
            )
            
            logger.info(f"Successfully copied to validated folder: {validated_key}")
            return validated_key
            
        except ClientError as e:
            logger.error(f"Failed to copy to validated folder: {e}")
            return None

class LocalStorageService:
    """Local file storage service as fallback"""
    
    def __init__(self):
        self.storage_path = settings.AUDIO_STORAGE_PATH
        self.validated_path = os.path.join(self.storage_path, "validated")
        
        # Create directories if they don't exist
        os.makedirs(self.storage_path, exist_ok=True)
        os.makedirs(self.validated_path, exist_ok=True)
    
    async def upload_audio_file(
        self, 
        file: UploadFile, 
        user_id: str, 
        sentence_id: str
    ) -> Tuple[str, str]:
        """Save audio file locally"""
        try:
            # Generate unique filename
            file_extension = os.path.splitext(file.filename)[1]
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            
            # Create organized directory structure
            user_dir = os.path.join(self.storage_path, user_id[:2], user_id)
            os.makedirs(user_dir, exist_ok=True)
            
            file_path = os.path.join(user_dir, unique_filename)
            
            # Save file
            content = await file.read()
            with open(file_path, "wb") as f:
                f.write(content)
            
            logger.info(f"Successfully saved audio locally: {file_path}")
            return file_path, file_path
            
        except Exception as e:
            logger.error(f"Local storage failed: {e}")
            raise HTTPException(
                status_code=500,
                detail="Failed to save audio file"
            )

# Global storage service instances
s3_service = S3StorageService()
local_service = LocalStorageService()

def get_storage_service():
    """Get appropriate storage service based on configuration"""
    if (s3_service.s3_client and 
        settings.AWS_BUCKET_NAME and 
        settings.AWS_ACCESS_KEY_ID):
        return s3_service
    else:
        logger.info("Using local storage service")
        return local_service

# Export the default storage service instance
storage_service = get_storage_service()
