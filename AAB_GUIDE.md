# PayTrack Premium - AAB Build Guide 📱

## About AAB (Android App Bundle) Files

AAB files are **better than APK** files for several reasons:

### ✅ **Advantages of AAB over APK:**
- **Smaller Download** - Only downloads resources needed for your device
- **Google Play Ready** - Native format for Play Store
- **Dynamic Delivery** - Features can be downloaded on-demand  
- **Better Performance** - Optimized for specific device configurations
- **Automatic Signing** - Google Play handles app signing

## 🚀 **Getting Your AAB File**

### **Method 1: GitHub Actions (Recommended)**
1. Go to [GitHub Actions](https://github.com/anilchowdary07/paytrack-app/actions)
2. Find "Build AAB (Android App Bundle)" workflow
3. Download the `paytrack-premium-aab` artifact
4. Or check [Releases](https://github.com/anilchowdary07/paytrack-app/releases) for AAB file

### **Method 2: Manual Build**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
Find AAB at: `build/app/outputs/bundle/release/app-release.aab`

## 📱 **Installing AAB Files**

### **Option 1: Convert to APK (For Direct Install)**
```bash
# Install bundletool
brew install bundletool  # macOS
# or download from: https://github.com/google/bundletool

# Convert AAB to APK
bundletool build-apks --bundle=app-release.aab --output=app.apks

# Extract APK for installation
bundletool extract-apks --apks=app.apks --output-dir=./
```

### **Option 2: Upload to Google Play Store**
1. Create Google Play Console account
2. Upload the `.aab` file directly
3. Google Play will generate optimized APKs for users

### **Option 3: Side-loading via ADB**
```bash
# Install directly from AAB
bundletool install-apks --apks=app.apks
```

## 🎯 **PayTrack Premium Features**

Your AAB includes all premium features:
- **💰 Payment Reminders** - Never miss due dates
- **📊 Spending Analytics** - Visual insights and charts
- **📅 Calendar View** - Monthly payment overview
- **💳 Budget Management** - Real-time spending limits
- **📈 Financial Reports** - Detailed spending analysis
- **🔔 Smart Notifications** - Timely payment alerts
- **👤 Profile Management** - Personalized settings

## 📦 **File Information**

- **Format**: Android App Bundle (.aab)
- **Target SDK**: 34 (Android 14)
- **Min SDK**: 21 (Android 5.0+)
- **Architecture**: Universal (ARM64, ARM, x86)
- **Size**: Optimized per device (~15-25MB typical)

## 🔧 **Troubleshooting**

### If AAB conversion fails:
1. Ensure bundletool is installed
2. Check Java version (requires Java 8+)
3. Use alternative: Upload AAB to Google Play directly

### For direct APK:
- Use the web version: https://anilchowdary07.github.io/paytrack-app/
- Works perfectly on mobile browsers
- Can be installed as PWA

---

**AAB files are the future of Android app distribution!** 🚀
