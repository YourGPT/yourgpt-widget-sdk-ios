import Foundation
import UserNotifications
import UIKit

/// Utility class for notification operations.
/// Maps to Android's YourGPTNotificationHelper.
public final class YourGPTNotificationHelper {

    // MARK: - Permission Management

    /// Request notification permission from the user.
    /// Automatically calls `registerForRemoteNotifications()` when granted.
    public static func requestPermission(
        options: UNAuthorizationOptions = [.alert, .sound, .badge],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: options
        ) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                completion(granted, error)
            }
        }
    }

    /// Check if notifications are currently authorized.
    public static func areNotificationsEnabled(
        completion: @escaping (Bool) -> Void
    ) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Local Notification Display

    /// Show a local notification (used for foreground display in minimalist mode).
    public static func showLocalNotification(
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        config: YourGPTNotificationConfig = YourGPTNotificationConfig(),
        threadIdentifier: String? = nil
    ) {
        guard config.shouldShowNotification() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = config.processedMessageContent(body)

        // Convert [AnyHashable: Any] to a form that UNMutableNotificationContent accepts
        var safeUserInfo: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                safeUserInfo[stringKey] = value
            }
        }
        content.userInfo = safeUserInfo

        if config.soundEnabled {
            if let soundName = config.soundName {
                content.sound = UNNotificationSound(
                    named: UNNotificationSoundName(soundName)
                )
            } else {
                content.sound = .default
            }
        }

        if config.groupMessages, let threadId = threadIdentifier {
            content.threadIdentifier = threadId
        }

        content.categoryIdentifier = config.categoryIdentifier

        let identifier = "yourgpt_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[YourGPTSDK] Failed to show notification: \(error)")
            }
        }
    }

    // MARK: - Notification Management

    /// Remove all delivered YourGPT notifications.
    public static func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current()
            .getDeliveredNotifications { notifications in
                let ids = notifications
                    .filter { $0.request.identifier.hasPrefix("yourgpt_") }
                    .map { $0.request.identifier }
                if !ids.isEmpty {
                    UNUserNotificationCenter.current()
                        .removeDeliveredNotifications(withIdentifiers: ids)
                }
            }
    }

    /// Remove a specific notification by identifier.
    public static func removeNotification(identifier: String) {
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    // MARK: - Notification Category Registration

    /// Register notification categories for interactive notifications.
    /// Call this during app launch.
    public static func registerNotificationCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: "YOURGPT_REPLY",
            title: "Reply",
            options: []
        )

        let openAction = UNNotificationAction(
            identifier: "YOURGPT_OPEN",
            title: "Open Chat",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "chat_message",
            actions: [replyAction, openAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current()
            .setNotificationCategories([category])
    }

    // MARK: - Badge Management

    /// Reset the app badge count to zero.
    public static func resetBadgeCount() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    /// Increment the app badge count by one.
    public static func incrementBadgeCount() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber += 1
        }
    }

    // MARK: - Rich Notification Builders

    /// Show a rich notification with expandable body text.
    /// Mirrors Android's `createRichNotification()`.
    public static func showRichNotification(
        title: String,
        body: String,
        subtitle: String? = nil,
        imageURL: URL? = nil,
        userInfo: [AnyHashable: Any] = [:],
        config: YourGPTNotificationConfig = YourGPTNotificationConfig(),
        threadIdentifier: String? = nil
    ) {
        guard config.shouldShowNotification() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = config.processedMessageContent(body)
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }

        var safeUserInfo: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                safeUserInfo[stringKey] = value
            }
        }
        content.userInfo = safeUserInfo

        if config.soundEnabled {
            if let soundName = config.soundName {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
            } else {
                content.sound = .default
            }
        }

        if config.groupMessages, let threadId = threadIdentifier {
            content.threadIdentifier = threadId
        }

        content.categoryIdentifier = config.categoryIdentifier

        // Attach image if URL is provided
        if let imageURL = imageURL {
            downloadAndAttachImage(from: imageURL, to: content) { finalContent in
                let identifier = "yourgpt_\(UUID().uuidString)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: finalContent,
                    trigger: nil
                )
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
            return
        }

        let identifier = "yourgpt_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// Show a notification with a reply action.
    /// Mirrors Android's `createReplyNotification()`.
    public static func showReplyNotification(
        title: String,
        body: String,
        replyLabel: String = "Reply",
        userInfo: [AnyHashable: Any] = [:],
        config: YourGPTNotificationConfig = YourGPTNotificationConfig()
    ) {
        guard config.shouldShowNotification() else { return }

        // Register reply category if not already done
        let replyAction = UNTextInputNotificationAction(
            identifier: "YOURGPT_REPLY",
            title: replyLabel,
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "yourgpt_reply",
            actions: [replyAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = config.processedMessageContent(body)
        content.categoryIdentifier = "yourgpt_reply"

        var safeUserInfo: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                safeUserInfo[stringKey] = value
            }
        }
        content.userInfo = safeUserInfo

        if config.soundEnabled {
            if let soundName = config.soundName {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
            } else {
                content.sound = .default
            }
        }

        let identifier = "yourgpt_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// Show a notification with custom action buttons.
    /// Mirrors Android's `createActionNotification()`.
    public static func showActionNotification(
        title: String,
        body: String,
        actions: [NotificationAction],
        userInfo: [AnyHashable: Any] = [:],
        config: YourGPTNotificationConfig = YourGPTNotificationConfig()
    ) {
        guard config.shouldShowNotification() else { return }

        let categoryId = "yourgpt_actions_\(UUID().uuidString)"
        let unActions = actions.map { action in
            UNNotificationAction(
                identifier: action.identifier,
                title: action.title,
                options: action.foreground ? [.foreground] : []
            )
        }
        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: unActions,
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = config.processedMessageContent(body)
        content.categoryIdentifier = categoryId

        var safeUserInfo: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                safeUserInfo[stringKey] = value
            }
        }
        content.userInfo = safeUserInfo

        if config.soundEnabled {
            content.sound = .default
        }

        let identifier = "yourgpt_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Reply Text Extraction

    /// Extract reply text from a notification response.
    /// Mirrors Android's `getReplyText()`.
    public static func getReplyText(from response: UNNotificationResponse) -> String? {
        return (response as? UNTextInputNotificationResponse)?.userText
    }

    // MARK: - Token Conversion

    /// Convert APNs device token Data to hex string.
    /// Use this in `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    public static func tokenString(from deviceToken: Data) -> String {
        return deviceToken.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private Helpers

    private static func downloadAndAttachImage(
        from url: URL,
        to content: UNMutableNotificationContent,
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) {
        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                completion(content)
                return
            }

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")

            do {
                try FileManager.default.moveItem(at: localURL, to: fileURL)
                let attachment = try UNNotificationAttachment(
                    identifier: "image",
                    url: fileURL,
                    options: nil
                )
                content.attachments = [attachment]
            } catch {
                print("[YourGPTSDK] Failed to attach image: \(error)")
            }

            completion(content)
        }.resume()
    }
}

// MARK: - Supporting Types

/// Notification action definition.
/// Mirrors Android's `NotificationAction` data class.
public struct NotificationAction {
    public let identifier: String
    public let title: String
    public let foreground: Bool

    public init(identifier: String, title: String, foreground: Bool = false) {
        self.identifier = identifier
        self.title = title
        self.foreground = foreground
    }
}
