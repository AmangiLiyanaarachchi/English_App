# EnglishCircle - Quick Start Guide

## 🚀 Getting Started

### Step 1: Configure Agora
Before running the app, you MUST set up Agora:

1. Visit [https://console.agora.io](https://console.agora.io) and create a free account
2. Create a new project and get your **App ID**
3. Open `lib/services/agora_service.dart` and replace:
   ```dart
   static const String appId = 'YOUR_AGORA_APP_ID';
   ```
   with your actual App ID.

### Step 2: Run the App
```bash
flutter run
```

## 📱 How to Use

### First Time Setup
1. **Register**: 
   - Enter your email and password
   - Provide your full name
   - Enter your institute code (e.g., "ENGL101")
   - Select your English level (Beginner/Intermediate/Advanced)
   - Choose your interests (optional)

2. **Login**: Use your email and password

### Main Features

#### 🎤 Audio Pairing
1. Tap the big **"START AUDIO PAIR"** button on home screen
2. App will find a matching partner from your institute
3. You'll be connected via voice call for up to 5 minutes
4. Speak in English! The app tracks your conversation time
5. Earn karma points and badges

#### 💬 Chat
1. After audio calls, you can continue chatting
2. Navigate to **"Chats"** tab
3. Type messages in English
4. If you type non-English text, the app will warn you

#### 🎙️ Recording
1. Tap **"Record"** from home screen
2. Press **"Start Recording"**
3. Speak in English for 30-60 seconds
4. Stop recording and play it back
5. Save to get basic fluency feedback

#### 👤 Profile
1. View your stats: total chats, minutes, karma, streak
2. See your earned badges
3. Update your interests
4. Sign out

## 🏆 Karma & Badges

### Earning Karma
- 2 karma points per minute of conversation
- Complete audio sessions
- Send English messages

### Available Badges
- **Chatty**: Complete 10+ audio chats
- **Fluent Fox**: Accumulate 100+ minutes of conversation
- More badges coming soon!

## 🎯 Tips for Best Experience

### For Better Audio Quality
1. Use headphones
2. Find a quiet place
3. Ensure good internet connection
4. Grant microphone permissions

### For Better Learning
1. Practice daily to maintain your streak
2. Try matching with different levels
3. Record yourself regularly
4. Ask your partner about their interests
5. Use the daily idiom suggestions

### English Practice Topics
The app includes IELTS-style topics:
- Describe your hometown
- Talk about your favorite book
- What are your hobbies?
- Describe a memorable journey
- And many more...

## ⚠️ Troubleshooting

### Audio Call Not Working
- Check microphone permissions
- Verify Agora App ID is correctly configured
- Ensure you have internet connection
- Try restarting the app

### No Partners Available
- Make sure you're using the correct institute code
- Check your internet connection
- Try again during peak hours
- Ask friends to join!

### Messages Not Sending
- Check internet connection
- Verify Firebase is configured correctly
- Try logging out and back in

## 🔧 Configuration Files

### Required Setup
1. **Agora App ID**: `lib/services/agora_service.dart`
2. **Firebase**: Already configured via `firebase_options.dart`

### Optional Configuration
- Modify max audio duration in `audio_chat_screen.dart`
- Adjust English detection threshold in `english_checker.dart`
- Customize matching algorithm in `firebase_service.dart`

## 📊 Understanding Your Stats

### Profile Statistics
- **Chats**: Total audio sessions completed
- **Minutes**: Total conversation time
- **Karma**: Points earned from practice
- **Streak**: Consecutive days of practice

### English Level
- **Beginner**: Just starting with English
- **Intermediate**: Can hold basic conversations
- **Advanced**: Fluent or near-fluent

The app pairs beginners with advanced speakers for better learning!

## 🎨 App Features

### English Enforcement
- Detects non-English text/speech
- Shows friendly reminders
- Provides translation suggestions
- Tracks English percentage

### Daily Content
- New idiom every time you open the app
- Practice phrases and meanings
- Real-world usage examples

### Community Features
- Institute-based matching
- Group chats (coming soon)
- Friend system (coming soon)
- Leaderboards (coming soon)

## 💡 Pro Tips

1. **Set a Goal**: Try to practice 10 minutes daily
2. **Mix Levels**: Talk with both beginners and advanced learners
3. **Record Progress**: Use recording feature weekly to track improvement
4. **Stay Consistent**: Build your streak for motivation
5. **Help Others**: Teaching beginners improves your own skills

## 🆘 Need Help?

### Common Questions

**Q: How long are audio sessions?**
A: Maximum 5 minutes per session.

**Q: Can I talk to the same person again?**
A: The matching is random, but chat history is saved.

**Q: Is my data safe?**
A: Yes! All data is stored securely in Firebase.

**Q: Do I need to pay?**
A: The app is free! Premium features coming soon.

**Q: Can I use it offline?**
A: Some features work offline, but audio calls need internet.

### Contact Support
For technical issues, check the logs or contact your institute admin.

## 🎓 For Institute Admins

### Setting Up for Your Institute
1. Share a unique institute code with students (e.g., "ENGL101")
2. Encourage daily usage
3. Monitor engagement through user stats
4. Consider running challenges and competitions

### Best Practices
- Recommend 15-30 minutes daily practice
- Create themed practice days (debate, movies, etc.)
- Celebrate top karma earners
- Share daily idioms in class

---

**Happy Learning! Practice makes perfect!** 🌟
