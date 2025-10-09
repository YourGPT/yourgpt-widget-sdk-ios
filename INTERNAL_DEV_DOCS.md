# YourGPT iOS SDK - Internal Developer Documentation

## Architecture Overview

The iOS SDK follows the MVVM-C pattern with reactive programming using Combine framework:

```
YourGPTSDKCore (Business Logic)
├── ObservableObject with @Published state
├── Async/await initialization
├── Event-driven communication
└── URL building and validation

YourGPTChatbotViewController (UI Layer)
├── Reactive UI updates via Combine
├── Loading/Error state management
├── WebView lifecycle management
└── Bridge communication handling
```

## Core Components

### 1. YourGPTSDKCore (ObservableObject)

**Location**: `Sources/YourGPTSDK/YourGPTSDKCore.swift`

**Purpose**: Central SDK management with reactive state publishing

**Architecture Patterns**:
- Singleton pattern for global state consistency
- ObservableObject for SwiftUI/Combine integration
- @Published properties for reactive updates
- async/await for modern concurrency

**State Management**:
```swift
@Published public private(set) var state = YourGPTSDKState()

struct YourGPTSDKState {
    let isInitialized: Bool
    let isLoading: Bool
    let error: String?
    let connectionState: YourGPTConnectionState
}

enum YourGPTConnectionState {
    case disconnected, connecting, connected, error
}
```

**Key Features**:
- Thread-safe state management with MainActor
- Async initialization with proper error handling
- Event system for cross-component communication
- URL building with comprehensive validation

**Initialization Flow**:
1. `initialize(config:)` called with `YourGPTConfig`
2. State published: `connecting`
3. Widget validation (async simulation)
4. Success: `connected` | Failure: `error`
5. State changes published automatically

### 2. YourGPTConfig

**Purpose**: Immutable configuration with strong typing

**Features**:
- Strongly typed enum for theme
- Built-in URL query item generation
- Default value handling
- Debug mode for development

```swift
public struct YourGPTConfig {
    public let widgetUid: String        // Required
    public let baseUrl: String          // Default: https://yourgpt.ai
    public let userId: String?          // Optional
    public let authToken: String?       // Optional
    public let theme: YourGPTTheme      // Default: .light
    public let debug: Bool              // Default: false
}
```

### 3. YourGPTChatbotViewController

**Location**: `Sources/YourGPTSDK/YourGPTChatbotViewController.swift`

**Purpose**: WebView wrapper with enhanced lifecycle management

**Component Architecture**:
```
UIViewController
├── Combine Subscribers (cancellables)
├── SDK State Observer
├── Loading/Error Views
├── WKWebView Integration
└── Delegate Pattern
```

**State Variables**:
- `isSDKReady`: SDK initialization completion
- `loadingView/errorView`: UI state containers
- `cancellables`: Combine subscription management

**Lifecycle Flow**:
```
viewDidLoad()
    ↓
setupSDKObserver() → Combine subscription
    ↓
initializeSDK() → Async SDK setup
    ↓
handleSDKStateChange() → Reactive UI updates
    ↓
setupWebView() → WebView creation (if ready)
    ↓
loadChatbot() → URL loading
    ↓
Bridge communication established
```

## Communication Architecture

### Reactive State Management
```swift
// Publisher-Subscriber pattern
sdk.$state
    .receive(on: DispatchQueue.main)
    .sink { state in
        // Handle state changes
    }
    .store(in: &cancellables)
```

### Event System
```swift
// SDK-level events
core.on(event: "sdk:initialized", callback: { data in })
core.on(event: "sdk:stateChanged", callback: { data in })
core.on(event: "sdk:error", callback: { data in })
```

### Bridge Communication
```swift
// iOS → JavaScript
webView.evaluateJavaScript("window.postMessage(...)")

// JavaScript → iOS
WKScriptMessageHandler protocol implementation
contentController.add(self, name: "YourGPTNative")
```

### Delegate Pattern
```swift
public protocol YourGPTChatbotDelegate: AnyObject {
    func chatbotDidReceiveMessage(_ message: [String: Any])
    func chatbotDidOpen()
    func chatbotDidClose()
    func chatbotDidFailWithError(_ error: Error)
    func chatbotDidStartLoading()
    func chatbotDidFinishLoading()
}
```

## Error Handling Strategy

### Error Types & Hierarchy
```swift
public enum YourGPTError: LocalizedError {
    case invalidConfiguration(String)
    case notInitialized
    case notReady
    case invalidURL
    case webViewError(String)
}
```

### Error Propagation Flow
```
Error Source
    ↓
Async/Await Error Handling
    ↓
MainActor State Update
    ↓
@Published State Change
    ↓
Combine Subscriber
    ↓
UI Update + Delegate Callback
```

### Multi-Layer Error Handling
1. **SDK Core Level**: Configuration validation, network simulation
2. **WebView Level**: Page loading, navigation errors
3. **View Controller Level**: Lifecycle, bridge communication
4. **Application Level**: User-facing error display

## Performance Considerations

### Memory Management
- Singleton SDK prevents multiple instances
- `weak self` in Combine subscriptions
- Proper cancellable cleanup in `viewDidDisappear`
- WebView cleanup on navigation

### Concurrency
```swift
// Modern async/await pattern
Task {
    do {
        try await sdk.initialize(config: config)
    } catch {
        await MainActor.run {
            // UI updates on main thread
        }
    }
}
```

### State Synchronization
- `@Published` ensures thread-safe state updates
- `MainActor` ensures UI updates on main queue
- Combine handles backpressure automatically

## UI State Management

### Loading States
```swift
private func showLoadingView() {
    let loading = customLoadingView ?? createDefaultLoadingView()
    // Add with Auto Layout constraints
}

private func createDefaultLoadingView() -> UIView {
    // UIActivityIndicatorView + UILabel in UIStackView
}
```

### Error States
```swift
private func showErrorView(_ message: String) {
    let error = customErrorView?(message) ?? createDefaultErrorView(message: message)
    // Add with Auto Layout constraints
}

private func createDefaultErrorView(message: String) -> UIView {
    // UIImageView + UILabel in UIStackView
}
```

### Custom View Support
```swift
// Developer can provide custom views
public var customLoadingView: UIView?
public var customErrorView: ((String) -> UIView)?
```

## WebView Integration

### Configuration
```swift
let webViewConfiguration = WKWebViewConfiguration()
webViewConfiguration.preferences.javaScriptEnabled = true

let contentController = WKUserContentController()
contentController.add(self, name: "YourGPTNative")
webViewConfiguration.userContentController = contentController
```

### Navigation Handling
```swift
func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    delegate?.chatbotDidStartLoading()
}

func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    hideLoadingView()
    injectJavaScript()
    delegate?.chatbotDidFinishLoading()
}
```

### JavaScript Injection
```swift
private func injectJavaScript() {
    let script = """
        window.addEventListener('message', function(event) {
            window.webkit.messageHandlers.YourGPTNative.postMessage(event.data);
        });
        
        window.nativeBridge = {
            sendMessage: function(message) { /* ... */ },
            setUserContext: function(context) { /* ... */ }
        };
    """
    webView.evaluateJavaScript(script)
}
```

## Debug & Development Features

### Debug Mode
```swift
YourGPTConfig(debug: true) // Enables detailed logging
```

### Development Tools
- Console logging for state transitions
- Combine debugging with print operators
- Error tracking with delegate callbacks
- WebView debugging support

### Testing Hooks
```swift
// Access SDK state for testing
YourGPTSDK.currentState
YourGPTSDK.isReady

// State observation for testing
YourGPTSDK.core.$state.sink { state in
    // Test state changes
}
```

## Extension Points

### Custom UI Components
```swift
let chatbotVC = YourGPTSDK.createChatbotViewController(...)
chatbotVC.customLoadingView = MyCustomLoader()
chatbotVC.customErrorView = { error in MyErrorView(error) }
```

### Event Handling
```swift
// Custom event handlers
YourGPTSDK.core.on(event: "custom:event") { data in
    handleCustomEvent(data)
}
```

### Configuration Extensions
- Theme customization with enum
- Additional URL parameters
- Custom base URLs
- Environment-specific settings

## Package Management

### Swift Package Manager
```swift
// Package.swift
let package = Package(
    name: "YourGPTSDK",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "YourGPTSDK", targets: ["YourGPTSDK"])
    ],
    targets: [
        .target(name: "YourGPTSDK", path: "Sources")
    ]
)
```

### CocoaPods
```ruby
# YourGPTSDK.podspec
Pod::Spec.new do |spec|
  spec.name = "YourGPTSDK"
  spec.version = "1.0.0"
  spec.platform = :ios, "12.0"
  spec.frameworks = "UIKit", "WebKit"
  spec.swift_version = "5.0"
end
```

## Testing Strategy

### Unit Testing
- SDK initialization logic
- Configuration validation
- URL building functions
- Error handling paths
- State management

### UI Testing
- View controller lifecycle
- Loading state display
- Error state handling
- WebView integration
- Delegate method calls

### Integration Testing
- End-to-end initialization flow
- Bridge communication
- Reactive state updates
- Memory management

### Manual Testing Checklist
- [ ] SDK initializes with valid/invalid configurations
- [ ] Loading states display correctly
- [ ] Error states show appropriate messages
- [ ] WebView loads and communicates bidirectionally
- [ ] Multiple view controller instances work
- [ ] Memory usage remains stable
- [ ] Combine subscriptions clean up properly

## Development Workflow

### Local Development
1. Use example app for testing
2. Enable debug mode for detailed logging
3. Test with various configurations
4. Verify error handling paths
5. Test memory management

### Build Process
1. Swift compilation
2. Framework generation
3. Swift Package validation
4. Documentation generation

### Release Process
1. Version bump in Package.swift and podspec
2. Update CHANGELOG.md
3. Test on devices and simulators
4. Publish to GitHub/Package registry
5. Update documentation

## Common Issues & Solutions

### WebView Not Loading
- Verify ATS (App Transport Security) settings
- Check widget URL validity
- Test with debug mode enabled
- Validate network connectivity

### SDK Initialization Fails
- Validate widgetUid format
- Check async/await usage
- Review error delegate callbacks
- Test configuration parameters

### Bridge Communication Issues
- Verify JavaScript injection timing
- Check message format consistency
- Validate WKScriptMessageHandler setup
- Test with debug logging

### Memory Leaks
- Proper Combine cancellable cleanup
- WebView reference management
- Delegate weak references
- View controller lifecycle