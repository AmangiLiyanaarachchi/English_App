# Voice Call Troubleshooting Guide

## Problem: Two Phones Can't Hear Each Other

### What We've Fixed
1. ✅ Added comprehensive logging throughout the call flow
2. ✅ Fixed native AudioManager fallback for speaker control
3. ✅ Added audio volume indication to detect speech
4. ✅ Added connection state monitoring
5. ✅ Fixed UI overflow in chat detail screen

### Testing Checklist

#### BEFORE TESTING
- [ ] Both phones have stable internet connection (WiFi or 4G)
- [ ] Both phones have microphone permission granted
- [ ] Both phones are running the SAME version of the app
- [ ] Clear app data on both phones (Settings → Apps → English App → Clear Data)
- [ ] Restart both phones

#### STEP-BY-STEP TEST PROCEDURE

**Phone A (Caller):**
1. Open the app and login with User A
2. Navigate to home screen
3. Find User B in the contacts/users list
4. Tap the call button next to User B
5. **IMPORTANT: Wait and watch the logs**

**Phone B (Receiver):**
1. Open the app and login with User B
2. Keep the app in the foreground
3. Wait for incoming call screen
4. Accept the call
5. **IMPORTANT: Watch the logs**

### What to Look for in Logs

#### 1. Channel ID Matching (CRITICAL!)
Look for these lines on **BOTH** phones:
```
🎬 CHANNEL: Generated channel ID: "XXXXXXXX_YYYYYYYY"
```
**The channel IDs MUST BE IDENTICAL on both phones!**

If they're different:
- ❌ Users are in different channels
- ❌ They will NEVER detect each other
- ❌ Fix: Check user IDs match in Firestore

#### 2. Successful Join (Both Phones)
```
✅ AGORA EVENT: onJoinChannelSuccess - Channel: XXXXXXXX_YYYYYYYY
```

#### 3. Remote User Detection (MOST CRITICAL!)
**This should appear on BOTH phones:**
```
👤 AGORA EVENT: onUserJoined - Remote UID: XXXXX joined
```

**If you DON'T see onUserJoined:**
- Problem: Phones are not detecting each other
- Possible causes:
  1. Different channel names
  2. Network firewall blocking Agora
  3. App running different versions
  4. Agora SDK initialization failed

#### 4. Audio Route
```
🔊 AGORA EVENT: Audio route changed to: AudioRouteSpeakerphone
```

#### 5. Audio Activity
```
🎤 AGORA EVENT: Audio detected - X speakers, Total volume: YYY
```

### Common Problems and Solutions

#### Problem 1: "onUserJoined" never fires
**Symptoms:**
- Both users join successfully
- No remote user detected
- Error -3 when enabling speaker

**Solutions:**
```bash
# 1. Check if both phones are using the same channel
#    Compare the logs for "Generated channel ID"

# 2. Verify both users are logged in with correct UIDs
#    Check Firebase Auth current user

# 3. Try with different network
#    Switch from WiFi to mobile data or vice versa

# 4. Check Agora service status
#    Visit: https://console.agora.io
```

#### Problem 2: Different Channel IDs
**Symptoms:**
```
Phone A: 🎬 CHANNEL: Generated channel ID: "AAA_BBB"
Phone B: 🎬 CHANNEL: Generated channel ID: "XXX_YYY"
```

**Solution:**
- Check that both phones are calling each other (not two separate calls)
- Verify the call document in Firestore
- Check user IDs are consistent

#### Problem 3: One phone joins, other doesn't
**Symptoms:**
- Only one phone shows "onJoinChannelSuccess"
- Other phone shows error or timeout

**Solutions:**
1. Check network connection on failing phone
2. Verify microphone permission granted
3. Clear app data and try again
4. Check if device is in "Do Not Disturb" mode

#### Problem 4: Both join but no audio
**Symptoms:**
- Both show "onUserJoined"  
- No audio transmitted
- No "Audio detected" logs

**Solutions:**
```dart
// 1. Check if muted
//    Look for logs: "Muted: true"

// 2. Verify microphone is working
//    Test with another app (WhatsApp, etc.)

// 3. Check audio route
//    Should be Speakerphone or Earpiece

// 4. Restart Agora engine
//    Leave and rejoin the channel
```

### Debug Commands

Run the app with verbose logging:
```bash
flutter run -d <DEVICE_ID> --verbose
```

Filter Agora logs only:
```bash
# Android
adb logcat | grep -i "agora\|flutter"

# Or use Android Studio Logcat filter:
package:mine tag:flutter|AGORA
```

### Expected Log Sequence

**Phone A (Caller) - Should see:**
```
📞 CALL: Creating call with ID: ...
📞 CALL: Agora Channel: "XXXXXXXX_YYYYYYYY"
📤 HOME: Call created, joining Agora channel: XXXXXXXX_YYYYYYYY
🔊 AGORA: Attempting to join channel: "XXXXXXXX_YYYYYYYY"
✅ AGORA EVENT: onJoinChannelSuccess - Channel: XXXXXXXX_YYYYYYYY
[WAIT FOR PHONE B TO JOIN]
👤 AGORA EVENT: onUserJoined - Remote UID: YYYYY joined
🎤 AGORA EVENT: Audio detected - 2 speakers
```

**Phone B (Receiver) - Should see:**
```
📥 INCOMING: Call accepted, joining Agora channel: XXXXXXXX_YYYYYYYY
🔊 AGORA: Attempting to join channel: "XXXXXXXX_YYYYYYYY"
✅ AGORA EVENT: onJoinChannelSuccess - Channel: XXXXXXXX_YYYYYYYY
👤 AGORA EVENT: onUserJoined - Remote UID: XXXXX joined
🎤 AGORA EVENT: Audio detected - 2 speakers
```

### Network Requirements

Agora requires these ports to be open:
- **UDP**: 1024-65535
- **TCP**: 1024-65535

If you're on a corporate/school WiFi, these may be blocked.

**Test on mobile data first** to rule out network issues.

### Still Not Working?

If you see **onUserJoined on both phones** but still no audio:

1. **Check device volume:**
   - Volume must be > 0 on both phones
   - Check both media and call volume

2. **Test speakers/mic:**
   ```bash
   # Open phone dialer and call:
   *#*#7378423#*#*  (Sony)
   *#0*#             (Samsung)
   # Test speaker and mic
   ```

3. **Try different devices:**
   - Some devices have audio routing issues
   - Test with different phone models

4. **Check Agora App ID:**
   - Verify it's correct in `agora_service.dart`
   - App ID: `ea75dc54a4aa480db3f7d5cb6eef54ed`

### Report Issues

When reporting problems, include:
1. ✅ Both phones' complete logs (from app start to call end)
2. ✅ Phone models and Android versions
3. ✅ Network type (WiFi/4G/5G)
4. ✅ Screenshot of Firestore call document
5. ✅ Whether "onUserJoined" appeared on either phone

### Quick Test

Run this to verify channel ID generation:
```dart
// In Dart DevTools console
String user1 = "ABC123";
String user2 = "XYZ789";
var ids = [user1, user2]..sort();
print('Channel: ${ids[0]}_${ids[1]}');

// Now reverse order
user1 = "XYZ789";
user2 = "ABC123";
ids = [user1, user2]..sort();
print('Channel: ${ids[0]}_${ids[1]}');

// Both should print the SAME channel ID
```

---

## Emergency Reset

If nothing works:

```bash
# 1. Uninstall app from both phones
adb uninstall com.example.english_app

# 2. Clear Flutter build cache
flutter clean

# 3. Rebuild
flutter pub get
flutter build apk --debug

# 4. Reinstall on both phones
flutter install -d <DEVICE1_ID>
flutter install -d <DEVICE2_ID>

# 5. Grant permissions manually in Settings
#    Settings → Apps → English App → Permissions → Microphone → Allow

# 6. Test again following the step-by-step procedure
```
