# How to Run the iOS SDK Example App

## 🚀 Complete Step-by-Step Guide

Follow these instructions to run the enhanced iOS SDK example app with the new support screen and mobile data features.

## 📋 **Prerequisites**

### **System Requirements**
- **macOS**: 12.0+ (Monterey or later)
- **Xcode**: 14.0+ 
- **iOS Simulator**: iOS 13.0+ or physical device
- **Command Line Tools**: `xcode-select --install`

### **Check Your Setup**
```bash
# Verify Xcode installation
xcode-select -p

# Check available simulators
xcrun simctl list devices
```

## 🛠️ **Setup Instructions**

### **Step 1: Navigate to Project Directory**
```bash
cd "/Users/superman41/Drive/AI/Widget Mobile SDK/ios-sdk"
```

### **Step 2: Open Xcode Project**
```bash
# Open the example project in Xcode
open Example/YourGPTExample.xcodeproj
```

### **Step 3: Add SupportHomeViewController to Project**

#### **Method A: Using Xcode (Recommended)**
1. In Xcode Project Navigator, **right-click** on `YourGPTExample` folder
2. Select **"Add Files to 'YourGPTExample'..."**
3. Navigate to: `Example/YourGPTExample/SupportHomeViewController.swift`
4. Select the file and ensure:
   - ✅ **"Add to target: YourGPTExample"** is checked
   - ✅ **"Copy items if needed"** is checked
5. Click **"Add"**

#### **Method B: Drag & Drop**
1. Open **Finder** and locate: `Example/YourGPTExample/SupportHomeViewController.swift`
2. **Drag** the file into Xcode's Project Navigator
3. Drop it in the `YourGPTExample` folder
4. In the dialog:
   - ✅ **"Copy items if needed"**
   - ✅ **"Add to target: YourGPTExample"**
5. Click **"Finish"**

### **Step 4: Update SceneDelegate**
After adding the file, edit `SceneDelegate.swift`:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    
    let mainViewController: UIViewController
    if #available(iOS 13.0, *) {
        mainViewController = SupportHomeViewController()  // Use new support screen
    } else {
        mainViewController = ViewController()             // Fallback for older iOS
    }
    
    let navigationController = UINavigationController(rootViewController: mainViewController)
    
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
}
```

### **Step 5: Select Target and Simulator**
1. In Xcode toolbar, click the **scheme selector** (next to play button)
2. Select **"YourGPTExample"** as the scheme
3. Choose target:
   - **iOS Simulator**: Select "iPhone 15 Pro" or similar
   - **Physical Device**: Connect iPhone/iPad and select it

### **Step 6: Build and Run**
```bash
# Clean build folder (recommended)
Cmd + Shift + K

# Build the project
Cmd + B

# Run the app
Cmd + R
```

**Or use Xcode menu**: `Product` → `Run`

## 📱 **What You'll See**

### **🏠 Support Home Screen**
When the app launches, you'll see:

#### **Header Section**
- **Title**: "Help & Support" with large title navigation
- **Welcome Message**: "👋 How can we help you today?"
- **Subtitle**: "Get instant help or chat with our AI assistant"

#### **Status Card**
- **Connection Indicator**: Colored dot showing SDK status
- **Status Text**: 
  - 🔄 "Connecting to AI Assistant..." (orange)
  - ✅ "AI Assistant Ready" (green) 
  - ❌ "Connection Failed" (red)
- **Chat Button**: Enabled only when ready

#### **Quick Actions Section**
Four interactive cards:
- 💬 **Start a Conversation** → Opens AI chat
- 📧 **Email Support** → Demo email action
- 📞 **Call Support** → Demo call action  
- 🔍 **Search Help Articles** → Demo search action

#### **FAQ Section**
Common support questions with answers:
- How do I reset my password?
- How do I update my payment method?
- How do I cancel my subscription?
- How do I contact support?

### **💬 Enhanced Chat Experience**
When you tap **"Chat"** (after SDK shows ready):

#### **Modern Sheet Presentation**
- **Sheet-style modal** (not full-screen)
- **Grabber handle** at top (iOS 15+)
- **Navigation bar** with "AI Assistant" title
- **Close button (X)** in top-right corner

#### **Loading States**
- **Initial Loading**: "🤖 Connecting to AI Assistant"
- **Progress Message**: "Just a moment while we set things up..."
- **Error States**: Clear error messages with retry button

#### **Automatic Data Injection**
The app automatically sends demo data to the widget:

```swift
// Session Data
{
  "userId": "demo-user-123",
  "plan": "premium",
  "sessionStart": "2024-01-13T10:30:00Z",
  "features": ["ai-actions", "support-chat", "escalation"],
  "userSegment": "premium-support"
}

// Visitor Data (auto-enriched with iOS info)
{
  "source": "support-screen",
  "platform": "iOS",
  "deviceModel": "iPhone",
  "systemVersion": "17.2",
  "appVersion": "1.0",
  "screenSize": "393x852"
}

// Contact Data
{
  "email": "demo@example.com",
  "name": "Demo User",
  "phone": "+1-555-0123",
  "preferredLanguage": "en",
  "timezone": "America/New_York"
}
```

## 🐛 **Troubleshooting**

### **Issue: Build Fails**
```bash
# Clean and rebuild
Cmd + Shift + K
Cmd + B
```

### **Issue: "Cannot find SupportHomeViewController"**
**Solution**: File not added to project
1. Check Project Navigator - file should be visible
2. Select file → File Inspector → ensure "YourGPTExample" target is checked
3. Re-add file if necessary

### **Issue: App Crashes on Launch**
**Solution**: Check iOS version
- App requires iOS 13.0+
- Use iOS 13+ simulator or device

### **Issue: White Screen**
**Solution**: Check SceneDelegate setup
1. Ensure SceneDelegate is properly configured
2. Verify window setup is correct
3. Check navigation controller initialization

### **Issue: Widget Won't Load**
**Solution**: Check network and widget UID
1. Ensure internet connection (simulator or device)
2. Verify widget UID: `232d2602-7cbd-4f6a-87eb-21058599d594`
3. Check console logs for detailed error messages

## 📊 **Console Debugging**

### **Enable Debug Logging**
The app includes extensive logging. In Xcode, open **Console** (`View` → `Debug Area` → `Console`) to see:

```
[YourGPTSDK] Initializing SDK with widgetUid: 232d2602-7cbd-4f6a-87eb-21058599d594
🚀 SDK initialized in WebView
📱 WebView content loaded
🔗 Connection established
⌨️ User is typing
📨 New message received: {...}
👨‍💼 Escalated to human: {...}
```

### **Debug Network Issues**
```swift
// Check widget URL being loaded
print("Loading widget URL: \(widgetURL)")

// Monitor connection state
print("SDK State: \(YourGPTSDK.core.state)")
```

## 🎯 **Testing Features**

### **Test SDK Status**
1. Launch app
2. Watch status card change from "Connecting..." to "Ready"
3. Chat button should become enabled and blue

### **Test Chat Functionality**
1. Tap "Chat" when ready
2. Verify sheet presentation with close button
3. Check console for data injection logs
4. Test typing in chat interface

### **Test Data Management**
1. Monitor console logs during chat launch
2. Verify session, visitor, and contact data injection
3. Check iOS-specific data enrichment

### **Test Error Handling**
1. Disconnect internet
2. Launch app to see error states
3. Reconnect and test retry functionality

## 📂 **Project Structure**

```
ios-sdk/
├── Sources/YourGPTSDK/
│   ├── YourGPTSDK.swift
│   ├── YourGPTSDKCore.swift
│   ├── YourGPTConfig.swift
│   └── YourGPTChatbotViewController.swift  ← Enhanced with data management
├── Example/
│   ├── YourGPTExample.xcodeproj
│   └── YourGPTExample/
│       ├── AppDelegate.swift
│       ├── SceneDelegate.swift               ← Updated to use SupportHomeViewController
│       ├── ViewController.swift              ← Original simple demo
│       ├── SupportHomeViewController.swift   ← New professional support screen
│       ├── Main.storyboard
│       ├── LaunchScreen.storyboard
│       └── Assets.xcassets/
└── Package.swift
```

## 🚀 **Alternative: Command Line Build**

If you prefer command line:

```bash
# Navigate to project
cd "/Users/superman41/Drive/AI/Widget Mobile SDK/ios-sdk/Example"

# Build for simulator
xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build

# Run in simulator
open -a Simulator
xcrun simctl install booted "build/path/to/YourGPTExample.app"
xcrun simctl launch booted com.yourcompany.yourgptexample
```

---

**Once running, you'll have a professional iOS support app demonstrating the full mobile SDK capabilities with modern sheet presentation, real-time status monitoring, and comprehensive data management features!**