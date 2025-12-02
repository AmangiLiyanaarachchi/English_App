# EnglishCircle - Quick Setup Commands

## Get SHA-1 Fingerprint (Required for Google Sign-In)
cd android
./gradlew signingReport

## Install Dependencies
flutter pub get

## Run on Device
flutter devices
flutter run -d <DEVICE_ID>

## Clean Build (if issues occur)
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run

## Check for Errors
flutter doctor -v
flutter analyze

## Update Firebase
# After getting SHA-1:
# 1. Go to Firebase Console
# 2. Add SHA-1 to your Android app
# 3. Download new google-services.json
# 4. Replace android/app/google-services.json

## Test Google Sign-In
# Must use REAL device with Google account
flutter run -d R9YR8086S5T
