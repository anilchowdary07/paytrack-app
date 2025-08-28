# PayTrack Premium 💰

A comprehensive financial management app built with Flutter.

## Features ✨

- **Payment Reminders** - Never miss a payment deadline
- **Spending Analytics** - Track your expenses with beautiful charts
- **Calendar Integration** - View all payments in calendar format
- **Smart Notifications** - Get timely reminders
- **Modern UI** - Beautiful animations and smooth user experience
- **Financial Insights** - Understand your spending patterns

## Build Status 🚀

![Build APK](https://github.com/anilchowdary07/paytrack-app/workflows/Build%20APK/badge.svg)

## Getting Started 📱

### Download APK
1. Go to [Releases](https://github.com/anilchowdary07/paytrack-app/releases)
2. Download the latest `app-release.apk`
3. Install on your Android device

### Build Commands
```bash
flutter clean
flutter pub get
flutter build apk
```

### Run in Development
```bash
flutter run
```

### Deploy to FlutLab
1. Go to [FlutLab.io](https://flutlab.io)
2. Create new project
3. Copy content from `lib/main.dart`
4. Copy content from `pubspec.yaml`
5. Build APK directly in browser!

## 📱 App Structure

- **Single File App** - All code in `lib/main.dart` for simplicity
- **Minimal Dependencies** - Only SharedPreferences for local storage
- **No Firebase** - Standalone app with guaranteed build success
- **Material 3 Design** - Modern, premium UI throughout

## 🎯 Key Screens

1. **Welcome** - Animated splash with auto-login detection
2. **Authentication** - Beautiful login/signup forms
3. **Dashboard** - Monthly spending overview with quick actions
4. **Payment Reminders** - Smart status tracking (Overdue, Due Soon, Upcoming)
5. **Spending Tracking** - Daily limits with real-time monitoring
6. **Analytics** - Category breakdown and spending trends
7. **Profile** - Settings and app information

## 📊 Data Storage

All data is stored locally using SharedPreferences:
- User login state
- Payment reminders
- Spending entries
- User preferences

## � Build Configuration

- **Flutter SDK**: ^3.5.0
- **Dependencies**: Minimal (shared_preferences only)
- **Platform**: Android, iOS, Web ready
- **Architecture**: Single-file standalone

## 📝 Version History

- **v1.0.0** - Initial premium release with all core features

---

**PayTrack Premium** - Your Smart Finance Companion
