import UIKit
import YourGPTSDK
import Combine

@available(iOS 13.0, *)
class YourGPTWrapper: NSObject {

    // MARK: - Properties

    static let shared = YourGPTWrapper()

    private var cancellables = Set<AnyCancellable>()
    private var chatbotViewController: YourGPTChatbotViewController?
    private var bottomSheetController: BottomSheetChatbotViewController?

    // Configuration
    private let widgetUid = "your-widget-uid" // Required: Your widget UID from YourGPT dashboard

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

    func initializeSDK() async throws {
        let config = YourGPTConfig(
            widgetUid: widgetUid,
        )

        try await YourGPTSDK.initialize(config: config)
    }

    // MARK: - Chatbot Management

    func openChatbot(from presentingViewController: UIViewController, delegate: YourGPTChatbotDelegate?) {
        guard YourGPTSDK.isReady else {
            showAlert(on: presentingViewController, title: "SDK Not Ready", message: "Please wait for the SDK to initialize.")
            return
        }

        chatbotViewController = YourGPTSDK.createChatbotViewController(
            widgetUid: widgetUid, // Required: Your widget UID from YourGPT dashboard
        )

        chatbotViewController?.delegate = delegate

        // Create bottom sheet presentation
        bottomSheetController = BottomSheetChatbotViewController()
        bottomSheetController?.setChatbotViewController(chatbotViewController!)
        
        // Set up dismissal callback
        bottomSheetController?.onDismiss = { [weak self] in
            self?.chatbotViewController = nil
            self?.bottomSheetController = nil
        }
        
        // Present as bottom sheet
        if #available(iOS 15.0, *) {
            bottomSheetController?.modalPresentationStyle = .pageSheet
            if let sheet = bottomSheetController?.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
        } else {
            bottomSheetController?.modalPresentationStyle = .formSheet
        }

        if let bottomSheet = bottomSheetController {
            presentingViewController.present(bottomSheet, animated: true)
        }
    }

    @objc private func closeChatbot() {
        bottomSheetController?.dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
            self?.bottomSheetController = nil
        }
    }

    func dismissChatbot() {
        bottomSheetController?.dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
            self?.bottomSheetController = nil
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

// MARK: - BottomSheetChatbotViewController

@available(iOS 13.0, *)
class BottomSheetChatbotViewController: UIViewController {
    
    // MARK: - Properties
    
    private var chatbotViewController: YourGPTChatbotViewController?
    var onDismiss: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateChatbotFrame()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
    }
    
    private func updateChatbotFrame() {
        guard let chatbotVC = chatbotViewController else { return }
        
        chatbotVC.view.frame = view.bounds
    }
    
    // MARK: - Public Methods
    
    func setChatbotViewController(_ chatbotVC: YourGPTChatbotViewController) {
        // Remove existing chatbot if any
        chatbotViewController?.view.removeFromSuperview()
        chatbotViewController?.removeFromParent()
        
        // Add new chatbot
        chatbotViewController = chatbotVC
        addChild(chatbotVC)
        view.addSubview(chatbotVC.view)
        chatbotVC.didMove(toParent: self)
        
        // Update frame
        updateChatbotFrame()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}
