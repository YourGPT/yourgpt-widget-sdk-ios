import Foundation

/// Global event listener for YourGPT SDK events.
/// Maps to Android's YourGPTEventListener interface.
///
/// Widget events (first 6) are required.
/// Notification events (last 6) are optional with empty default implementations.
public protocol YourGPTEventListener: AnyObject {

    // MARK: - Widget Events (Required)

    /// Called when a new message is received from the widget.
    func onMessageReceived(_ message: [String: Any])

    /// Called when the chat widget opens.
    func onChatOpened()

    /// Called when the chat widget closes.
    func onChatClosed()

    /// Called when an error occurs.
    func onError(_ error: String)

    /// Called when the widget starts loading.
    func onLoadingStarted()

    /// Called when the widget finishes loading.
    func onLoadingFinished()

    // MARK: - Notification Events (Optional)

    /// Called when APNs device token is received.
    func onAPNsTokenReceived(_ token: String)

    /// Called when a push message is received.
    func onPushMessageReceived(_ data: [String: Any])

    /// Called when user taps a notification.
    func onNotificationClicked(_ userInfo: [String: Any])

    /// Called when the widget should be opened from a notification tap.
    func onWidgetOpenRequested(_ widgetUid: String)

    /// Called when notification permission is denied by the user.
    func onNotificationPermissionDenied()

    /// Called when notification permission is granted by the user.
    func onNotificationPermissionGranted()
}

// MARK: - Default Implementations for Optional Notification Events

public extension YourGPTEventListener {
    func onAPNsTokenReceived(_ token: String) {}
    func onPushMessageReceived(_ data: [String: Any]) {}
    func onNotificationClicked(_ userInfo: [String: Any]) {}
    func onWidgetOpenRequested(_ widgetUid: String) {}
    func onNotificationPermissionDenied() {}
    func onNotificationPermissionGranted() {}
}
