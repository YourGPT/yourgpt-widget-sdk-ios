# YourGPT iOS SDK

A Swift SDK for integrating YourGPT chatbot widget as a full-screen view in iOS applications.

## Quick Start

### Installation

#### Swift Package Manager (Recommended)

1. In Xcode, open your project
2. Go to **File → Add Package Dependencies**
3. Enter the repository URL: `https://github.com/YourGPT/yourgpt-widget-sdk-ios.git`
4. Select version `1.0.0` or later
5. Click **Add Package**

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourGPT/yourgpt-widget-sdk-ios.git", from: "1.0.0")
]
```

#### CocoaPods

Add this to your `Podfile`:

```ruby
pod 'YourGPTSDK', '~> 1.0'
```

Then run:
```bash
pod install
```

### Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

### Development Environment Setup

For local development and testing, see [DEV_SETUP.md](./DEV_SETUP.md) for detailed instructions on:
- Setting up Xcode development environment
- Running the example app locally in Xcode and iOS Simulator
- Testing on physical iOS devices
- Debugging with Xcode tools and Instruments
- Performance testing and memory profiling

## Integration Guide

## How to Integrate

Follow these steps to integrate the YourGPT SDK into your iOS app:

### Step 1: Import the SDK

In any file where you want to use the SDK, import it:

```swift
import YourGPTSDK
```

### Step 2: Create a Wrapper Class (Recommended)

Create a new Swift file called `YourGPTWrapper.swift` in your project. This wrapper class helps manage the SDK lifecycle and chatbot presentation:

```swift
import UIKit
import YourGPTSDK
import Combine

@available(iOS 13.0, *)
class YourGPTWrapper: NSObject {

    // Singleton instance
    static let shared = YourGPTWrapper()

    private var cancellables = Set<AnyCancellable>()
    private var chatbotViewController: YourGPTChatbotViewController?
    private var bottomSheetController: BottomSheetChatbotViewController?

    // Configuration - Replace with your widget UID from YourGPT dashboard
    private let widgetUid = "your-widget-uid-here"

    // State observer callback
    var onStateChange: ((YourGPTSDKState) -> Void)?

    private override init() {
        super.init()
        setupSDKObserver()
    }

    // Monitor SDK state changes
    private func setupSDKObserver() {
        YourGPTSDK.core.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.onStateChange?(state)
            }
            .store(in: &cancellables)
    }

    // Initialize the SDK
    func initializeSDK() async throws {
        let config = YourGPTConfig(widgetUid: widgetUid)
        try await YourGPTSDK.initialize(config: config)
    }

    // Open chatbot in a bottom sheet
    func openChatbot(from presentingViewController: UIViewController, delegate: YourGPTChatbotDelegate?) {
        guard YourGPTSDK.isReady else {
            showAlert(on: presentingViewController, title: "SDK Not Ready", message: "Please wait for the SDK to initialize.")
            return
        }

        chatbotViewController = YourGPTSDK.createChatbotViewController(
            widgetUid: widgetUid
        )

        chatbotViewController?.delegate = delegate

        // Create bottom sheet presentation
        bottomSheetController = BottomSheetChatbotViewController()
        bottomSheetController?.setChatbotViewController(chatbotViewController!)

        // Set up dismissal callback
        bottomSheetController?.onDismiss = { [weak self] in
            self?.chatbotViewController = nil
            self?.bottomSheetController = nil
        }

        // Present as bottom sheet (iOS 15+) or form sheet (iOS 13-14)
        if #available(iOS 15.0, *) {
            bottomSheetController?.modalPresentationStyle = .pageSheet
            if let sheet = bottomSheetController?.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
        } else {
            bottomSheetController?.modalPresentationStyle = .formSheet
        }

        if let bottomSheet = bottomSheetController {
            presentingViewController.present(bottomSheet, animated: true)
        }
    }

    // Dismiss the chatbot
    func dismissChatbot() {
        bottomSheetController?.dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
            self?.bottomSheetController = nil
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

// MARK: - Bottom Sheet Container

@available(iOS 13.0, *)
class BottomSheetChatbotViewController: UIViewController {

    private var chatbotViewController: YourGPTChatbotViewController?
    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chatbotViewController?.view.frame = view.bounds
    }

    func setChatbotViewController(_ chatbotVC: YourGPTChatbotViewController) {
        chatbotViewController?.view.removeFromSuperview()
        chatbotViewController?.removeFromParent()

        chatbotViewController = chatbotVC
        addChild(chatbotVC)
        view.addSubview(chatbotVC.view)
        chatbotVC.didMove(toParent: self)
        chatbotVC.view.frame = view.bounds
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}
```

**Important:** Replace `"your-widget-uid-here"` with your actual widget UID from the [YourGPT dashboard](https://yourgpt.ai).

### Step 3: Initialize the SDK in Your View Controller

In your view controller (e.g., `ViewController.swift`), initialize the SDK and set up the UI:

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
        title = "YourGPT Demo"
        openChatButton?.isEnabled = false
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
            statusLabel?.text = "SDK Status: Ready"
            statusLabel?.textColor = .systemGreen
            openChatButton?.isEnabled = true
        case .connecting:
            statusLabel?.text = "SDK Status: Connecting..."
            statusLabel?.textColor = .systemOrange
            openChatButton?.isEnabled = false
        case .error:
            statusLabel?.text = "SDK Status: Error"
            statusLabel?.textColor = .systemRed
            openChatButton?.isEnabled = false
        case .disconnected:
            statusLabel?.text = "SDK Status: Disconnected"
            statusLabel?.textColor = .systemGray
            openChatButton?.isEnabled = false
        }
    }

    @IBAction func openChatTapped(_ sender: UIButton) {
        YourGPTWrapper.shared.openChatbot(from: self, delegate: self)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Step 4: Implement Delegate Methods

Add an extension to your view controller to handle chatbot events:

```swift
extension ViewController: YourGPTChatbotDelegate {

    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        print("New message received: \(message)")
    }

    func chatbotDidOpen() {
        print("Chatbot opened")
    }

    func chatbotDidClose() {
        print("Chatbot closed")
        YourGPTWrapper.shared.dismissChatbot()
    }

    func chatbotDidFailWithError(_ error: Error) {
        print("Chatbot error: \(error)")
        showAlert(title: "Error", message: error.localizedDescription)
    }

    func chatbotDidStartLoading() {
        print("Chatbot started loading")
    }

    func chatbotDidFinishLoading() {
        print("Chatbot finished loading")
    }
}
```

That's it! You now have a fully functional YourGPT chatbot in your iOS app.

## API Reference

### YourGPTConfig

Initialize the SDK with a configuration object:

```swift
let config = YourGPTConfig(
    widgetUid: "your-widget-uid"    // Required: Your widget UID from YourGPT dashboard
)

try await YourGPTSDK.initialize(config: config)
```

### Creating Chatbot View Controller

Create a chatbot view controller:

```swift
let chatbotVC = YourGPTSDK.createChatbotViewController(
    widgetUid: "your-widget-uid"    // Required: Your widget UID
)
```

**Minimal usage:** `widgetUid` only

### YourGPTChatbotDelegate

Implement these delegate methods to handle chatbot events:

| Method | Description |
|--------|-------------|
| `chatbotDidReceiveMessage(_ message: [String: Any])` | Called when a new message is received |
| `chatbotDidOpen()` | Called when the chatbot is opened |
| `chatbotDidClose()` | Called when the chatbot is closed |
| `chatbotDidFailWithError(_ error: Error)` | Called when an error occurs |
| `chatbotDidStartLoading()` | Called when the chatbot starts loading |
| `chatbotDidFinishLoading()` | Called when the chatbot finishes loading |

### SDK State Management

Monitor SDK state changes using Combine:

```swift
YourGPTSDK.core.$state
    .receive(on: DispatchQueue.main)
    .sink { state in
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
    .store(in: &cancellables)
```

Check SDK readiness:

```swift
if YourGPTSDK.isReady {
    // SDK is ready, you can open the chatbot
}
```

## Example App

For a complete working example, check out the [Example](./Example) folder which demonstrates:

- Setting up the SDK with [YourGPTWrapper.swift](./Example/YourGPTExample/YourGPTWrapper.swift) - A singleton wrapper class for easy SDK management
- Initializing the SDK in [ViewController.swift](./Example/YourGPTExample/ViewController.swift) - with async/await and error handling
- Monitoring SDK state with Combine and updating UI accordingly
- Presenting the chatbot in a bottom sheet with iOS 15+ detents
- Implementing all delegate methods for chatbot events
- Handling SDK connection states (connected, connecting, error, disconnected)

### Running the Example

1. Clone the repository
2. Open `Example/YourGPTExample.xcodeproj` in Xcode
3. Replace the `widgetUid` in [YourGPTWrapper.swift:17](./Example/YourGPTExample/YourGPTWrapper.swift#L17) with your actual widget UID
4. Build and run on the iOS Simulator or a physical device

## Troubleshooting

### SDK not connecting

- Make sure you've added the network permissions to `Info.plist`
- Verify your widget UID is correct
- Check your internet connection
- Enable debug logging to see detailed error messages

### Chatbot not displaying

- Ensure the SDK state is `.connected` before opening the chatbot
- Check that you've set the delegate properly
- Verify the presenting view controller is visible

## Support

For issues, questions, or feature requests, please visit:
- GitHub Issues: [https://github.com/YourGPT/yourgpt-widget-sdk-ios/issues](https://github.com/YourGPT/yourgpt-widget-sdk-ios/issues)
- YourGPT Dashboard: [https://yourgpt.ai](https://yourgpt.ai)