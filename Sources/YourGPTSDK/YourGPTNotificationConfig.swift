import Foundation

/// Configuration for push notification appearance and behavior.
/// Maps to Android's YourGPTNotificationConfig.
///
/// Android-only features (LED, channels, vibration patterns) are omitted.
/// iOS-specific features (badge, threadIdentifier) are added.
public struct YourGPTNotificationConfig {

    // MARK: - Basic Settings

    /// Whether notifications are enabled.
    public let notificationsEnabled: Bool

    // MARK: - Sound Settings

    /// Whether notification sound is enabled.
    public let soundEnabled: Bool

    /// Custom sound file name. nil uses the default system sound.
    public let soundName: String?

    // MARK: - Badge Settings (iOS-specific)

    /// Whether to update the app badge count on new notifications.
    public let badgeEnabled: Bool

    // MARK: - Grouping

    /// Whether to group notifications by conversation.
    public let groupMessages: Bool

    /// Prefix for thread identifiers used in notification grouping.
    public let threadIdentifierPrefix: String

    // MARK: - Auto-dismiss

    /// Whether to remove delivered notifications when the widget is opened.
    public let autoDismissOnOpen: Bool

    // MARK: - Quiet Hours

    /// Whether quiet hours are enabled.
    public let quietHoursEnabled: Bool

    /// Quiet hours start time in 24-hour format (e.g. 22 for 10 PM).
    public let quietHoursStart: Int

    /// Quiet hours end time in 24-hour format (e.g. 8 for 8 AM).
    public let quietHoursEnd: Int

    // MARK: - Message Preview

    /// Whether to show message content in notification body.
    public let showMessagePreview: Bool

    /// Maximum number of characters to show in notification preview.
    public let maxPreviewLength: Int

    // MARK: - Reply Action

    /// Whether to show a reply action on notifications.
    /// Mirrors Android's `showReplyAction`.
    public let showReplyAction: Bool

    // MARK: - Stacking

    /// Whether to stack notifications when multiple arrive.
    /// Mirrors Android's `stackNotifications`.
    public let stackNotifications: Bool

    /// Maximum number of notifications to show before summarizing.
    /// Mirrors Android's `maxNotificationStack`.
    public let maxNotificationStack: Int

    // MARK: - Notification Category

    /// Category identifier for notification actions (reply, open).
    public let categoryIdentifier: String

    // MARK: - Custom Data

    /// Additional key-value pairs attached to notifications.
    public let customExtras: [String: String]

    // MARK: - Initialization

    public init(
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        soundName: String? = nil,
        badgeEnabled: Bool = true,
        groupMessages: Bool = true,
        threadIdentifierPrefix: String = "com.yourgpt.sdk",
        autoDismissOnOpen: Bool = true,
        quietHoursEnabled: Bool = false,
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 8,
        showMessagePreview: Bool = true,
        maxPreviewLength: Int = 100,
        showReplyAction: Bool = true,
        stackNotifications: Bool = true,
        maxNotificationStack: Int = 5,
        categoryIdentifier: String = "chat_message",
        customExtras: [String: String] = [:]
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.soundName = soundName
        self.badgeEnabled = badgeEnabled
        self.groupMessages = groupMessages
        self.threadIdentifierPrefix = threadIdentifierPrefix
        self.autoDismissOnOpen = autoDismissOnOpen
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.showMessagePreview = showMessagePreview
        self.maxPreviewLength = maxPreviewLength
        self.showReplyAction = showReplyAction
        self.stackNotifications = stackNotifications
        self.maxNotificationStack = maxNotificationStack
        self.categoryIdentifier = categoryIdentifier
        self.customExtras = customExtras
    }

    // MARK: - Utility Methods

    /// Check if the current time falls within quiet hours.
    public func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: Date())
        if quietHoursStart > quietHoursEnd {
            // Wraps midnight (e.g. 22:00 to 08:00)
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
        return hour >= quietHoursStart && hour < quietHoursEnd
    }

    /// Check if a notification should be shown (enabled and not in quiet hours).
    public func shouldShowNotification() -> Bool {
        return notificationsEnabled && !isInQuietHours()
    }

    /// Process message content for notification preview (truncate if needed).
    public func processedMessageContent(_ message: String) -> String {
        guard showMessagePreview else { return "New message" }
        if message.count > maxPreviewLength {
            return String(message.prefix(maxPreviewLength)) + "..."
        }
        return message
    }
}
