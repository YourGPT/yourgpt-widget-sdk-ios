import UIKit
import WebKit
import Combine

public protocol YourGPTChatbotDelegate: AnyObject {
    func chatbotDidReceiveMessage(_ message: [String: Any])
    func chatbotDidOpen()
    func chatbotDidClose()
    func chatbotDidFailWithError(_ error: Error)
    func chatbotDidStartLoading()
    func chatbotDidFinishLoading()
}

public class YourGPTChatbotViewController: UIViewController {
    
    // MARK: - Properties
    
    public weak var delegate: YourGPTChatbotDelegate?
    
    private let widgetUid: String
    
    private var webView: WKWebView!
    private var webViewConfiguration: WKWebViewConfiguration!
    private let sdk = YourGPTSDKCore.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Loading and error states
    private var loadingView: UIView?
    private var errorView: UIView?
    private var isSDKReady = false
    
    // Customization
    public var customLoadingView: UIView?
    public var customErrorView: ((String) -> UIView)?
    
    // MARK: - Initialization
    
    public init(
        widgetUid: String
    ) {
        self.widgetUid = widgetUid
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSDKObserver()
        initializeSDK()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.chatbotDidOpen()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup navigation bar appearance for modal presentation
        if let navigationController = navigationController {
            navigationController.navigationBar.prefersLargeTitles = false
            navigationItem.title = title ?? "AI Assistant"
            
            // Add a subtle separator line at the bottom of navigation bar
            navigationController.navigationBar.setValue(true, forKey: "hidesShadow")
            
            // Modern iOS appearance
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.backgroundColor = .systemBackground
                appearance.shadowColor = .separator
                appearance.shadowImage = UIImage()
                
                navigationController.navigationBar.standardAppearance = appearance
                navigationController.navigationBar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    private func setupSDKObserver() {
        sdk.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleSDKStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func initializeSDK() {
        showLoadingView()
        delegate?.chatbotDidStartLoading()
        
        let config = YourGPTConfig(
            widgetUid: widgetUid,
            debug: true
        )
        
        Task {
            do {
                try await sdk.initialize(config: config)
            } catch {
                await MainActor.run {
                    self.showErrorView(error.localizedDescription)
                    self.delegate?.chatbotDidFailWithError(error)
                }
            }
        }
    }
    
    private func handleSDKStateChange(_ state: YourGPTSDKState) {
        if state.isInitialized && !state.isLoading && state.error == nil {
            isSDKReady = true
            hideLoadingView()
            setupWebView()
            loadChatbot()
        } else if let error = state.error {
            showErrorView(error)
            delegate?.chatbotDidFailWithError(YourGPTError.webViewError(error))
        }
    }
    
    private func setupWebView() {
        guard isSDKReady else { return }
        
        webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.preferences.javaScriptEnabled = true
        
        // Add script message handler for native communication
        let contentController = WKUserContentController()
        contentController.add(self, name: "YourGPTNative")
        webViewConfiguration.userContentController = contentController
        
        webView = WKWebView(frame: view.bounds, configuration: webViewConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadChatbot() {
        guard isSDKReady else { return }
        
        do {
            let url = try sdk.buildWidgetUrl()
            let request = URLRequest(url: url)
            webView.load(request)
        } catch {
            showErrorView(error.localizedDescription)
            delegate?.chatbotDidFailWithError(error)
        }
    }
    
    // MARK: - Loading & Error Views
    
    private func showLoadingView() {
        hideErrorView()
        
        let loading = customLoadingView ?? createDefaultLoadingView()
        loadingView = loading
        
        view.addSubview(loading)
        loading.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loading.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            loading.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func hideLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
    
    private func showErrorView(_ message: String) {
        hideLoadingView()
        
        let error = customErrorView?(message) ?? createDefaultErrorView(message: message)
        errorView = error
        
        view.addSubview(error)
        error.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            error.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            error.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            error.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            error.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func hideErrorView() {
        errorView?.removeFromSuperview()
        errorView = nil
    }
    
    private func createDefaultLoadingView() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        spinner.color = .systemBlue
        
        let titleLabel = UILabel()
        titleLabel.text = "🤖 Connecting to AI Assistant"
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Just a moment while we set things up..."
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        let stackView = UIStackView(arrangedSubviews: [spinner, titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        
        container.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20)
        ])
        
        return container
    }
    
    private func createDefaultErrorView(message: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground
        
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.systemOrange
        
        let titleLabel = UILabel()
        titleLabel.text = "Connection Error"
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.textColor = UIColor.secondaryLabel
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.numberOfLines = 0
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        retryButton.addTarget(self, action: #selector(retryConnection), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        container.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64),
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20)
        ])
        
        return container
    }
    
    private func injectJavaScript() {
        let script = """
(function() {
    window.addEventListener('message', function(event) {
        console.log('Message received:', event.data);
        if (event.data === 'chatbot-close') {
            window.webkit.messageHandlers.YourGPTNative.postMessage({
                type: 'chatbot-close',
                source: 'widget'
            });
        } else if (event.data && typeof event.data === 'object') {
            window.webkit.messageHandlers.YourGPTNative.postMessage(event.data);
        }
    });

    window.nativeBridge = {
        sendMessage: function(message) {
            window.postMessage({ type: 'native:sendMessage', payload: message }, '*');
        },
        setUserContext: function(context) {
            window.postMessage({ type: 'native:setUserContext', payload: context }, '*');
        }
    };

    document.addEventListener('click', function(event) {
        if (event.target && event.target.classList && event.target.classList.contains('widget-close-button')) {
            window.webkit.messageHandlers.YourGPTNative.postMessage({
                type: 'chatbot-close',
                source: 'widget-close-button'
            });
        }
    });

    console.log('YourGPT native bridge initialized');
})();
"""

        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("❌ Error injecting JavaScript: \(error)")
            } else {
                print("✅ JavaScript injected successfully")
            }
        }
    }
    
    // MARK: - Public Methods
    
    public func sendMessage(_ message: String) {
        let script = """
            window.postMessage({
                type: 'sendMessage',
                payload: '\(message)'
            }, '*');
        """
        
        webView.evaluateJavaScript(script)
    }
    
    public func setUserContext(_ context: [String: Any]) {
        guard let contextData = try? JSONSerialization.data(withJSONObject: context),
              let contextString = String(data: contextData, encoding: .utf8) else {
            return
        }
        
        let script = """
            window.postMessage({
                type: 'setUserContext',
                payload: \(contextString)
            }, '*');
        """
        
        webView.evaluateJavaScript(script)
    }
    
    public func openChat() {
        let script = """
            window.postMessage({
                type: 'openChat'
            }, '*');
        """
        
        webView.evaluateJavaScript(script)
    }
    
    // MARK: - Data Management (Mobile SDK Features)
    
    public func setSessionData(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let script = """
            window.postMessage({
                type: 'native:setSessionData',
                payload: \(jsonString)
            }, '*');
        """
        
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error setting session data: \(error)")
            }
        }
    }
    
    public func setVisitorData(_ data: [String: Any]) {
        // Enrich with iOS-specific data
        var enrichedData = data
        enrichedData["platform"] = "iOS"
        enrichedData["deviceModel"] = UIDevice.current.model
        enrichedData["systemVersion"] = UIDevice.current.systemVersion
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            enrichedData["appVersion"] = appVersion
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: enrichedData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let script = """
            window.postMessage({
                type: 'native:setVisitorData',
                payload: \(jsonString)
            }, '*');
        """
        
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error setting visitor data: \(error)")
            }
        }
    }
    
    public func setContactData(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let script = """
            window.postMessage({
                type: 'native:setContactData',
                payload: \(jsonString)
            }, '*');
        """
        
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error setting contact data: \(error)")
            }
        }
    }
    
    // MARK: - Bottom Sheet Dismissal
    
    /// Dismisses the bottom sheet when the widget sends a 'chatbot-close' postMessage.
    /// This method is called automatically when the widget requests to close itself.
    private func dismissBottomSheet() {
        print("🔴 Dismissing bottom sheet...")
        // Dismiss the current view controller (which is the bottom sheet)
        dismiss(animated: true) { [weak self] in
            print("🔴 Bottom sheet dismissed successfully")
            // Notify delegate that chatbot was closed
            self?.delegate?.chatbotDidClose()
        }
    }
    
    // MARK: - Error Handling
    
    @objc private func retryConnection() {
        hideErrorView()
        initializeSDK()
    }
}

// MARK: - WKNavigationDelegate

extension YourGPTChatbotViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.chatbotDidStartLoading()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoadingView()
        hideErrorView()
        injectJavaScript()
        delegate?.chatbotDidFinishLoading()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let errorMessage = "WebView navigation failed: \(error.localizedDescription)"
        showErrorView(errorMessage)
        delegate?.chatbotDidFailWithError(YourGPTError.webViewError(errorMessage))
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let errorMessage = "WebView failed to load: \(error.localizedDescription)"
        showErrorView(errorMessage)
        delegate?.chatbotDidFailWithError(YourGPTError.webViewError(errorMessage))
    }
}

// MARK: - WKScriptMessageHandler

extension YourGPTChatbotViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        switch type {
        // Message events
        case "message:received", "message:new":
            if let payload = body["payload"] as? [String: Any] {
                delegate?.chatbotDidReceiveMessage(payload)
            }
        case "message:sent":
            if let payload = body["payload"] as? [String: Any] {
                print("📤 Message sent: \(payload)")
                // Could add delegate method for message sent if needed
            }
            
        // Chat lifecycle events
        case "chat:opened", "widget:opened":
            delegate?.chatbotDidOpen()
        case "chat:closed", "widget:closed":
            delegate?.chatbotDidClose()
        case "chatbot-close":
            // Close the bottom sheet when widget requests it (from X icon or other close actions)
            let source = body["source"] as? String ?? "unknown"
            print("🔴 Received chatbot-close message from widget (source: \(source))")
            DispatchQueue.main.async { [weak self] in
                self?.dismissBottomSheet()
            }
            
        // Connection events
        case "connection:established":
            print("🔗 Connection established")
        case "connection:lost":
            print("📡 Connection lost")
            if let payload = body["payload"] as? [String: Any],
               let reason = payload["reason"] as? String {
                delegate?.chatbotDidFailWithError(YourGPTError.webViewError("Connection lost: \(reason)"))
            }
        case "connection:restored":
            print("🔄 Connection restored")
            
        // User interaction events
        case "user:typing":
            print("⌨️ User is typing")
        case "user:stopped_typing":
            print("✋ User stopped typing")
            
        // Escalation events
        case "escalation:to_human":
            if let payload = body["payload"] as? [String: Any] {
                print("👨‍💼 Escalated to human: \(payload)")
                // Could add specific delegate method for escalation
            }
        case "escalation:resolved":
            print("✅ Escalation resolved")
            
        // Error events
        case "error:occurred":
            if let payload = body["payload"] as? [String: Any],
               let errorMessage = payload["message"] as? String {
                delegate?.chatbotDidFailWithError(YourGPTError.webViewError(errorMessage))
            }
        case "error:network":
            if let payload = body["payload"] as? [String: Any],
               let errorMessage = payload["message"] as? String {
                delegate?.chatbotDidFailWithError(YourGPTError.webViewError("Network error: \(errorMessage)"))
            }
            
        // SDK lifecycle events
        case "sdk:initialized":
            print("🚀 SDK initialized in WebView")
        case "webview:loaded":
            print("📱 WebView content loaded")
            
        default:
            print("🔍 Unhandled message type: \(type)")
            break
        }
    }
}