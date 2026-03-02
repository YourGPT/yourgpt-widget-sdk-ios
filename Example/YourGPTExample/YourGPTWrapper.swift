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
    static let widgetUid = "69dd8b5d-d4bf-444c-a40f-732d15248ae9" // Required: Your widget UID from YourGPT dashboard

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
        // Quick init with notifications auto-enabled in minimalist mode
        try await YourGPTSDK.quickInitialize(widgetUid: Self.widgetUid)
    }

    // MARK: - Chatbot Management

    func openChatbot(from presentingViewController: UIViewController, delegate: YourGPTChatbotDelegate?) {
        guard YourGPTSDK.isReady else {
            showAlert(on: presentingViewController, title: "SDK Not Ready", message: "Please wait for the SDK to initialize.")
            return
        }

        chatbotViewController = YourGPTSDK.createChatbotViewController(
            widgetUid: Self.widgetUid, // Required: Your widget UID from YourGPT dashboard
        )

        // Create bottom sheet presentation
        bottomSheetController = BottomSheetChatbotViewController()
        bottomSheetController?.setChatbotViewController(chatbotViewController!)
        bottomSheetController?.chatbotDelegate = delegate
        chatbotViewController?.delegate = bottomSheetController
        
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
    private var loadingView: UIView?
    private var activityIndicator: UIActivityIndicatorView?
    private var loadingLabel: UILabel?
    weak var chatbotDelegate: YourGPTChatbotDelegate?
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
        setupLoadingView()
    }
    
    private func setupLoadingView() {
        // Create loading container
        loadingView = UIView()
        loadingView?.backgroundColor = .systemBackground
        loadingView?.translatesAutoresizingMaskIntoConstraints = false
        
        // Create activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.color = .label
        activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator?.startAnimating()
        
        // Create loading label
        loadingLabel = UILabel()
        loadingLabel?.text = "Loading Chatbot..."
        loadingLabel?.font = .preferredFont(forTextStyle: .headline)
        loadingLabel?.textColor = .secondaryLabel
        loadingLabel?.textAlignment = .center
        loadingLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        if let loadingView = loadingView,
           let activityIndicator = activityIndicator,
           let loadingLabel = loadingLabel {
            view.addSubview(loadingView)
            loadingView.addSubview(activityIndicator)
            loadingView.addSubview(loadingLabel)
            
            // Constraints
            NSLayoutConstraint.activate([
                loadingView.topAnchor.constraint(equalTo: view.topAnchor),
                loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -20),
                
                loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
                loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
                loadingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: loadingView.leadingAnchor, constant: 20),
                loadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: loadingView.trailingAnchor, constant: -20)
            ])
        }
    }
    
    private func hideLoadingView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView?.alpha = 0
        }) { _ in
            self.activityIndicator?.stopAnimating()
            self.loadingView?.removeFromSuperview()
            self.loadingView = nil
            self.activityIndicator = nil
            self.loadingLabel = nil
        }
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

// MARK: - YourGPTChatbotDelegate

@available(iOS 13.0, *)
extension BottomSheetChatbotViewController: YourGPTChatbotDelegate {
    
    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        chatbotDelegate?.chatbotDidReceiveMessage(message)
    }
    
    func chatbotDidOpen() {
        hideLoadingView()
        chatbotDelegate?.chatbotDidOpen()
    }
    
    func chatbotDidClose() {
        chatbotDelegate?.chatbotDidClose()
    }
    
    func chatbotDidFailWithError(_ error: Error) {
        hideLoadingView()
        chatbotDelegate?.chatbotDidFailWithError(error)
    }
    
    func chatbotDidStartLoading() {
        chatbotDelegate?.chatbotDidStartLoading()
    }
    
    func chatbotDidFinishLoading() {
        hideLoadingView()
        chatbotDelegate?.chatbotDidFinishLoading()
    }
}
