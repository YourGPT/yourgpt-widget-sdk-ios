import Foundation
import UIKit

public struct YourGPTSDK {
    public static let version = "1.0.0"
    public static let core = YourGPTSDKCore.shared
    
    public static func initialize(config: YourGPTConfig) async throws {
        try await core.initialize(config: config)
    }
    
    public static func createChatbotViewController(
        widgetUid: String,
        userId: String? = nil,
        authToken: String? = nil,
        theme: YourGPTTheme = .light
    ) -> YourGPTChatbotViewController {
        return YourGPTChatbotViewController(
            widgetUid: widgetUid,
            userId: userId,
            authToken: authToken,
            theme: theme
        )
    }
    
    public static func setUserContext(_ context: [String: Any]) async {
        await core.setUserContext(context)
    }
    
    public static var isReady: Bool {
        return core.isReady
    }
    
    public static var currentState: YourGPTSDKState {
        return core.state
    }
    
    public static func destroy() {
        core.destroy()
    }
}