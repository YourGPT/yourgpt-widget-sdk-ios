# YourGPT iOS SDK

A Swift SDK for integrating YourGPT chatbot widget as a full-screen view in iOS applications.

## Quick Start

### Installation

#### CocoaPods

Add this to your `Podfile`:

```ruby
pod 'YourGPTSDK', '~> 1.0'
```

Then run:
```bash
pod install
```

#### Swift Package Manager

Add the package dependency in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/YourGPT/yourgpt-widget-sdk-ios.git`
3. Select version `1.0.0`

Or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourGPT/yourgpt-widget-sdk-ios.git", from: "1.0.0")
]
```

### Development Environment Setup

For local development and testing, see [DEV_SETUP.md](./DEV_SETUP.md) for detailed instructions on:
- Setting up Xcode development environment
- Running the example app locally in Xcode and iOS Simulator
- Testing on physical iOS devices
- Debugging with Xcode tools and Instruments
- Performance testing and memory profiling

## Usage

### Basic Implementation

```swift
import YourGPTSDK

class ViewController: UIViewController {
    
    @IBAction func openChatTapped(_ sender: UIButton) {
        let configuration = YourGPTConfiguration(
            projectId: "your-project-id",
            userId: "user123",
            authToken: "your-auth-token",
            theme: .light
        )
        
        let chatbotVC = YourGPTSDK.createChatbotViewController(configuration: configuration)
        chatbotVC.delegate = self
        
        let navController = UINavigationController(rootViewController: chatbotVC)
        navController.modalPresentationStyle = .fullScreen
        
        present(navController, animated: true)
    }
}

extension ViewController: YourGPTChatbotDelegate {
    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        print("New message: \(message)")
    }
    
    func chatbotDidOpen() {
        print("Chat opened")
    }
    
    func chatbotDidClose() {
        print("Chat closed")
        dismiss(animated: true)
    }
}
```

### Configuration Options

```swift
let configuration = YourGPTConfiguration(
    projectId: "your-project-id",    // Required
    userId: "user123",               // Optional
    authToken: "your-auth-token",    // Optional
    theme: .light                    // Optional: .light or .dark
)
```

### Methods

```swift
// Send a message to the chatbot
chatbotViewController.sendMessage("Hello from iOS!")

// Set user context
chatbotViewController.setUserContext([
    "name": "John Doe",
    "email": "john@example.com",
    "plan": "premium"
])

// Open chat programmatically
chatbotViewController.openChat()
```

### Delegate Methods

Implement `YourGPTChatbotDelegate` to handle events:

```swift
func chatbotDidReceiveMessage(_ message: [String : Any]) {
    // Handle new messages from the chatbot
}

func chatbotDidOpen() {
    // Chat interface opened
}

func chatbotDidClose() {
    // Chat interface closed
}
```

## Requirements

- iOS 12.0+
- Xcode 12.0+
- Swift 5.0+

## Permissions

Add network permissions to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Events

The widget sends these events via delegate methods:
- `chatbotDidReceiveMessage` - New message received
- `chatbotDidOpen` - Chat interface opened
- `chatbotDidClose` - Chat interface closed