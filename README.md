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

### Demo Screenshots

Here's how the YourGPT chatbot looks in action:

![AI Assistant Chat Interface](demo-screenshot-1.png)
*Clean, modern chat interface with AI assistant ready to help*

![Chat Conversation Example](demo-screenshot-2.png)
*Example conversation showing the AI assistant providing detailed, helpful responses*

### Step 1: Create a Wrapper Class (Recommended)

For better organization and reusability, create a wrapper class to manage the SDK:

```swift
import UIKit
import YourGPTSDK
import Combine

@available(iOS 13.0, *)
class YourGPTWrapper: NSObject {
    
    static let shared = YourGPTWrapper()
    
    private var cancellables = Set<AnyCancellable>()
    private var chatbotViewController: YourGPTChatbotViewController?
    
    // Configuration
    private let widgetUid = "your-widget-uid"
    
    // State observer
    var onStateChange: ((YourGPTSDKState) -> Void)?
    
    private override init() {
        super.init()
        setupSDKObserver()
    }
    
    private func setupSDKObserver() {
        YourGPTSDK.core.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.onStateChange?(state)
            }
            .store(in: &cancellables)
    }
    
    func initializeSDK() async throws {
        let config = YourGPTConfig(
            widgetUid: widgetUid
        )
        
        try await YourGPTSDK.initialize(config: config)
    }
    
    func openChatbot(from presentingViewController: UIViewController, delegate: YourGPTChatbotDelegate?) {
        guard YourGPTSDK.isReady else {
            showAlert(on: presentingViewController, title: "SDK Not Ready", message: "Please wait for the SDK to initialize.")
            return
        }
        
        chatbotViewController = YourGPTSDK.createChatbotViewController(
            widgetUid: widgetUid
        )
        
        chatbotViewController?.delegate = delegate
        
        let navigationController = UINavigationController(rootViewController: chatbotViewController!)
        navigationController.modalPresentationStyle = .fullScreen
        
        // Add close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeChatbot)
        )
        chatbotViewController?.navigationItem.rightBarButtonItem = closeButton
        
        presentingViewController.present(navigationController, animated: true)
    }
    
    @objc private func closeChatbot() {
        chatbotViewController?.dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
        }
    }
    
    var isReady: Bool {
        return YourGPTSDK.isReady
    }
    
    var currentState: YourGPTSDKState {
        return YourGPTSDK.core.state
    }
    
    private func showAlert(on viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
```

### Step 2: Initialize the SDK in Your View Controller

```swift
import UIKit
import YourGPTSDK

@available(iOS 13.0, *)
class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var openChatButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSDKObserver()
        initializeSDK()
    }
    
    private func setupUI() {
        title = "YourGPT iOS SDK Demo"
        view.backgroundColor = .systemBackground
        
        // Configure button
        openChatButton?.layer.cornerRadius = 8
        openChatButton?.isEnabled = false
        updateStatus("Initializing...")
    }
    
    private func setupSDKObserver() {
        YourGPTWrapper.shared.onStateChange = { [weak self] state in
            self?.updateUIForSDKState(state)
        }
    }
    
    private func initializeSDK() {
        Task {
            do {
                try await YourGPTWrapper.shared.initializeSDK()
            } catch {
                await MainActor.run {
                    self.showAlert(title: "SDK Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func updateUIForSDKState(_ state: YourGPTSDKState) {
        switch state.connectionState {
        case .connected:
            statusLabel?.textColor = .systemGreen
            openChatButton?.isEnabled = true
            updateStatus("Ready - SDK Connected!", color: .systemGreen)
        case .connecting:
            statusLabel?.textColor = .systemOrange
            openChatButton?.isEnabled = false
            updateStatus("Connecting...", color: .systemOrange)
        case .error:
            statusLabel?.textColor = .systemRed
            openChatButton?.isEnabled = false
            if let error = state.error {
                updateStatus("Error: \(error)", color: .systemRed)
            }
        case .disconnected:
            statusLabel?.textColor = .systemGray
            openChatButton?.isEnabled = false
            updateStatus("Disconnected", color: .systemGray)
        }
    }
    
    private func updateStatus(_ text: String, color: UIColor = .systemOrange) {
        statusLabel?.text = "SDK Status: \(text)"
        statusLabel?.textColor = color
    }
    
    @IBAction func openChatTapped(_ sender: UIButton? = nil) {
        YourGPTWrapper.shared.openChatbot(from: self, delegate: self)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Step 3: Implement Delegate Methods

Implement `YourGPTChatbotDelegate` to handle chatbot events:

```swift
extension ViewController: YourGPTChatbotDelegate {
    
    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        print("📨 New message received: \(message)")
        
        DispatchQueue.main.async {
            self.showAlert(
                title: "New Message",
                message: "Received: \(message.description)"
            )
        }
    }
    
    func chatbotDidOpen() {
        print("🚀 Chatbot opened")
    }
    
    func chatbotDidClose() {
        print("📴 Chatbot closed")
        YourGPTWrapper.shared.dismissChatbot()
    }
    
    func chatbotDidFailWithError(_ error: Error) {
        print("❌ Chatbot error: \(error)")
        
        DispatchQueue.main.async {
            self.showAlert(
                title: "Chatbot Error",
                message: error.localizedDescription
            )
        }
    }
    
    func chatbotDidStartLoading() {
        print("⏳ Chatbot started loading")
    }
    
    func chatbotDidFinishLoading() {
        print("✅ Chatbot finished loading")
    }
}
```

### Configuration Options

The `YourGPTConfig` supports various optional parameters:

```swift
YourGPTConfig(
    widgetUid: "your-widget-uid",    // Required: Your widget UID from YourGPT dashboard
    userId: "user-123",              // Optional: Unique user identifier
    authToken: "your-auth-token",    // Optional: Authentication token
    theme: .light,                   // Optional: .light or .dark
    debug: true,                     // Optional: Enable debug logging
)
```

**Minimal Configuration:**
```swift
// Only widgetUid is required
let config = YourGPTConfig(widgetUid: "your-widget-uid")
```

### SDK State Management

The wrapper provides convenient access to SDK state:

```swift
// Check if SDK is ready
if YourGPTWrapper.shared.isReady {
    // Open chatbot
}

// Get current state
let currentState = YourGPTWrapper.shared.currentState

// Monitor state changes
YourGPTWrapper.shared.onStateChange = { state in
    switch state.connectionState {
    case .connected:
        print("SDK Ready")
    case .connecting:
        print("SDK Connecting...")
    case .disconnected:
        print("SDK Disconnected")
    case .error:
        print("SDK Error: \(state.error?.localizedDescription ?? "Unknown")")
    }
}
```

### Complete Example

For a complete working example, see the [Example](./Example) folder which demonstrates:
- **YourGPTWrapper**: A singleton wrapper class for easy SDK management
- **SDK initialization** with async/await and error handling
- **State monitoring** with Combine and UI updates
- **Full-screen chatbot presentation** with navigation controller
- **Delegate method implementations** for all chatbot events
- **UI state management** based on SDK connection state
- **Programmatic UI creation** for both storyboard and code-based approaches

The example includes:
- `YourGPTWrapper.swift` - The wrapper class for SDK management
- `ViewController.swift` - Main view controller with UI and delegate implementation
- `SceneDelegate.swift` - App setup and navigation

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