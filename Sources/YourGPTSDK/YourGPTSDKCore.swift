import Foundation
import Combine

// Theme support removed as optional and not required

public enum YourGPTConnectionState: String, CaseIterable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case error = "error"
}

// YourGPTConfig is now defined in YourGPTConfig.swift

public struct YourGPTSDKState {
    public let isInitialized: Bool
    public let isLoading: Bool
    public let error: String?
    public let connectionState: YourGPTConnectionState
    
    public init(
        isInitialized: Bool = false,
        isLoading: Bool = false,
        error: String? = nil,
        connectionState: YourGPTConnectionState = .disconnected
    ) {
        self.isInitialized = isInitialized
        self.isLoading = isLoading
        self.error = error
        self.connectionState = connectionState
    }
}

public class YourGPTSDKCore: ObservableObject {
    public static let shared = YourGPTSDKCore()
    
    @Published public private(set) var state = YourGPTSDKState()
    
    private var config: YourGPTConfig?
    private var eventListeners: [String: [(Any?) -> Void]] = [:]

    /// Global event listener for SDK and notification events.
    /// Set via `YourGPTSDK.setEventListener(_:)`.
    public var eventListener: YourGPTEventListener?

    private init() {}
    
    public func initialize(config: YourGPTConfig) async throws {
        log("Initializing SDK with widgetUid: \(config.widgetUid)")
        
        guard !config.widgetUid.isEmpty else {
            throw YourGPTError.invalidConfiguration("widgetUid is required")
        }
        
        await MainActor.run {
            self.state = YourGPTSDKState(
                isLoading: true,
                connectionState: .connecting
            )
        }
        
        do {
            self.config = config
            
            // Validate widget
            try await validateWidget()
            
            await MainActor.run {
                self.state = YourGPTSDKState(
                    isInitialized: true,
                    isLoading: false,
                    connectionState: .connected
                )
            }
            
            emit(event: "sdk:initialized", data: config)
            log("SDK initialized successfully")
            
        } catch {
            let errorMessage = "Failed to initialize SDK: \(error.localizedDescription)"
            
            await MainActor.run {
                self.state = YourGPTSDKState(
                    isLoading: false,
                    error: errorMessage,
                    connectionState: .error
                )
            }
            
            emit(event: "sdk:error", data: errorMessage)
            throw error
        }
    }
    
    private func validateWidget() async throws {
        guard let config = config else {
            throw YourGPTError.notInitialized
        }
        
        // Simulate widget validation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if config.widgetUid.count < 3 {
            throw YourGPTError.invalidConfiguration("Invalid widget UID")
        }
    }
    
    public func buildWidgetUrl(additionalParams: [String: String] = [:]) throws -> URL {
        guard let config = config else {
            throw YourGPTError.notInitialized
        }
        
        guard isReady else {
            throw YourGPTError.notReady
        }
        
        // Create config with additional params
        let configWithParams = config.withParams(additionalParams)
        
        guard let url = configWithParams.buildWidgetURL() else {
            throw YourGPTError.invalidURL
        }
        
        return url
    }
    
    public var isReady: Bool {
        return state.isInitialized && !state.isLoading && state.error == nil
    }
    
    public var currentConfig: YourGPTConfig? {
        return config
    }
    
    // Event system
    public func on(event: String, callback: @escaping (Any?) -> Void) {
        if eventListeners[event] == nil {
            eventListeners[event] = []
        }
        eventListeners[event]?.append(callback)
    }
    
    public func off(event: String, callback: @escaping (Any?) -> Void) {
        // Note: This is a simplified implementation
        // In production, you'd need to compare function references
        eventListeners[event]?.removeAll()
    }
    
    private func emit(event: String, data: Any? = nil) {
        eventListeners[event]?.forEach { callback in
            callback(data)
        }
    }
    
    public func setUserContext(_ context: [String: Any]) async {
        log("Setting user context: \(context)")
        emit(event: "sdk:userContextSet", data: context)
    }
    
    public func updateConfig(_ newConfig: YourGPTConfig) async throws {
        guard state.isInitialized else {
            throw YourGPTError.notInitialized
        }
        
        self.config = newConfig
        emit(event: "sdk:configUpdated", data: newConfig)
    }
    
    private func log(_ message: String) {
        if config?.debug == true {
            print("[YourGPTSDK] \(message)")
        }
    }
    
    public func destroy() {
        log("Destroying SDK instance")
        config = nil
        state = YourGPTSDKState()
        eventListeners.removeAll()
        eventListener = nil
    }
}

public enum YourGPTError: LocalizedError {
    case invalidConfiguration(String)
    case notInitialized
    case notReady
    case invalidURL
    case webViewError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .notInitialized:
            return "SDK not initialized"
        case .notReady:
            return "SDK not ready"
        case .invalidURL:
            return "Invalid URL"
        case .webViewError(let message):
            return "WebView error: \(message)"
        }
    }
}