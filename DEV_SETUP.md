# YourGPT iOS SDK - Development Environment Setup

## Prerequisites

### Required Software
- **macOS** (required for iOS development)
- **Xcode** (latest version) - [Mac App Store](https://apps.apple.com/app/xcode/id497799835)
- **Xcode Command Line Tools** - `xcode-select --install`
- **Git** for version control

### Optional Tools
- **CocoaPods** - `sudo gem install cocoapods`
- **Swift Package Manager** (included with Xcode)
- **iOS Simulator** (included with Xcode)

## Quick Start

### 1. Environment Setup
```bash
# Verify Xcode installation
xcode-select --print-path
# Should output: /Applications/Xcode.app/Contents/Developer

# Install command line tools if needed
xcode-select --install

# Verify Swift installation
swift --version

# Install CocoaPods (if using CocoaPods)
sudo gem install cocoapods
pod setup
```

### 2. Clone and Setup SDK
```bash
# Clone the repository
git clone https://github.com/YourGPT/yourgpt-widget-sdk-ios.git
cd yourgpt-widget-sdk-ios

# Open the example project
open Example/YourGPTExample.xcodeproj
```

### 3. Running the Example App

#### Using Xcode (Recommended)
1. **Open Project**: Open `Example/YourGPTExample.xcodeproj` in Xcode
2. **Select Target**: Choose iPhone simulator or connected device
3. **Build & Run**: Press Cmd+R or click the play button

#### Using Command Line
```bash
# Build the project
xcodebuild -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample -sdk iphonesimulator -configuration Debug build

# Run on simulator
xcrun simctl boot "iPhone 14"
xcrun simctl install booted /path/to/YourGPTExample.app
xcrun simctl launch booted com.yourgpt.example
```

## Development Workflow

### Working with Local SDK

The example app is configured to use the local SDK source code:

#### Swift Package Manager (Recommended)
1. **Add Local Package**:
   - In Xcode: File → Add Package Dependencies
   - Choose "Add Local..."
   - Select the `yourgpt-widget-sdk-ios` folder
   - Add `YourGPTSDK` target to your app

2. **Local Development**:
   ```swift
   // In your app, import the SDK
   import YourGPTSDK
   
   // Changes to SDK source files will automatically be reflected
   ```

#### CocoaPods Alternative
```ruby
# In your Podfile
pod 'YourGPTSDK', :path => '../'

# Then run
pod install
```

### Hot Reloading

Changes to SDK source files will automatically trigger rebuilds:

1. **Edit SDK Files**: Modify files in `Sources/YourGPTSDK/`
2. **Build**: Xcode will automatically rebuild
3. **Run**: Changes reflected immediately

## Testing the SDK

### 1. Basic Functionality Test
```swift
// In ViewController.swift, verify these features work:
1. SDK initialization with valid widgetUid
2. Loading states display correctly
3. Error handling with invalid configuration
4. WebView loads the widget successfully
5. Bidirectional communication (send message, receive events)
```

### 2. Debug Mode Testing
```swift
// Enable debug mode in the example app
let config = YourGPTConfig(
    widgetUid: "widget_123456",
    debug: true // Enable detailed logging
)
```

### 3. Device Testing

#### iOS Simulator Testing
```bash
# List available simulators
xcrun simctl list devices

# Boot a specific simulator
xcrun simctl boot "iPhone 14 Pro"

# Run app on specific simulator
xcodebuild -project Example/YourGPTExample.xcodeproj \
    -scheme YourGPTExample \
    -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
    build
```

#### Physical Device Testing
1. **Connect Device**: Connect iPhone/iPad via USB
2. **Trust Computer**: Follow on-device prompts
3. **Developer Account**: Sign in with Apple Developer account in Xcode
4. **Provisioning**: Xcode will handle automatic provisioning
5. **Run**: Select your device and run

## Development Commands

### Building
```bash
# Build for simulator
xcodebuild -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample -sdk iphonesimulator -configuration Debug build

# Build for device
xcodebuild -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample -sdk iphoneos -configuration Debug build

# Build for release
xcodebuild -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample -configuration Release build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample -destination 'platform=iOS Simulator,name=iPhone 14'

# Run on specific simulator
xcodebuild test -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'
```

### Cleaning
```bash
# Clean build folder
xcodebuild clean -project Example/YourGPTExample.xcodeproj -scheme YourGPTExample

# Or in Xcode: Product → Clean Build Folder (Cmd+Shift+K)
```

## Debugging

### Xcode Debugger
1. **Set Breakpoints**: Click in the gutter next to line numbers
2. **Run with Debugger**: Press Cmd+R
3. **Debug Console**: View → Debug Area → Show Debug Area
4. **Variables**: Inspect variables in the debug area

### Console Logging
```swift
// Use print statements for basic logging
print("Debug message")

// Use os_log for advanced logging
import os
let logger = Logger(subsystem: "com.yourgpt.sdk", category: "general")
logger.debug("Debug message")
logger.info("Info message")
logger.error("Error message")
```

### Memory Debugging
1. **Memory Graph**: Debug → View Memory → Memory Graph
2. **Leaks Instrument**: Product → Profile → Leaks
3. **Allocations Instrument**: Product → Profile → Allocations

### Network Debugging
1. **Network Link Conditioner**: Test with poor network conditions
2. **Proxy Tools**: Use Charles Proxy or similar
3. **WebView Debugging**: Enable in Safari Developer menu

### WebView Debugging
1. **Enable Safari Developer Menu**: Safari → Preferences → Advanced → Show Develop menu
2. **Connect Device**: Connect iOS device or use simulator
3. **Inspect WebView**: Develop → [Device Name] → [WebView Page]

## Xcode Configuration

### Project Settings
```bash
# Key settings for the example project:
- Deployment Target: iOS 12.0+
- Swift Version: 5.0+
- Signing: Automatic (for development)
- Bundle Identifier: com.yourgpt.example
```

### Build Settings
```bash
# Important build settings:
IPHONEOS_DEPLOYMENT_TARGET = 12.0
SWIFT_VERSION = 5.0
ENABLE_BITCODE = NO (if needed for WebKit)
ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES
```

### Capabilities
Enable these capabilities if needed:
- App Transport Security Exception (for HTTP URLs)
- Background Modes (if supporting background WebView)

## Advanced Development

### Custom Build Configurations
```bash
# Create additional build configurations
# In Xcode: Project → Info → Configurations
# Duplicate Debug/Release configurations for different environments
```

### Schemes
```bash
# Create custom schemes for different testing scenarios
# In Xcode: Product → Scheme → Manage Schemes
# Add schemes for different widget configurations
```

### Unit Testing
```swift
// Create unit tests for SDK functionality
import XCTest
@testable import YourGPTSDK

class YourGPTSDKTests: XCTestCase {
    func testSDKInitialization() {
        let config = YourGPTConfig(widgetUid: "test123")
        // Test initialization logic
    }
}
```

### UI Testing
```swift
// Create UI tests for user interactions
import XCUITest

class YourGPTUITests: XCTestCase {
    func testChatbotOpening() {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Open Chatbot"].tap()
        // Test UI interactions
    }
}
```

## Performance Testing

### Instruments
```bash
# Profile with different instruments
# Product → Profile → Choose Instrument:

# Time Profiler - CPU usage
# Allocations - Memory usage
# Leaks - Memory leaks
# Network - Network requests
# Energy Log - Battery usage
```

### Performance Metrics
Monitor these metrics:
- App launch time
- Memory usage during WebView loading
- CPU usage during JavaScript execution
- Network request performance
- Battery usage

## Common Issues & Solutions

### Build Issues
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset simulators
xcrun simctl shutdown all
xcrun simctl erase all

# Reinstall command line tools
sudo xcode-select --reset
xcode-select --install
```

### Simulator Issues
```bash
# Reset simulator
xcrun simctl shutdown all
xcrun simctl erase all

# Kill simulator processes
sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService
```

### Signing Issues
1. **Check Apple Developer Account**: Verify account status
2. **Provisioning Profiles**: Refresh in Xcode preferences
3. **Certificates**: Ensure valid development certificates
4. **Bundle ID**: Verify unique bundle identifier

### WebView Issues
1. **ATS Settings**: Configure App Transport Security
2. **Network Permissions**: Check Info.plist settings
3. **JavaScript**: Verify JavaScript is enabled
4. **CORS**: Check cross-origin policies

## CI/CD Setup

### GitHub Actions Example
```yaml
# .github/workflows/ios.yml
name: iOS CI

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build and Test
      run: |
        xcodebuild test -project Example/YourGPTExample.xcodeproj \
          -scheme YourGPTExample \
          -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Fastlane Integration
```ruby
# Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(
      project: "Example/YourGPTExample.xcodeproj",
      scheme: "YourGPTExample",
      device: "iPhone 14"
    )
  end
  
  desc "Build for testing"
  lane :build do
    build_app(
      project: "Example/YourGPTExample.xcodeproj",
      scheme: "YourGPTExample"
    )
  end
end
```

## Release Testing

### Pre-release Checklist
- [ ] Test on multiple iOS versions (iOS 12+)
- [ ] Test on different device sizes (iPhone, iPad)
- [ ] Test on physical devices
- [ ] Verify all SDK methods work correctly
- [ ] Test error handling scenarios
- [ ] Performance testing with Instruments
- [ ] Memory leak testing
- [ ] Network interruption testing
- [ ] App Store submission preparation

### Distribution
```bash
# Archive for distribution
xcodebuild archive -project Example/YourGPTExample.xcodeproj \
  -scheme YourGPTExample \
  -archivePath YourGPTExample.xcarchive

# Export IPA
xcodebuild -exportArchive -archivePath YourGPTExample.xcarchive \
  -exportPath . \
  -exportOptionsPlist ExportOptions.plist
```

## Support Resources

### Documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Documentation](https://swift.org/documentation/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit)

### Tools
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [Instruments User Guide](https://help.apple.com/instruments/)
- [iOS Simulator User Guide](https://help.apple.com/simulator/)

### Community
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Swift Forums](https://forums.swift.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/ios)