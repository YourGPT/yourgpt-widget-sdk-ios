# iOS SDK Troubleshooting Guide

## Common Issues and Solutions

### ❌ Error: 'AnyCancellable' is only available in iOS 13.0 or newer

This error can occur if Xcode is showing stale error information or if there are version conflicts.

**Solutions:**

1. **Clean Build Folder in Xcode:**
   ```
   Product → Clean Build Folder (Cmd+Shift+K)
   ```

2. **Reset Package Caches:**
   ```
   File → Packages → Reset Package Caches
   ```

3. **Restart Xcode:**
   - Close Xcode completely
   - Reopen the project

4. **Command Line Clean (if above doesn't work):**
   ```bash
   cd ios-sdk/Example
   xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample clean
   ```

5. **Verify Deployment Target:**
   - In Xcode, select the project file
   - Go to Build Settings
   - Search for "iOS Deployment Target"
   - Ensure it's set to "iOS 13.0" or later

### ✅ Project Configuration

The project is properly configured with:

- **iOS Deployment Target:** 13.0+
- **Swift Package:** YourGPTSDK targeting iOS 13.0+
- **Availability Annotations:** `@available(iOS 13.0, *)` on classes using Combine
- **Info.plist:** MinimumOSVersion set to 13.0

### 🔧 Manual Fix Steps

If you're still seeing the error:

1. **Open project in Xcode:**
   ```bash
   open ios-sdk/Example/YourGPTExample.xcodeproj
   ```

2. **Check the ViewController.swift file:**
   - Should have `@available(iOS 13.0, *)` before the class declaration
   - Should import `Combine` framework

3. **Verify Package Dependency:**
   - In Xcode project navigator, look for "Package Dependencies"
   - Should show "YourGPTSDK" as a local package
   - If missing, go to File → Add Package Dependencies and add the parent directory

4. **Test Build:**
   - Select "iPhone 15 Pro" simulator (or any iOS 17.5+ simulator)
   - Press Cmd+B to build
   - Should build successfully

### 🚀 Running the Demo

Once the build succeeds:

1. **Select a Simulator:**
   - Choose any iPhone simulator with iOS 17.5+
   - iPhone 15, iPhone 15 Pro, iPhone 16, etc.

2. **Run the App:**
   - Press Cmd+R or click the Run button
   - The app should launch and show "YourGPT iOS SDK Demo"

3. **Test SDK Features:**
   - Watch the status change from "Connecting..." to "Ready - SDK Connected!"
   - Tap "Open Chatbot" to test the WebView integration
   - Check console output for debug logs

### 📱 Expected Behavior

**On Launch:**
- Shows "SDK Status: Connecting..." (orange text)
- After ~1 second: "SDK Status: Ready - SDK Connected!" (green text)
- "Open Chatbot" button becomes enabled

**When Opening Chatbot:**
- Full-screen WebView opens
- Navigation bar with "Done" button
- Loads the configured chatbot URL
- Console shows delegate method calls

### 🐛 Still Having Issues?

If the error persists:

1. **Check Xcode Version:**
   - Requires Xcode 13.0+ for iOS 13.0 deployment target
   - Recommended: Xcode 15.0+

2. **Check macOS Version:**
   - Ensure your macOS supports the Xcode version you're using

3. **Create New Project:**
   - If all else fails, create a new project and copy the source files
   - Add the YourGPTSDK package dependency manually

4. **Command Line Build Test:**
   ```bash
   cd ios-sdk/Example
   xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample -configuration Debug build -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5"
   ```
   
   If this succeeds but Xcode shows errors, it's an IDE issue, not a code issue.

### 📋 System Requirements

- **Xcode:** 13.0 or later
- **iOS Deployment Target:** 13.0 or later
- **macOS:** Version compatible with your Xcode version
- **Swift:** 5.5 or later (for async/await support)

The project builds successfully via command line, so any IDE errors are typically resolved by cleaning/restarting Xcode.