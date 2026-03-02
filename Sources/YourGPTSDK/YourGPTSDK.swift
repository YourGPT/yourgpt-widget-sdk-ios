import Foundation
import UIKit
import Combine

public struct YourGPTSDK {
    public static let version = "1.0.0"
    public static let core = YourGPTSDKCore.shared

    // MARK: - Initialization

    public static func initialize(config: YourGPTConfig) async throws {
        try await core.initialize(config: config)

        // Auto-initialize notifications if enabled
        if config.enableNotifications && config.notificationMode != .disabled {
            YourGPTNotificationClient.shared.initialize(
                widgetUid: config.widgetUid,
                mode: config.notificationMode,
                config: config.notificationConfig
            )
        }
    }

    /// Simplified initialization with notifications auto-enabled in minimalist mode.
    /// Mirrors Android's `quickInitialize()`.
    public static func quickInitialize(widgetUid: String) async throws {
        let config = YourGPTConfig(
            widgetUid: widgetUid,
            enableNotifications: true,
            notificationMode: .minimalist,
            autoRegisterToken: true
        )
        try await initialize(config: config)
    }

    // MARK: - Widget Display

    public static func createChatbotViewController(
        widgetUid: String,
        customParams: [String: String] = [:]
    ) -> YourGPTChatbotViewController {
        return YourGPTChatbotViewController(
            widgetUid: widgetUid,
            customParams: customParams
        )
    }

    /// One-liner to present the chatbot widget as a bottom sheet.
    /// Mirrors Android's `show()`.
    public static func show(from viewController: UIViewController) {
        guard let config = core.currentConfig else {
            print("[YourGPTSDK] Error: SDK not initialized. Call initialize() first.")
            return
        }

        let chatbotVC = createChatbotViewController(widgetUid: config.widgetUid)

        if #available(iOS 15.0, *) {
            chatbotVC.modalPresentationStyle = .pageSheet
            if let sheet = chatbotVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
        } else {
            chatbotVC.modalPresentationStyle = .formSheet
        }

        viewController.present(chatbotVC, animated: true)
    }

    /// Open the chatbot widget with an ad-hoc configuration.
    /// Mirrors Android's `openChatbotBottomSheet(fragmentManager, configuration)`.
    public static func show(from viewController: UIViewController, config: YourGPTConfig) {
        let chatbotVC = createChatbotViewController(
            widgetUid: config.widgetUid,
            customParams: config.customParams
        )

        if #available(iOS 15.0, *) {
            chatbotVC.modalPresentationStyle = .pageSheet
            if let sheet = chatbotVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
        } else {
            chatbotVC.modalPresentationStyle = .formSheet
        }

        viewController.present(chatbotVC, animated: true)
    }

    /// Present the chatbot widget and navigate directly to a specific session.
    /// Use when opening from a notification tap or programmatic deep-link.
    public static func openSession(from viewController: UIViewController, sessionUid: String) {
        guard let config = core.currentConfig else {
            print("[YourGPTSDK] Error: SDK not initialized. Call initialize() first.")
            return
        }

        let chatbotVC = createChatbotViewController(
            widgetUid: config.widgetUid,
            customParams: ["session_uid": sessionUid]
        )

        if #available(iOS 15.0, *) {
            chatbotVC.modalPresentationStyle = .pageSheet
            if let sheet = chatbotVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
        } else {
            chatbotVC.modalPresentationStyle = .formSheet
        }

        viewController.present(chatbotVC, animated: true)
    }

    // MARK: - Event Listener

    /// Set a global event listener for SDK and notification events.
    /// Mirrors Android's `setEventListener()`.
    public static func setEventListener(_ listener: YourGPTEventListener?) {
        core.eventListener = listener
    }

    // MARK: - Event System

    /// Register a callback for a named event.
    public static func on(event: String, callback: @escaping (Any?) -> Void) {
        core.on(event: event, callback: callback)
    }

    /// Unregister a callback for a named event.
    public static func off(event: String, callback: @escaping (Any?) -> Void) {
        core.off(event: event, callback: callback)
    }

    // MARK: - User Context

    public static func setUserContext(_ context: [String: Any]) async {
        await core.setUserContext(context)
    }

    // MARK: - State

    public static var isReady: Bool {
        return core.isReady
    }

    public static var currentState: YourGPTSDKState {
        return core.state
    }

    /// Reactive publisher for SDK state changes.
    /// Mirrors Android's `stateFlow: StateFlow<YourGPTSDKState>`.
    public static var statePublisher: AnyPublisher<YourGPTSDKState, Never> {
        return core.$state.eraseToAnyPublisher()
    }

    // MARK: - Widget URL

    /// Build the complete widget URL with optional additional parameters.
    /// Mirrors Android's `buildWidgetUrl(additionalParams)`.
    public static func buildWidgetUrl(additionalParams: [String: String] = [:]) throws -> URL {
        return try core.buildWidgetUrl(additionalParams: additionalParams)
    }

    // MARK: - Lifecycle

    public static func destroy() {
        core.destroy()
    }
}
