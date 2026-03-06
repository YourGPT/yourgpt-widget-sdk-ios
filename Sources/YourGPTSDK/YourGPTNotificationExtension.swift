import Foundation
import UserNotifications
import UIKit

/// Protocol that your AppDelegate can adopt for simplified push notification handling.
/// Replaces Android's YourGPTNotificationService (FirebaseMessagingService).
///
/// iOS has no equivalent auto-routing notification service. Instead, the SDK installs
/// a concrete `UNUserNotificationCenterDelegate` internally so that foreground
/// notification display and tap handling work automatically.
///
/// Usage:
/// ```swift
/// class AppDelegate: UIResponder, UIApplicationDelegate, YourGPTNotificationHandler {
///     func application(_ application: UIApplication,
///                      didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
///         setupYourGPTNotifications(widgetUid: "your-widget-uid")
///         return true
///     }
/// }
/// ```
public protocol YourGPTNotificationHandler: AnyObject {

    /// Called when a YourGPT notification tap should open the widget.
    /// Override to provide a custom view controller to present from.
    /// Default implementation returns the key window's root view controller.
    func yourGPTShouldOpenWidget(from notification: UNNotification) -> UIViewController?
}

// MARK: - Default Implementations

public extension YourGPTNotificationHandler {

    /// Convenience setup method. Call from `didFinishLaunchingWithOptions`.
    func setupYourGPTNotifications(widgetUid: String) {
        let delegate = YourGPTNotificationDelegate(handler: self)
        YourGPTNotificationClient.shared.installNotificationDelegate(delegate)
        YourGPTNotificationClient.shared.quickSetup(widgetUid: widgetUid)
    }

    /// Default: returns the key window's root view controller.
    func yourGPTShouldOpenWidget(from notification: UNNotification) -> UIViewController? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.rootViewController
        } else {
            return UIApplication.shared.windows
                .first { $0.isKeyWindow }?.rootViewController
        }
    }
}

// MARK: - Static Callbacks for Advanced Mode

extension YourGPTNotificationClient {

    /// Set a callback invoked whenever a new APNs token is received.
    /// Mirrors Android's `YourGPTNotificationService.setTokenCallback()`.
    public func setTokenCallback(_ callback: ((String) -> Void)?) {
        _tokenCallback = callback
    }

    /// Set a callback invoked whenever a push message is received.
    /// Mirrors Android's `YourGPTNotificationService.setMessageCallback()`.
    public func setMessageCallback(_ callback: (([AnyHashable: Any]) -> Void)?) {
        _messageCallback = callback
    }

    /// Internal: fire the token callback (called from cacheToken).
    internal func fireTokenCallback(_ token: String) {
        _tokenCallback?(token)
    }

    /// Internal: fire the message callback (called from handleNotification).
    internal func fireMessageCallback(_ userInfo: [AnyHashable: Any]) {
        _messageCallback?(userInfo)
    }
}

// MARK: - Concrete UNUserNotificationCenterDelegate

/// Internal concrete class whose delegate methods are visible to the Obj-C runtime.
/// Swift protocol extension methods are invisible to Objective-C `respondsToSelector:`
/// checks, so we use a concrete `NSObject` subclass instead.
internal final class YourGPTNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Weak reference back to the handler for `yourGPTShouldOpenWidget` customization.
    private weak var handler: YourGPTNotificationHandler?

    init(handler: YourGPTNotificationHandler) {
        self.handler = handler
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle foreground notification display.
    /// In minimalist mode: shows banner with sound and badge, fires event listeners.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        if YourGPTNotificationClient.shared.isYourGPTNotification(userInfo) {
            // Fire event listeners for foreground push
            YourGPTNotificationClient.shared.notifyPushReceived(userInfo)

            if YourGPTNotificationClient.shared.currentMode == .minimalist {
                if #available(iOS 14.0, *) {
                    completionHandler([.banner, .sound, .badge])
                } else {
                    completionHandler([.alert, .sound, .badge])
                }
                return
            }
        }

        // For non-YourGPT notifications or advanced mode, show normally
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    /// Handle notification tap response.
    /// Routes YourGPT notification taps to open the widget.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let vc: UIViewController?
        if let handler = handler {
            vc = handler.yourGPTShouldOpenWidget(from: response.notification)
        } else {
            // Fallback if handler was deallocated
            if #available(iOS 15.0, *) {
                vc = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?.rootViewController
            } else {
                vc = UIApplication.shared.windows
                    .first { $0.isKeyWindow }?.rootViewController
            }
        }

        _ = YourGPTNotificationClient.shared.handleNotificationResponse(
            response,
            openWidgetFrom: vc
        )

        completionHandler()
    }
}
