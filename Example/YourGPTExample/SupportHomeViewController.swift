import UIKit
import YourGPTSDK
import Combine

@available(iOS 13.0, *)
class SupportHomeViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    private var chatbotViewController: YourGPTChatbotViewController?
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let statusCard = UIView()
    private let statusLabel = UILabel()
    private let quickActionsSection = UIStackView()
    private let faqSection = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSDKObserver()
        initializeSDK()
    }
    
    private func setupUI() {
        title = "Help & Support"
        view.backgroundColor = UIColor.systemGroupedBackground
        
        setupNavigationBar()
        setupScrollView()
        setupHeaderView()
        setupStatusCard()
        setupQuickActions()
        setupFAQSection()
        layoutViews()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Add settings button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .clear
        
        let welcomeLabel = UILabel()
        welcomeLabel.text = "👋 How can we help you today?"
        welcomeLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        welcomeLabel.textColor = .label
        welcomeLabel.numberOfLines = 0
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Get instant help or chat with our AI assistant"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(welcomeLabel)
        headerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            welcomeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            welcomeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    private func setupStatusCard() {
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.backgroundColor = .secondarySystemGroupedBackground
        statusCard.layer.cornerRadius = 12
        statusCard.layer.shadowColor = UIColor.black.cgColor
        statusCard.layer.shadowOffset = CGSize(width: 0, height: 1)
        statusCard.layer.shadowRadius = 3
        statusCard.layer.shadowOpacity = 0.1
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "circle.fill")
        iconView.tintColor = .systemOrange
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.text = "Connecting to support..."
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .label
        statusLabel.numberOfLines = 0
        
        let chatButton = UIButton(type: .system)
        chatButton.setTitle("Chat", for: .normal)
        chatButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        chatButton.backgroundColor = .systemBlue
        chatButton.setTitleColor(.white, for: .normal)
        chatButton.layer.cornerRadius = 8
        chatButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        chatButton.addTarget(self, action: #selector(openChatTapped), for: .touchUpInside)
        chatButton.isEnabled = false
        chatButton.alpha = 0.6
        chatButton.tag = 100 // For easy access
        
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(chatButton)
        
        statusCard.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12),
            
            stackView.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupQuickActions() {
        quickActionsSection.axis = .vertical
        quickActionsSection.spacing = 12
        quickActionsSection.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Quick Actions"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        
        quickActionsSection.addArrangedSubview(titleLabel)
        
        let actions = [
            ("💬", "Start a Conversation", "Chat with our AI assistant", #selector(openChatTapped)),
            ("📧", "Email Support", "Send us an email for detailed help", #selector(emailSupportTapped)),
            ("📞", "Call Support", "Speak directly with our team", #selector(callSupportTapped)),
            ("🔍", "Search Help Articles", "Find answers in our knowledge base", #selector(searchHelpTapped))
        ]
        
        for (icon, title, subtitle, action) in actions {
            let actionView = createActionCard(icon: icon, title: title, subtitle: subtitle, action: action)
            quickActionsSection.addArrangedSubview(actionView)
        }
    }
    
    private func setupFAQSection() {
        faqSection.axis = .vertical
        faqSection.spacing = 12
        faqSection.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Frequently Asked Questions"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        
        faqSection.addArrangedSubview(titleLabel)
        
        let faqs = [
            ("How do I reset my password?", "You can reset your password by going to Settings > Account > Reset Password"),
            ("How do I update my payment method?", "Visit your account settings and select 'Payment Methods' to add or update cards"),
            ("How do I cancel my subscription?", "You can cancel anytime in Settings > Subscription > Cancel Subscription"),
            ("How do I contact support?", "Use the chat button above or email us at support@yourgpt.ai")
        ]
        
        for (question, answer) in faqs {
            let faqView = createFAQCard(question: question, answer: answer)
            faqSection.addArrangedSubview(faqView)
        }
    }
    
    private func createActionCard(icon: String, title: String, subtitle: String, action: Selector) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 24)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        
        let chevron = UIImageView()
        chevron.image = UIImage(systemName: "chevron.right")
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(iconLabel)
        stackView.addArrangedSubview(textStack)
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(chevron)
        
        container.addSubview(stackView)
        container.addSubview(button)
        
        NSLayoutConstraint.activate([
            iconLabel.widthAnchor.constraint(equalToConstant: 40),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 12),
            
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        return container
    }
    
    private func createFAQCard(question: String, answer: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let questionLabel = UILabel()
        questionLabel.text = question
        questionLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        questionLabel.textColor = .label
        questionLabel.numberOfLines = 0
        
        let answerLabel = UILabel()
        answerLabel.text = answer
        answerLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        answerLabel.textColor = .secondaryLabel
        answerLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(questionLabel)
        stackView.addArrangedSubview(answerLabel)
        
        container.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    private func layoutViews() {
        contentView.addSubview(headerView)
        contentView.addSubview(statusCard)
        contentView.addSubview(quickActionsSection)
        contentView.addSubview(faqSection)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Status card
            statusCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            statusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Quick actions
            quickActionsSection.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 32),
            quickActionsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickActionsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // FAQ section
            faqSection.topAnchor.constraint(equalTo: quickActionsSection.bottomAnchor, constant: 32),
            faqSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            faqSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            faqSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupSDKObserver() {
        YourGPTSDK.core.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUIForSDKState(state)
            }
            .store(in: &cancellables)
    }
    
    private func initializeSDK() {
        let config = YourGPTConfig(
            widgetUid: "232d2602-7cbd-4f6a-87eb-21058599d594",
            userId: "demo-user-123",
            authToken: "demo-auth-token",
            theme: .light,
            debug: true
        )
        
        Task {
            do {
                try await YourGPTSDK.initialize(config: config)
            } catch {
                await MainActor.run {
                    self.showAlert(title: "SDK Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func updateUIForSDKState(_ state: YourGPTSDKState) {
        guard let chatButton = statusCard.viewWithTag(100) as? UIButton,
              let iconView = statusCard.subviews.first?.subviews.first as? UIImageView else { return }
        
        switch state.connectionState {
        case .connected:
            statusLabel.text = "✅ AI Assistant Ready"
            iconView.tintColor = .systemGreen
            chatButton.isEnabled = true
            chatButton.alpha = 1.0
            chatButton.backgroundColor = .systemBlue
        case .connecting:
            statusLabel.text = "🔄 Connecting to AI Assistant..."
            iconView.tintColor = .systemOrange
            chatButton.isEnabled = false
            chatButton.alpha = 0.6
        case .error:
            statusLabel.text = "❌ Connection Failed"
            iconView.tintColor = .systemRed
            chatButton.isEnabled = false
            chatButton.alpha = 0.6
            if let error = state.error {
                statusLabel.text = "❌ Error: \(error)"
            }
        case .disconnected:
            statusLabel.text = "⚫ Disconnected"
            iconView.tintColor = .systemGray
            chatButton.isEnabled = false
            chatButton.alpha = 0.6
        }
    }
    
    // MARK: - Actions
    
    @objc private func openChatTapped() {
        guard YourGPTSDK.isReady else {
            showAlert(title: "AI Assistant Not Ready", message: "Please wait while we connect to our AI assistant.")
            return
        }
        
        chatbotViewController = YourGPTSDK.createChatbotViewController(
            widgetUid: "232d2602-7cbd-4f6a-87eb-21058599d594",
            userId: "demo-user-123",
            authToken: "demo-auth-token",
            theme: .light
        )
        
        chatbotViewController?.delegate = self
        
        // Set up data for the chatbot session
        setupChatbotData()
        
        let navigationController = UINavigationController(rootViewController: chatbotViewController!)
        
        // Modern sheet presentation (iOS 13+)
        if #available(iOS 15.0, *) {
            if let sheet = navigationController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            }
        } else {
            navigationController.modalPresentationStyle = .pageSheet
        }
        
        // Add close button with X icon
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeChatTapped)
        )
        closeButton.tintColor = .systemGray2
        chatbotViewController?.navigationItem.rightBarButtonItem = closeButton
        
        // Set navigation title
        chatbotViewController?.title = "AI Assistant"
        
        present(navigationController, animated: true)
    }
    
    @objc private func closeChatTapped() {
        dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
        }
    }
    
    // MARK: - Data Management Demo
    
    private func setupChatbotData() {
        guard let chatbot = chatbotViewController else { return }
        
        // Demo session data
        let sessionData: [String: Any] = [
            "userId": "demo-user-123",
            "plan": "premium",
            "sessionStart": ISO8601DateFormatter().string(from: Date()),
            "features": ["ai-actions", "support-chat", "escalation"],
            "userSegment": "premium-support",
            "supportTier": "priority"
        ]
        
        // Demo visitor data (will be enriched with iOS-specific info automatically)
        let visitorData: [String: Any] = [
            "source": "support-screen",
            "campaign": "ios-app-support",
            "referrer": "help-screen",
            "userJourney": ["app-launch", "support-screen", "chat-opened"],
            "screenSize": "\(UIScreen.main.bounds.width)x\(UIScreen.main.bounds.height)"
        ]
        
        // Demo contact data
        let contactData: [String: Any] = [
            "email": "demo@example.com",
            "name": "Demo User",
            "phone": "+1-555-0123",
            "user_hash": "demo-secure-hash-123",
            "preferredLanguage": Locale.current.languageCode ?? "en",
            "timezone": TimeZone.current.identifier
        ]
        
        // Set data after a small delay to ensure WebView is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            chatbot.setSessionData(sessionData)
            chatbot.setVisitorData(visitorData)
            chatbot.setContactData(contactData)
            
            // Optional: Set initial user context
            chatbot.setUserContext([
                "supportContext": "general-help",
                "previousInteractions": 3,
                "lastContactDate": "2024-01-10",
                "satisfactionScore": 4.5
            ])
        }
    }
    
    @objc private func settingsTapped() {
        showAlert(title: "Settings", message: "Settings functionality would be implemented here.")
    }
    
    @objc private func emailSupportTapped() {
        showAlert(title: "Email Support", message: "This would open your email app to contact support@yourgpt.ai")
    }
    
    @objc private func callSupportTapped() {
        showAlert(title: "Call Support", message: "This would initiate a call to our support number: +1-800-YOURGPT")
    }
    
    @objc private func searchHelpTapped() {
        showAlert(title: "Help Search", message: "This would open our knowledge base search functionality.")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - YourGPTChatbotDelegate

@available(iOS 13.0, *)
extension SupportHomeViewController: YourGPTChatbotDelegate {
    
    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        print("📨 New message received: \(message)")
        // Don't show alert for every message in production
        // This is just for demo purposes
    }
    
    func chatbotDidOpen() {
        print("🚀 Chatbot opened")
    }
    
    func chatbotDidClose() {
        print("📴 Chatbot closed")
        dismiss(animated: true) { [weak self] in
            self?.chatbotViewController = nil
        }
    }
    
    func chatbotDidFailWithError(_ error: Error) {
        print("❌ Chatbot error: \(error)")
        
        DispatchQueue.main.async {
            self.showAlert(
                title: "Chat Error",
                message: "There was an issue with the chat: \(error.localizedDescription)"
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