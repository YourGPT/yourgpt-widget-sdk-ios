import Foundation

/// YourGPT SDK Configuration Constants
public struct YourGPTSDKConfig {
    
    /// Widget API endpoint configuration
    public struct Endpoints {
        /// Base widget URL - DO NOT CHANGE without coordination
        public static let widgetBase = "https://widget.yourgpt.ai"
        
        /// Constructs the full widget URL with the provided widget UID
        /// Format: https://widget.yourgpt.ai/{widgetUid}
        /// Example: https://widget.yourgpt.ai/232d2602-7cbd-4f6a-87eb-21058599d594
        public static func widgetURL(for widgetUid: String) -> String {
            return "\(widgetBase)/\(widgetUid)"
        }
        
        /// Constructs widget URL with additional query parameters
        public static func widgetURL(for widgetUid: String, queryParams: [URLQueryItem] = []) -> URL? {
            guard var components = URLComponents(string: widgetURL(for: widgetUid)) else {
                return nil
            }
            
            if !queryParams.isEmpty {
                components.queryItems = queryParams
            }
            
            return components.url
        }
    }
    
    /// SDK metadata
    public struct SDK {
        public static let version = "1.0.0"
        public static let platform = "iOS"
        public static let name = "YourGPT iOS SDK"
    }
    
    /// Default configuration values
    public struct Defaults {
        public static let debug = false
        public static let timeout: TimeInterval = 30.0
    }
}

/// Configuration for initializing the SDK
public struct YourGPTConfig {
    public let widgetUid: String
    public let debug: Bool
    public let customParams: [String: String]
    
    public init(
        widgetUid: String,
        debug: Bool = YourGPTSDKConfig.Defaults.debug,
        customParams: [String: String] = [:]
    ) {
        self.widgetUid = widgetUid
        self.debug = debug
        self.customParams = customParams
    }
    
    /// Generates query parameters for the widget URL
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        // Note: userId, authToken, and theme removed (optional)
        
        // Add mobile parameter to enable X icon in widget
        items.append(URLQueryItem(name: "mobileWebView", value: "true"))
        
        // Add custom parameters
        for (key, value) in customParams {
            items.append(URLQueryItem(name: key, value: value))
        }
        
        // Add SDK metadata
        items.append(URLQueryItem(name: "sdk", value: YourGPTSDKConfig.SDK.platform))
        items.append(URLQueryItem(name: "sdkVersion", value: YourGPTSDKConfig.SDK.version))
        
        return items
    }
    
    /// Generates the complete widget URL
    public func buildWidgetURL() -> URL? {
        return YourGPTSDKConfig.Endpoints.widgetURL(
            for: widgetUid,
            queryParams: toQueryItems()
        )
    }
}