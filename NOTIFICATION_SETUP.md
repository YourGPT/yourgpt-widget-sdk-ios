# YourGPT iOS SDK - Push Notification Setup

This guide explains how to enable push notifications in your iOS app using the YourGPT SDK. When set up, your users will receive notifications for new messages from the YourGPT widget even when the app is in the background or closed.

## Features

- **Background Notifications**: Receive messages when the app is closed or in the background
- **Automatic Token Management**: APNs token is cached and registered with the backend automatically
- **Two Modes**: Minimalist (auto-handles everything) or Advanced (custom handling)

## Prerequisites

1. An **Apple Developer account** with push notification entitlements
2. Your YourGPT **widget UID**
3. iOS 13.0 or higher
4. A physical iOS device (push notifications do not work on the Simulator)

---

## Step 1: Enable Push Notifications in Xcode

1. Open your project in Xcode
2. Select your app target → **Signing & Capabilities**
3. Click **+ Capability** and add **Push Notifications**
4. Also add **Background Modes** and check **Remote notifications**

---

## Step 2: Create an APNs Key

1. Go to [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Click the **+** button to create a new key
3. Enter a name (e.g., "YourGPT Push Key")
4. Check **Apple Push Notifications service (APNs)**
5. Click **Continue** → **Register**
6. Download the `.p8` key file and note the **Key ID**
7. Note your **Team ID** from [Membership Details](https://developer.apple.com/account/#/membership)

> **Important:** You can only download the `.p8` file once. Keep it safe.

---

## Step 3: Configure Push Notifications on YourGPT Dashboard

1. Log in to the [YourGPT Dashboard](https://app.yourgpt.ai)
2. Navigate to your chatbot's **Settings → Notifications**
3. Enable the **APNs** toggle
4. Enter your **Team ID** and **Key ID**
5. Upload the `.p8` key file you downloaded in Step 2
6. Enter your app's **Bundle ID** (e.g., `com.yourcompany.yourapp`)
7. Click **Save Credentials** — the dashboard will verify the credentials automatically

Once the status shows **"Configured"**, your YourGPT backend is ready to send push notifications.

---

## Step 4: Set Up AppDelegate for APNs

Add the following to your `AppDelegate.swift`:

```swift
import UIKit
import YourGPTSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate, YourGPTNotificationHandler {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up YourGPT notifications (installs delegate, requests permissions, registers for APNs)
        setupYourGPTNotifications(widgetUid: "YOUR_WIDGET_UID")
        return true
    }

    // MARK: - APNs Token

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert Data to hex string and cache for WebView JS bridge
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        YourGPTNotificationClient.shared.cacheToken(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for APNs: \(error)")
    }
}
```

The `YourGPTNotificationHandler` protocol automatically:

- Installs a `UNUserNotificationCenterDelegate` for foreground display and tap handling
- Requests notification permission from the user
- Registers with APNs

---

## Step 5: Initialize the SDK with Notifications

There are two ways to initialize: **Quick Setup** (recommended) or **Full Configuration**.

### Option A: Quick Setup (Recommended)

The simplest way — one line to enable everything:

```swift
import YourGPTSDK

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            try await YourGPTSDK.quickInitialize(widgetUid: "YOUR_WIDGET_UID")
        }
    }
}
```

This automatically:

- Initializes the SDK
- Enables minimalist notification handling
- Requests notification permission
- Registers notification categories

### Option B: Full Configuration

For more control over notification behavior:

```swift
let notifConfig = YourGPTNotificationConfig(
    soundEnabled: true,
    soundName: "message_sound.wav",    // Place in app bundle
    badgeEnabled: true,
    groupMessages: true,
    autoDismissOnOpen: true
)

let config = YourGPTConfig(
    widgetUid: "YOUR_WIDGET_UID",
    enableNotifications: true,
    notificationMode: .minimalist,  // or .advanced
    notificationConfig: notifConfig
)

try await YourGPTSDK.initialize(config: config)
```

---

## Step 6: Open the Widget at Least Once

The APNs token is registered with the YourGPT backend **through the WebView JS bridge** when the widget is opened. Until the widget is opened at least once, the backend won't know where to send notifications.

```swift
// Open the widget (e.g., on a button tap)
YourGPTSDK.show(from: self)
```

After the widget loads, the SDK automatically sends the cached APNs token to the backend. Subsequent token refreshes are also sent automatically the next time the widget is opened.

---

## How It Works

Here's the full notification flow:

```
1. App starts → AppDelegate registers for APNs → Token received and cached
2. User opens widget → Token sent to YourGPT backend via WebView JS bridge
3. New message on backend → APNs push sent to device
4. YourGPTNotificationDelegate handles foreground/tap → Widget opens
```

### Token Registration Flow

```
App Launch
  └→ setupYourGPTNotifications() requests permission
       └→ iOS grants → registerForRemoteNotifications()
            └→ didRegisterForRemoteNotificationsWithDeviceToken
                 └→ YourGPTNotificationClient.shared.cacheToken(tokenString)

Widget Opened
  └→ YourGPTChatbotViewController WebView loads
       └→ YourGPTNotificationClient.registerTokenViaWebView(webView)
            └→ Sends token to backend via window.postMessage()
```

---

## Notification Modes

| Mode          | Description                                                                              | Use Case                                |
| ------------- | ---------------------------------------------------------------------------------------- | --------------------------------------- |
| `.minimalist` | Auto-handles everything: display, tap actions, badge updates                             | Most apps — zero custom code needed     |
| `.advanced`   | SDK identifies YourGPT notifications but does not display them; your app handles display | Apps that need custom notification UI   |
| `.disabled`   | No notification handling                                                                 | Apps that don't want push notifications |

### Setting the Mode

```swift
// Via config during initialization
let config = YourGPTConfig(
    widgetUid: "YOUR_WIDGET_UID",
    enableNotifications: true,
    notificationMode: .minimalist  // or .advanced, .disabled
)

// Or change at runtime
YourGPTNotificationClient.shared.setNotificationMode(.advanced)
```

---

## Notification Configuration

Customize notification appearance using `YourGPTNotificationConfig`:

```swift
let config = YourGPTNotificationConfig(
    notificationsEnabled: true,
    soundEnabled: true,
    soundName: "message_sound.wav",
    badgeEnabled: true,
    groupMessages: true,
    threadIdentifierPrefix: "com.yourgpt.sdk",
    autoDismissOnOpen: true,
    quietHoursEnabled: false,
    quietHoursStart: 22,
    quietHoursEnd: 8,
    showMessagePreview: true,
    maxPreviewLength: 100,
    showReplyAction: true,
    stackNotifications: true,
    maxNotificationStack: 5,
    categoryIdentifier: "chat_message"
)
```

### Available Options

| Option                              | Default                | Description                                |
| ----------------------------------- | ---------------------- | ------------------------------------------ |
| `notificationsEnabled`              | `true`                 | Enable/disable notifications               |
| `soundEnabled`                      | `true`                 | Play sound on notification                 |
| `soundName`                         | `nil` (system default) | Custom sound file name from app bundle     |
| `badgeEnabled`                      | `true`                 | Update app badge count                     |
| `groupMessages`                     | `true`                 | Group notifications by conversation        |
| `threadIdentifierPrefix`            | `com.yourgpt.sdk`      | Prefix for notification thread identifiers |
| `autoDismissOnOpen`                 | `true`                 | Remove notifications when widget opens     |
| `quietHoursEnabled`                 | `false`                | Suppress notifications during hours        |
| `quietHoursStart` / `quietHoursEnd` | `22` / `8`             | Quiet hours range (24h format)             |
| `showMessagePreview`                | `true`                 | Show message content in notification       |
| `maxPreviewLength`                  | `100`                  | Max characters in notification preview     |
| `showReplyAction`                   | `true`                 | Show inline reply action                   |
| `stackNotifications`                | `true`                 | Stack notifications when multiple arrive   |
| `maxNotificationStack`              | `5`                    | Max notifications before summarizing       |
| `categoryIdentifier`                | `chat_message`         | UNNotificationCategory identifier          |

### Custom Sound

Place your sound file in the app bundle (e.g., `message_sound.wav`):

```swift
let config = YourGPTNotificationConfig(
    soundName: "message_sound.wav"
)
```

To disable sound:

```swift
let config = YourGPTNotificationConfig(
    soundEnabled: false
)
```

---

## Rich Notifications

The SDK includes helpers for creating rich notification content:

### Rich Notification (with image)

```swift
YourGPTNotificationHelper.showRichNotification(
    title: "Support Agent",
    body: "Here's the screenshot you requested",
    subtitle: "Order #12345",
    imageURL: URL(string: "https://example.com/image.png"),
    userInfo: userInfo,
    config: notifConfig
)
```

### Reply Notification

```swift
YourGPTNotificationHelper.showReplyNotification(
    title: "Support Agent",
    body: "How can I help?",
    replyLabel: "Type a reply...",
    userInfo: userInfo,
    config: notifConfig
)
```

### Action Notification

```swift
let actions = [
    YourGPTNotificationHelper.NotificationAction(
        identifier: "open",
        title: "Open Chat"
    ),
    YourGPTNotificationHelper.NotificationAction(
        identifier: "dismiss",
        title: "Dismiss",
        isDestructive: true
    )
]

YourGPTNotificationHelper.showActionNotification(
    title: "New Message",
    body: "You have a new message",
    actions: actions,
    userInfo: userInfo,
    config: notifConfig
)
```

### Extract Reply Text

```swift
// In your UNUserNotificationCenterDelegate's didReceive:
if let replyText = YourGPTNotificationHelper.getReplyText(from: response) {
    // User replied inline — send the text
    print("User replied: \(replyText)")
}
```

---

## SDK Methods Reference

### Notification Detection

```swift
// Check if a push payload is from YourGPT
let isYourGPT = YourGPTNotificationClient.shared.isYourGPTNotification(userInfo)

// Handle incoming notification (returns true if handled in minimalist mode)
let handled = YourGPTNotificationClient.shared.handleNotification(userInfo)
```

### Token Management

```swift
// Get the cached APNs token
let token = YourGPTNotificationClient.shared.cachedToken

// Reset token (useful when user logs out)
YourGPTNotificationClient.shared.resetToken()
```

### Widget

```swift
// Open the widget programmatically
YourGPTNotificationClient.shared.openWidget(from: viewController)

// Open to a specific conversation
YourGPTNotificationClient.shared.openWidget(from: viewController, sessionUid: "conversation-uid")

// Or use the SDK facade
YourGPTSDK.openSession(from: viewController, sessionUid: "conversation-uid")
```

### State & Mode

```swift
// Check if notification client is initialized
let ready = YourGPTNotificationClient.shared.isInitialized

// Get current notification mode
let mode = YourGPTNotificationClient.shared.currentMode

// Get current notification config
let config = YourGPTNotificationClient.shared.currentNotificationConfig

// Change mode at runtime
YourGPTNotificationClient.shared.setNotificationMode(.advanced)
```

### Notification Utilities

```swift
// Check if notifications are authorized
YourGPTNotificationHelper.areNotificationsEnabled { enabled in
    print("Notifications enabled: \(enabled)")
}

// Request notification permission
YourGPTNotificationHelper.requestPermission { granted, error in
    if granted {
        print("Permission granted")
    }
}

// Badge management
YourGPTNotificationHelper.incrementBadgeCount()
YourGPTNotificationHelper.resetBadgeCount()

// Remove all delivered notifications
YourGPTNotificationHelper.removeAllDeliveredNotifications()

// Register notification categories (reply, actions)
YourGPTNotificationHelper.registerNotificationCategories()
```

---

## Advanced Mode: Custom Notification Handling

If you use `.advanced` mode, the SDK identifies YourGPT notifications but does **not** display them — your app handles display.

### When to Use Advanced Mode

- Custom notification styling beyond the SDK defaults
- Different handling for different message types
- Integration with your own backend alongside YourGPT
- Custom actions or analytics on notifications

### Custom Implementation

```swift
import UserNotifications
import YourGPTSDK

class CustomNotificationHandler: NSObject, UNUserNotificationCenterDelegate {

    func setupCustomHandling() {
        UNUserNotificationCenter.current().delegate = self

        // Initialize in advanced mode
        YourGPTNotificationClient.shared.initialize(
            widgetUid: "YOUR_WIDGET_UID",
            mode: .advanced
        )

        // Set callbacks for token and message events
        YourGPTNotificationClient.shared.setTokenCallback { token in
            print("New APNs token: \(token)")
            // Send to your own backend if needed
        }

        YourGPTNotificationClient.shared.setMessageCallback { userInfo in
            print("Push received: \(userInfo)")
            // Custom processing
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        if YourGPTNotificationClient.shared.isYourGPTNotification(userInfo) {
            // Custom handling for YourGPT notifications
            // Show your own UI, log analytics, etc.
        }

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // Handle notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if YourGPTNotificationClient.shared.isYourGPTNotification(userInfo) {
            // Navigate to the appropriate screen
            // Or let the SDK handle it:
            // YourGPTNotificationClient.shared.handleNotificationResponse(response, openWidgetFrom: rootVC)
        }

        completionHandler()
    }
}
```

---

## Complete Example

```swift
// AppDelegate.swift
import UIKit
import YourGPTSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate, YourGPTNotificationHandler {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupYourGPTNotifications(widgetUid: "YOUR_WIDGET_UID")
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        YourGPTNotificationClient.shared.cacheToken(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNs registration failed: \(error)")
    }
}

// ViewController.swift
import UIKit
import YourGPTSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize SDK with notifications
        Task {
            try await YourGPTSDK.quickInitialize(widgetUid: "YOUR_WIDGET_UID")
        }
    }

    @IBAction func openChatTapped(_ sender: UIButton) {
        YourGPTSDK.show(from: self)
    }
}
```

---

## Testing

1. Use a **physical iOS device** (push notifications do not work on the Simulator)
2. Grant notification permission when prompted
3. Open the widget at least once (so the APNs token is registered with the backend)
4. Close the app
5. Send a test message through the YourGPT dashboard

---

## Troubleshooting

### Notifications not received

1. Verify APNs credentials are uploaded and showing **"Configured"** on the YourGPT Dashboard (Settings → Push Notifications)
2. Confirm the Push Notifications capability is enabled in your Xcode project
3. Verify the Bundle ID matches what's configured on the dashboard
4. Check that `didRegisterForRemoteNotificationsWithDeviceToken` is being called
5. Ensure the widget was opened at least once after SDK initialization (for token registration)
6. Enable `debug: true` in config and check console for `[YourGPTNotificationClient]` logs

### Notifications received but not displayed

1. Check that the app is in the background (foreground display requires `UNUserNotificationCenterDelegate`)
2. Verify `notificationMode` is not set to `.disabled`
3. Ensure quiet hours are not active

### Widget doesn't open on notification tap

1. Verify `YourGPTNotificationHandler` is adopted by your AppDelegate
2. Ensure `setupYourGPTNotifications()` is called in `didFinishLaunchingWithOptions`
3. Check that the handler's view controller is valid for presentation

### Token not registered

1. The APNs token is sent via the WebView JS bridge — the widget must be opened at least once
2. Check console for `"APNs token sent to widget backend via JS bridge"` message
3. If the token was refreshed while the widget was closed, it will be re-sent next time the widget opens

## Support

For issues or questions, please refer to the main [README](README.md) or contact YourGPT support.
