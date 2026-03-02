import Foundation
import UIKit
import UserNotifications
import WebKit

/// Singleton client for managing APNs push notifications.
/// Maps to Android's YourGPTNotificationClient.
///
/// Token flow:
/// 1. App receives APNs device token in AppDelegate
/// 2. App calls `YourGPTNotificationClient.shared.cacheToken(tokenString)`
/// 3. When widget WebView loads, token is sent to backend via JS bridge
/// 4. Backend associates token with widget for push delivery
public final class YourGPTNotificationClient {

    // MARK: - Singleton

    public static let shared = YourGPTNotificationClient()
    private init() {}

    // MARK: - Constants

    private static let tokenKey = "yourgpt_apns_token"
    private static let tokenTimestampKey = "yourgpt_apns_token_timestamp"
    private static let widgetUidKey = "yourgpt_widget_uid"

    // MARK: - Private State

    private var widgetUid: String?
    private var notificationMode: NotificationMode = .minimalist
    private var _isInitialized = false
    private var cachedAPNsToken: String?
    private var isTokenRegisteredViaWebView = false
    private var notificationConfig = YourGPTNotificationConfig()

    /// Callback for token events (advanced mode). Set via `setTokenCallback()`.
    internal var _tokenCallback: ((String) -> Void)?
    /// Callback for message events (advanced mode). Set via `setMessageCallback()`.
    internal var _messageCallback: (([AnyHashable: Any]) -> Void)?

    /// Strong reference to the concrete notification delegate.
    /// `UNUserNotificationCenter.delegate` is weak, so we must retain it here.
    private var notificationDelegate: YourGPTNotificationDelegate?

    // MARK: - Initialization

    /// Initialize notification client with configuration.
    /// Called automatically by `YourGPTSDK.initialize()` when
    /// `enableNotifications` is true.
    ///
    /// - Parameters:
    ///   - widgetUid: The widget UID.
    ///   - mode: Notification handling mode (default: `.minimalist`).
    ///   - config: Optional notification configuration.
    public func initialize(
        widgetUid: String,
        mode: NotificationMode = .minimalist,
        config: YourGPTNotificationConfig? = nil
    ) {
        self.widgetUid = widgetUid
        self.notificationMode = mode
        self._isInitialized = true

        if let config = config {
            self.notificationConfig = config
        }

        // Persist widgetUid for restoration after app restart
        let defaults = UserDefaults.standard
        defaults.set(widgetUid, forKey: Self.widgetUidKey)

        // Restore cached token if available
        if cachedAPNsToken == nil,
           let stored = defaults.string(forKey: Self.tokenKey) {
            cachedAPNsToken = stored
            log("Restored APNs token from UserDefaults")
        }

        log("Initialized with widget: \(widgetUid), mode: \(mode)")

        // In minimalist mode, auto-request permissions and register
        if mode == .minimalist {
            requestPermissionAndRegister()
        }
    }

    /// Quick one-line setup for minimalist mode.
    /// Mirrors Android's `quickSetup()`.
    public func quickSetup(widgetUid: String) {
        initialize(widgetUid: widgetUid, mode: .minimalist)
        YourGPTNotificationHelper.registerNotificationCategories()
    }

    /// Install the concrete notification delegate.
    /// Called by `setupYourGPTNotifications` on the `YourGPTNotificationHandler` extension.
    internal func installNotificationDelegate(_ delegate: YourGPTNotificationDelegate) {
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    // MARK: - Permission Flow

    private func requestPermissionAndRegister() {
        YourGPTNotificationHelper.requestPermission { [weak self] granted, _ in
            guard self != nil else { return }
            let listener = YourGPTSDKCore.shared.eventListener
            if granted {
                listener?.onNotificationPermissionGranted()
            } else {
                listener?.onNotificationPermissionDenied()
            }
        }
    }

    // MARK: - Notification Detection

    /// Check if a push notification payload is from YourGPT.
    /// Mirrors Android's `isYourGPTNotification()`.
    public func isYourGPTNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        // Primary: match widget_uid to our configured widget
        if let payloadWidgetUid = userInfo["widget_uid"] as? String,
           let myWidgetUid = widgetUid {
            return payloadWidgetUid == myWidgetUid
        }
        // Fallback: presence of project_uid indicates a YourGPT notification
        return userInfo["project_uid"] is String
    }

    // MARK: - Token Management

    /// Cache the APNs device token string.
    /// Call from `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    /// The token will be sent to the backend via the WebView JS bridge
    /// when the widget is next opened.
    ///
    /// - Parameter token: Hex string representation of the device token.
    public func cacheToken(_ token: String) {
        cachedAPNsToken = token
        isTokenRegisteredViaWebView = false

        let defaults = UserDefaults.standard
        defaults.set(token, forKey: Self.tokenKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Self.tokenTimestampKey)

        log("APNs token cached, will register via WebView when widget opens")

        // Notify listener
        YourGPTSDKCore.shared.eventListener?.onAPNsTokenReceived(token)
        fireTokenCallback(token)
    }

    /// Get the currently cached APNs token.
    public var cachedToken: String? {
        return cachedAPNsToken
    }

    /// Reset the cached token. Useful when user logs out.
    public func resetToken() {
        cachedAPNsToken = nil
        isTokenRegisteredViaWebView = false
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: Self.tokenTimestampKey)
        log("APNs token reset")
    }

    // MARK: - WebView JS Bridge Token Registration

    /// Send the cached APNs token to the widget backend through
    /// the WKWebView JS bridge. Called automatically when the
    /// widget WebView finishes loading.
    ///
    /// Sends: `window.postMessage({ type: 'register_push_token', payload: { ... } })`
    public func registerTokenViaWebView(_ webView: WKWebView) {
        guard let token = cachedAPNsToken,
              let uid = widgetUid else {
            log("No cached token or widgetUid to register via WebView")
            return
        }

        let script = """
        (function() {
            window.postMessage({
                type: 'register_push_token',
                payload: {
                    token: '\(token)',
                    platform: 'ios',
                    widget_uid: '\(uid)',
                }
            }, '*');
        })();
        """

        webView.evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                self?.log("Failed to register token via WebView: \(error)")
            } else {
                self?.isTokenRegisteredViaWebView = true
                self?.log("APNs token sent to widget backend via JS bridge")
            }
        }
    }

    // MARK: - Event Notification

    /// Notify event listeners that a push was received, without showing a local notification.
    /// Use this from `willPresent` (foreground) where the system already displays the remote push.
    public func notifyPushReceived(_ userInfo: [AnyHashable: Any]) {
        var data: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                data[stringKey] = value
            }
        }
        YourGPTSDKCore.shared.eventListener?.onPushMessageReceived(data)
    }

    // MARK: - Notification Handling

    /// Handle an incoming push notification.
    /// Returns `true` if the notification was handled (minimalist mode).
    /// Returns `false` if the app should handle it (advanced mode).
    ///
    /// Call from `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
    /// for background `content-available` pushes.
    public func handleNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard _isInitialized else {
            log("handleNotification: client not initialized")
            return false
        }

        guard notificationMode != .disabled else {
            log("handleNotification: mode is DISABLED")
            return false
        }

        guard isYourGPTNotification(userInfo) else {
            log("handleNotification: not a YourGPT notification")
            return false
        }

        // Notify listener
        notifyPushReceived(userInfo)
        fireMessageCallback(userInfo)

        switch notificationMode {
        case .minimalist:
            // Only show local notification if remote doesn't already have aps.alert
            // (remote pushes with aps.alert are displayed by the system automatically)
            let aps = userInfo["aps"] as? [String: Any]
            if aps?["alert"] == nil {
                showNotificationAutomatically(userInfo)
            }
            if notificationConfig.badgeEnabled {
                YourGPTNotificationHelper.incrementBadgeCount()
            }
            return true
        case .advanced, .disabled:
            return false
        }
    }

    /// Handle notification tap. Opens the widget if in minimalist mode.
    /// Call from `UNUserNotificationCenterDelegate`'s `didReceive` response method.
    ///
    /// - Parameters:
    ///   - response: The notification response from the user's tap.
    ///   - viewController: The view controller to present the widget from.
    /// - Returns: `true` if the notification was handled.
    public func handleNotificationResponse(
        _ response: UNNotificationResponse,
        openWidgetFrom viewController: UIViewController? = nil
    ) -> Bool {
        let userInfo = response.notification.request.content.userInfo

        guard _isInitialized,
              isYourGPTNotification(userInfo) else {
            return false
        }

        // Notify listener
        var clickData: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                clickData[stringKey] = value
            }
        }
        YourGPTSDKCore.shared.eventListener?.onNotificationClicked(clickData)

        if notificationMode == .minimalist, let vc = viewController {
            let uid = widgetUid ?? ""
            YourGPTSDKCore.shared.eventListener?.onWidgetOpenRequested(uid)

            let conversationId = (userInfo["session_uid"] as? String)
                ?? (userInfo["conversation_id"] as? String)

            if let sessionUid = conversationId {
                YourGPTSDK.openSession(from: vc, sessionUid: sessionUid)
            } else {
                YourGPTSDK.show(from: vc)
            }

            if notificationConfig.autoDismissOnOpen {
                YourGPTNotificationHelper.removeAllDeliveredNotifications()
                YourGPTNotificationHelper.resetBadgeCount()
            }

            return true
        }

        return false
    }

    // MARK: - Mode Management

    // MARK: - Open Widget

    /// Open the widget programmatically, optionally navigating to a specific session.
    /// Mirrors Android's `YourGPTNotificationClient.openWidget(activity, sessionUid)`.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present the widget from.
    ///   - sessionUid: Optional session/conversation UID to open directly.
    public func openWidget(from viewController: UIViewController, sessionUid: String? = nil) {
        let uid = widgetUid ?? ""
        YourGPTSDKCore.shared.eventListener?.onWidgetOpenRequested(uid)

        if let sessionUid = sessionUid {
            YourGPTSDK.openSession(from: viewController, sessionUid: sessionUid)
        } else {
            YourGPTSDK.show(from: viewController)
        }

        if notificationConfig.autoDismissOnOpen {
            YourGPTNotificationHelper.removeAllDeliveredNotifications()
            YourGPTNotificationHelper.resetBadgeCount()
        }
    }

    // MARK: - Mode & Config Management

    /// Whether the notification client has been initialized.
    public var isInitialized: Bool { _isInitialized }

    /// The current notification handling mode.
    public var currentMode: NotificationMode { notificationMode }

    /// The current notification configuration.
    /// Mirrors Android's `getNotificationConfig()`.
    public var currentNotificationConfig: YourGPTNotificationConfig { notificationConfig }

    /// Update the notification handling mode.
    public func setNotificationMode(_ mode: NotificationMode) {
        notificationMode = mode
        log("Notification mode set to: \(mode)")
    }

    /// Set a dedicated event listener on the notification client.
    /// Mirrors Android's `YourGPTNotificationClient.setEventListener()`.
    public func setEventListener(_ listener: YourGPTEventListener?) {
        YourGPTSDKCore.shared.eventListener = listener
    }

    // MARK: - Private Helpers

    private func showNotificationAutomatically(_ userInfo: [AnyHashable: Any]) {
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"]

        let title: String
        if let t = userInfo["title"] as? String {
            title = t
        } else if let alertDict = alert as? [String: Any],
                  let t = alertDict["title"] as? String {
            title = t
        } else {
            title = "YourGPT"
        }

        let body: String
        if let b = userInfo["body"] as? String {
            body = b
        } else if let alertDict = alert as? [String: Any],
                  let b = alertDict["body"] as? String {
            body = b
        } else if let alertString = alert as? String {
            body = alertString
        } else {
            body = "New message"
        }

        let conversationId = (userInfo["session_uid"] as? String)
            ?? (userInfo["conversation_id"] as? String)

        let threadId = conversationId.map {
            "\(notificationConfig.threadIdentifierPrefix).\($0)"
        }

        YourGPTNotificationHelper.showLocalNotification(
            title: title,
            body: body,
            userInfo: userInfo,
            config: notificationConfig,
            threadIdentifier: threadId
        )
    }

    private func log(_ message: String) {
        if YourGPTSDKCore.shared.currentConfig?.debug == true {
            print("[YourGPTNotificationClient] \(message)")
        }
    }
}
