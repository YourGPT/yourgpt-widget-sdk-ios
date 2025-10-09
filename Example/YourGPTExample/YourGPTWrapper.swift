import UIKit
import YourGPTSDK
import Combine

@available(iOS 13.0, *)
class YourGPTWrapper: NSObject {

    // MARK: - Properties

    static let shared = YourGPTWrapper()

    private var cancellables = Set<AnyCancellable>()
    private var chatbotViewController: YourGPTChatbotViewController?

    // State observer
    var onStateChange: ((YourGPTSDKState) -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupSDKObserver()
    }

    // MARK: - SDK Setup

    private func setupSDKObserver() {
        YourGPTSDK.core.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.onStateChange?(state)
            }
            .store(in: &cancellables)
    }

    func initializeSDK(widgetUid: String) async throws {
        let config = YourGPTConfig(widgetUid: widgetUid)
        try await YourGPTSDK.initialize(config: config)
    }

    // MARK: - Chatbot Management

    func openChatbot(from presentingViewController: UIViewController, delegate: YourGPTChatbotDelegate?) {
        guard YourGPTSDK.isReady else {
            showAlert(on: presentingViewController, title: "SDK Not Ready", message: "Please wait for the SDK to initialize.")
            return
        }

        chatbotViewController = YourGPTSDK.createChatbotViewController()

        chatbotViewController?.delegate = delegate

        // Add close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeChatbot)
        )
        chatbotViewController?.navigationItem.rightBarButtonItem = closeButton

        let navigationController = UINavigationController(rootViewController: chatbotViewController!)
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.modalTransitionStyle = .coverVertical

        presentingViewController.present(navigationController, animated: true)
    }

    @objc private func closeChatbot() {
        chatbotViewController?.dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
        }
    }

    func dismissChatbot() {
        chatbotViewController?.dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
        }
    }

    // MARK: - Helpers

    var isReady: Bool {
        return YourGPTSDK.isReady
    }

    var currentState: YourGPTSDKState {
        return YourGPTSDK.core.state
    }

    private func showAlert(on viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
