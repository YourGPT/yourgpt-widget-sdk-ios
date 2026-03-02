# YourGPT iOS SDK

A Swift SDK for integrating YourGPT chatbot widget into iOS applications.

## Quick Start

### Installation

#### Swift Package Manager (Recommended)

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/YourGPT/yourgpt-widget-sdk-ios.git`
3. Select version `1.0.0` or later
4. Click **Add Package**

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourGPT/yourgpt-widget-sdk-ios.git", from: "1.0.0")
]
```

#### CocoaPods

```ruby
pod 'YourGPTSDK', '~> 1.0'
```

### Initialize and Open the Chat Widget

```swift
import YourGPTSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize SDK
        Task {
            try await YourGPTSDK.initialize(config: YourGPTConfig(widgetUid: "your-widget-uid"))
        }
    }

    @IBAction func openChatTapped(_ sender: UIButton) {
        // Open chatbot
        YourGPTSDK.show(from: self)
    }
}
```

That's it. The SDK handles the WebView, loading states, and lifecycle internally.

### Quick Initialize (One-Liner)

For the simplest setup with notifications auto-enabled:

```swift
try await YourGPTSDK.quickInitialize(widgetUid: "your-widget-uid")
```

---

## Configuration

```swift
let config = YourGPTConfig(
    widgetUid: "your-widget-uid",      // Required
    debug: true,                        // Optional: Enable debug logs (default: false)
    enableNotifications: true,          // Optional: Enable push notifications (default: false)
    notificationMode: .minimalist       // Optional: .minimalist, .advanced, or .disabled
)

try await YourGPTSDK.initialize(config: config)
```

### Push Notifications

Enable push notifications with optional custom sound:

```swift
let notifConfig = YourGPTNotificationConfig(
    soundEnabled: true,
    soundName: "message_sound.wav",
    badgeEnabled: true
)

let config = YourGPTConfig(
    widgetUid: "your-widget-uid",
    enableNotifications: true,
    notificationConfig: notifConfig
)

try await YourGPTSDK.initialize(config: config)
```

See [NOTIFICATION_SETUP.md](NOTIFICATION_SETUP.md) for complete setup instructions including APNs configuration, permission handling, and all customization options.

---

## Opening the Chatbot

### Simple (uses config from `initialize()`)

```swift
YourGPTSDK.show(from: self)
```

### With ad-hoc config

```swift
let config = YourGPTConfig(widgetUid: "your-widget-uid")
YourGPTSDK.show(from: self, config: config)
```

### Open a specific conversation

```swift
YourGPTSDK.openSession(from: self, sessionUid: "conversation-uid")
```

### Create a standalone ViewController

Use `createChatbotViewController()` when you want to embed the chatbot in your own navigation or container:

```swift
let chatbotVC = YourGPTSDK.createChatbotViewController(
    widgetUid: "your-widget-uid",
    customParams: ["lang": "en"]
)
chatbotVC.delegate = self

// Present however you like
navigationController?.pushViewController(chatbotVC, animated: true)
```

---

## Widget Data Methods

After the chatbot is displayed, you can send data to the widget via the `YourGPTChatbotViewController` instance:

```swift
let chatbotVC = YourGPTSDK.createChatbotViewController(widgetUid: "your-widget-uid")

// Send session-specific data
chatbotVC.setSessionData(["orderId": "12345", "plan": "premium"])

// Send visitor data (auto-enriched with device info: platform, model, OS version, app version)
chatbotVC.setVisitorData(["userId": "user_abc", "name": "John"])

// Send contact information
chatbotVC.setContactData(["email": "john@example.com", "phone": "+1234567890"])

// Programmatically open the chat interface
chatbotVC.openChat()
```

---

## Event Handling

### Global Event Listener

Implement `YourGPTEventListener` to receive SDK-wide events:

```swift
class MyApp: YourGPTEventListener {

    func setup() {
        YourGPTSDK.setEventListener(self)
    }

    // Required — widget events
    func onMessageReceived(_ message: [String: Any]) { }
    func onChatOpened() { }
    func onChatClosed() { }
    func onError(_ error: String) { }
    func onLoadingStarted() { }
    func onLoadingFinished() { }

    // Optional — notification events (default no-op)
    func onAPNsTokenReceived(_ token: String) { }
    func onPushMessageReceived(_ data: [String: Any]) { }
    func onNotificationClicked(_ userInfo: [String: Any]) { }
    func onWidgetOpenRequested(_ widgetUid: String) { }
    func onNotificationPermissionGranted() { }
    func onNotificationPermissionDenied() { }
}
```

### Per-Dialog Delegate

Use `YourGPTChatbotDelegate` for per-instance event handling:

```swift
extension ViewController: YourGPTChatbotDelegate {
    func chatbotDidReceiveMessage(_ message: [String: Any]) { }
    func chatbotDidOpen() { }
    func chatbotDidClose() { }
    func chatbotDidFailWithError(_ error: Error) { }
    func chatbotDidStartLoading() { }
    func chatbotDidFinishLoading() { }
}
```

---

## Custom Loading & Error Views

Inject custom views for the loading and error states:

```swift
let chatbotVC = YourGPTSDK.createChatbotViewController(widgetUid: "your-widget-uid")

// Custom loading view
chatbotVC.customLoadingView = myLoadingSpinnerView

// Custom error view (receives the error message)
chatbotVC.customErrorView = { errorMessage in
    let label = UILabel()
    label.text = errorMessage
    label.textAlignment = .center
    return label
}
```

The default error view includes a "Try Again" button that retries the connection automatically.

---

## SDK State

### Observe State Changes (Combine)

```swift
import Combine

var cancellables = Set<AnyCancellable>()

YourGPTSDK.statePublisher
    .receive(on: DispatchQueue.main)
    .sink { state in
        switch state.connectionState {
        case .connected:    print("Ready")
        case .connecting:   print("Connecting...")
        case .error:        print("Error: \(state.error?.localizedDescription ?? "")")
        case .disconnected: print("Disconnected")
        }
    }
    .store(in: &cancellables)
```

### Check Readiness

```swift
if YourGPTSDK.isReady {
    // SDK is connected and ready
}
```

### Build Widget URL

```swift
let url = try YourGPTSDK.buildWidgetUrl(additionalParams: ["lang": "en"])
```

---

## Error Handling

The SDK uses structured error types via the `YourGPTError` enum:

```swift
do {
    try await YourGPTSDK.initialize(config: config)
} catch let error as YourGPTError {
    switch error {
    case .invalidConfiguration(let detail):
        print("Invalid config: \(detail)")
    case .notInitialized:
        print("Call initialize() first")
    case .invalidURL:
        print("Failed to build widget URL")
    }
}
```

---

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Example App

For a complete working example, check out the [Example](./Example) folder which demonstrates:
- SDK initialization with async/await
- Chatbot presentation as a bottom sheet
- Delegate implementation for chatbot events
- State observation with Combine
- Push notification setup

See [DEV_SETUP.md](./DEV_SETUP.md) for local development and testing instructions.

## Troubleshooting

### SDK not connecting

- Verify your widget UID is correct
- Check your internet connection
- Enable `debug: true` in config for detailed logs

### Chatbot not displaying

- Ensure `YourGPTSDK.isReady` is `true` before calling `show()`
- Check that the presenting view controller is visible
- Verify the delegate is set properly

### Push notifications not working

- See [NOTIFICATION_SETUP.md](NOTIFICATION_SETUP.md) for detailed troubleshooting

## Support

For issues or feature requests:
- GitHub Issues: [https://github.com/YourGPT/yourgpt-widget-sdk-ios/issues](https://github.com/YourGPT/yourgpt-widget-sdk-ios/issues)
- YourGPT Dashboard: [https://yourgpt.ai](https://yourgpt.ai)
