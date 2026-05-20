# Xelkoom Data Collection Mobile App

A Flutter mobile application for collecting Wolof audio data for Text-to-Speech training.

## Features

- User authentication (login/register)
- Sentence browsing and recording
- Audio recording with quality validation
- Progress tracking
- Profile management
- Offline support with sync

## Getting Started

### Prerequisites

- Flutter SDK (3.29.2 or later)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository
2. Navigate to the mobile_app directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Configure the backend URL in `lib/config/app_config.dart`
5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── providers/       # State management (Riverpod)
├── repositories/    # Data layer
├── screens/         # UI screens
├── services/        # External services
├── utils/           # Utilities
└── widgets/         # Reusable UI components
```

## Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Audio Recording**: flutter_sound
- **Local Storage**: Hive
- **Animations**: Lottie

## API Integration

The app connects to the FastAPI backend for:
- User authentication
- Sentence management
- Audio uploads
- Progress tracking

## Audio Recording

- Records in WAV format (mono, 16kHz)
- Validates audio quality
- Trims silence automatically
- Handles permissions

## Offline Support

- Caches sentences locally
- Queues audio uploads
- Syncs when connected

## Contributing

1. Follow Flutter/Dart style guidelines
2. Use type annotations
3. Write tests for critical functionality
4. Follow the existing project structure
