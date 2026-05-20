#!/usr/bin/env python3
"""
Script to configure balance settings
"""
import os
from pathlib import Path

def create_env_file():
    """Create or update .env file with balance settings"""
    
    env_path = Path(__file__).parent / ".env"
    
    # Default configuration
    balance_config = """
# Data Collection Balance Settings
TARGET_RECORDINGS_PER_SENTENCE=5
MAX_RECORDINGS_PER_SENTENCE=10
BALANCED_SELECTION_ENABLED=true
"""
    
    if env_path.exists():
        # Read existing content
        with open(env_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if balance settings already exist
        if "TARGET_RECORDINGS_PER_SENTENCE" not in content:
            # Append balance settings
            with open(env_path, 'a', encoding='utf-8') as f:
                f.write(balance_config)
            print("✅ Added balance settings to existing .env file")
        else:
            print("ℹ️  Balance settings already exist in .env file")
    else:
        # Create new .env file with all necessary settings
        full_config = """# Database
DATABASE_URL=sqlite:///./xelkoom.db

# JWT
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Audio storage
AUDIO_STORAGE_PATH=./audio/
MAX_AUDIO_SIZE_MB=10

# Development
DEBUG=true
ENVIRONMENT=development

# Default admin user
DEFAULT_ADMIN_USERNAME=admin
DEFAULT_ADMIN_PASSWORD=admin123

# Data Collection Balance Settings
TARGET_RECORDINGS_PER_SENTENCE=5
MAX_RECORDINGS_PER_SENTENCE=10
BALANCED_SELECTION_ENABLED=true
"""
        with open(env_path, 'w', encoding='utf-8') as f:
            f.write(full_config)
        print("✅ Created new .env file with balance settings")
    
    # Show current configuration
    print("\n📋 Current Balance Configuration:")
    print(f"Target recordings per sentence: 5")
    print(f"Max recordings per sentence: 10")
    print(f"Balanced selection enabled: true")
    
    print("\n💡 You can modify these values in the .env file:")
    print(f"  {env_path}")

def main():
    """Main function"""
    print("🔧 Configuring Balance Settings")
    print("=" * 40)
    
    create_env_file()
    
    print("\n📖 How it works:")
    print("1. Sentences with < 5 recordings get higher priority")
    print("2. Sentences with 5-9 recordings get medium priority")
    print("3. Sentences with 10+ recordings get low priority")
    print("4. Selection is weighted randomly based on these priorities")
    
    print("\n🚀 To test the new logic:")
    print("  python test_balanced_selection.py")

if __name__ == "__main__":
    main()
