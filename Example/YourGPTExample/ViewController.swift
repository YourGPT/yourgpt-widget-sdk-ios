import UIKit
import YourGPTSDK

@available(iOS 13.0, *)
class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var openChatButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSDKObserver()
        initializeSDK()
    }
    
    private func setupUI() {
        title = "YourGPT iOS SDK Demo"
        view.backgroundColor = .systemBackground
        
        // If storyboard outlets are nil, create UI programmatically
        if statusLabel == nil || openChatButton == nil {
            createUIElements()
        }
        
        // Configure button
        openChatButton?.layer.cornerRadius = 8
        openChatButton?.isEnabled = false
        updateStatus("Initializing...")
    }
    
    private func createUIElements() {
        // Create status label
        let label = UILabel()
        label.text = "SDK Status: Initializing..."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Create open chat button
        let button = UIButton(type: .system)
        button.setTitle("Open Chatbot", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openChatTapped), for: .touchUpInside)
        
        // Add to view
        view.addSubview(label)
        view.addSubview(button)
        
        // Set outlets
        statusLabel = label
        openChatButton = button
        
        // Setup constraints
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupSDKObserver() {
        YourGPTWrapper.shared.onStateChange = { [weak self] state in
            self?.updateUIForSDKState(state)
        }
    }
    
    private func initializeSDK() {
        Task {
            do {
                try await YourGPTWrapper.shared.initializeSDK()
            } catch {
                await MainActor.run {
                    self.showAlert(title: "SDK Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func updateUIForSDKState(_ state: YourGPTSDKState) {
        statusLabel?.text = "SDK Status: \(state.connectionState.rawValue.capitalized)"
        
        switch state.connectionState {
        case .connected:
            statusLabel?.textColor = .systemGreen
            openChatButton?.isEnabled = true
            updateStatus("Ready - SDK Connected!", color: .systemGreen)
        case .connecting:
            statusLabel?.textColor = .systemOrange
            openChatButton?.isEnabled = false
            updateStatus("Connecting...", color: .systemOrange)
        case .error:
            statusLabel?.textColor = .systemRed
            openChatButton?.isEnabled = false
            if let error = state.error {
                updateStatus("Error: \(error)", color: .systemRed)
            }
        case .disconnected:
            statusLabel?.textColor = .systemGray
            openChatButton?.isEnabled = false
            updateStatus("Disconnected", color: .systemGray)
        }
    }
    
    private func updateStatus(_ text: String, color: UIColor = .systemOrange) {
        statusLabel?.text = "SDK Status: \(text)"
        statusLabel?.textColor = color
    }
    
    @IBAction func openChatTapped(_ sender: UIButton? = nil) {
        YourGPTWrapper.shared.openChatbot(from: self, delegate: self)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - YourGPTChatbotDelegate

@available(iOS 13.0, *)
extension ViewController: YourGPTChatbotDelegate {
    
    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        print("📨 New message received: \(message)")
        
        DispatchQueue.main.async {
            self.showAlert(
                title: "New Message",
                message: "Received: \(message.description)"
            )
        }
    }
    
    func chatbotDidOpen() {
        print("🚀 Chatbot opened")
    }
    
    func chatbotDidClose() {
        print("📴 Chatbot closed")
        YourGPTWrapper.shared.dismissChatbot()
    }
    
    func chatbotDidFailWithError(_ error: Error) {
        print("❌ Chatbot error: \(error)")
        
        DispatchQueue.main.async {
            self.showAlert(
                title: "Chatbot Error",
                message: error.localizedDescription
            )
        }
    }
    
    func chatbotDidStartLoading() {
        print("⏳ Chatbot started loading")
    }
    
    func chatbotDidFinishLoading() {
        print("✅ Chatbot finished loading")
    }
}
