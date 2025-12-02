# EnglishCircle - English Speaking Practice App

A Flutter application clone of OpenTalk designed for English Institute communities to practice English through live audio pairing and messaging.

## Features

### Core Features
- **Live Audio Pairing**: Connect with random partners from your institute for English conversation practice
- **Smart Matching**: Algorithm pairs beginners with advanced speakers for optimal learning
- **WhatsApp-style Messaging**: Text chat with English enforcement
- **Recording & Feedback**: Record your practice sessions and get fluency scores
- **Progress Tracking**: Track your chats, minutes, karma points, and earning badges
- **English Enforcement**: AI-powered detection warns users to speak/type in English

### Screens
1. **Login/Register**: Email auth with institute code, English level, and interests
2. **Home**: Start audio pair, daily idioms, streak counter, quick stats
3. **Audio Chat**: 5-minute paired conversations with real-time connection
4. **Chat List**: WhatsApp-style chat rooms
5. **Chat Screen**: Messages with English detection warnings
6. **Recording**: Record audio practice with simple fluency scoring
7. **Profile**: View stats, badges, interests, and settings

## Tech Stack

- **Framework**: Flutter 3.24+
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Voice**: Agora RTC SDK v6.3+
- **AI/ML**: Google ML Kit (English detection via regex)
- **State Management**: Provider
- **Languages**: Dart

## Setup Instructions

### Prerequisites
- Flutter SDK 3.3.3 or higher
- Firebase account
- Agora account (free tier available)

### 1. Install Dependencies
```bash
cd English_App
flutter pub get
```

### 2. Configure Firebase
1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Firebase CLI should have already created `firebase_options.dart`

### 3. Configure Agora
1. Get your Agora App ID from [console.agora.io](https://console.agora.io)
2. Update `lib/services/agora_service.dart`:
   ```dart
   static const String appId = 'YOUR_AGORA_APP_ID';
   ```

### 4. Run the App
```bash
flutter run
```

## Project Structure
```
lib/
├── models/          # User, Message, Recording models
├── screens/         # All UI screens
├── services/        # Firebase, Agora, English checker
└── main.dart        # App entry point
```

## Key Features

- **English Detection**: Regex-based detection with helpful suggestions
- **Karma & Badges**: Earn points and unlock achievements
- **Audio Sessions**: 5-minute max, real-time Agora RTC
- **Smart Matching**: Pairs users by level and institute

## TODO / Premium Features
- [ ] Unlimited audio pairing
- [ ] AI-powered fluency feedback
- [ ] IELTS topic matching
- [ ] Teacher-moderated groups

## License
MIT License - Free to use and modify

**Note**: Replace `YOUR_AGORA_APP_ID` with your actual Agora App ID!
