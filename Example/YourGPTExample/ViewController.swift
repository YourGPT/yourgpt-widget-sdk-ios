import UIKit
import YourGPTSDK

struct Subscription {
    let name: String
    let icon: String
    let price: Double
    let cycle: String
    let nextBilling: Date
    let color: UIColor
}

@available(iOS 13.0, *)
class ViewController: UIViewController {
    
    private var subscriptions: [Subscription] = []
    private var collectionView: UICollectionView!
    private var tabBarView: UIView!
    private var headerView: UIView!
    private var totalSpendLabel: UILabel!
    private var monthlyTotalLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupSubscriptions()
        setupUI()
        setupSDKObserver()
        initializeSDK()
    }
    
    private func setupBackground() {
        // Use system background color for automatic light/dark mode support
        view.backgroundColor = .systemGroupedBackground
    }
    
    private func setupSubscriptions() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        subscriptions = [
            Subscription(name: "Netflix", icon: "tv.fill", price: 15.99, cycle: "monthly", 
                        nextBilling: formatter.date(from: "2025-01-15") ?? Date(), 
                        color: .systemRed),
            Subscription(name: "Spotify", icon: "music.note.list", price: 9.99, cycle: "monthly", 
                        nextBilling: formatter.date(from: "2025-01-20") ?? Date(), 
                        color: .systemGreen),
            Subscription(name: "iCloud+", icon: "icloud.fill", price: 2.99, cycle: "monthly", 
                        nextBilling: formatter.date(from: "2025-01-01") ?? Date(), 
                        color: .systemBlue),
            Subscription(name: "GitHub Pro", icon: "chevron.left.forwardslash.chevron.right", price: 7.00, cycle: "monthly", 
                        nextBilling: formatter.date(from: "2025-01-10") ?? Date(), 
                        color: .systemPurple),
            Subscription(name: "Adobe CC", icon: "paintbrush.fill", price: 54.99, cycle: "monthly", 
                        nextBilling: formatter.date(from: "2025-01-05") ?? Date(), 
                        color: .systemPink),
            Subscription(name: "Disney+", icon: "star.fill", price: 7.99, cycle: "monthly", 
                        nextBilling: formatter.date(from: "2025-01-25") ?? Date(), 
                        color: .systemIndigo)
        ]
    }
    
    private func setupUI() {
        title = "Subscriptions"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        setupHeaderView()
        setupCollectionView()
        setupFloatingTabBar()
    }
    
    private func setupHeaderView() {
        // Create clean header container
        headerView = UIView()
        headerView.backgroundColor = .secondarySystemGroupedBackground
        headerView.layer.cornerRadius = 16
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Create stack for stats
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.backgroundColor = .separator
        stackView.layer.cornerRadius = 12
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(stackView)
        
        // Monthly container
        let monthlyContainer = UIView()
        monthlyContainer.backgroundColor = .secondarySystemGroupedBackground
        
        let monthlyTitleLabel = UILabel()
        monthlyTitleLabel.text = "Monthly"
        monthlyTitleLabel.font = .preferredFont(forTextStyle: .caption1)
        monthlyTitleLabel.textColor = .secondaryLabel
        monthlyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        monthlyTotalLabel = UILabel()
        monthlyTotalLabel.text = "$0.00"
        monthlyTotalLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        monthlyTotalLabel.textColor = .label
        monthlyTotalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        monthlyContainer.addSubview(monthlyTitleLabel)
        monthlyContainer.addSubview(monthlyTotalLabel)
        
        // Yearly container
        let yearlyContainer = UIView()
        yearlyContainer.backgroundColor = .secondarySystemGroupedBackground
        
        let yearlyTitleLabel = UILabel()
        yearlyTitleLabel.text = "Yearly"
        yearlyTitleLabel.font = .preferredFont(forTextStyle: .caption1)
        yearlyTitleLabel.textColor = .secondaryLabel
        yearlyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalSpendLabel = UILabel()
        totalSpendLabel.text = "$0.00"
        totalSpendLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        totalSpendLabel.textColor = .label
        totalSpendLabel.translatesAutoresizingMaskIntoConstraints = false
        
        yearlyContainer.addSubview(yearlyTitleLabel)
        yearlyContainer.addSubview(totalSpendLabel)
        
        stackView.addArrangedSubview(monthlyContainer)
        stackView.addArrangedSubview(yearlyContainer)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            stackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            // Monthly labels
            monthlyTitleLabel.topAnchor.constraint(equalTo: monthlyContainer.topAnchor, constant: 12),
            monthlyTitleLabel.centerXAnchor.constraint(equalTo: monthlyContainer.centerXAnchor),
            
            monthlyTotalLabel.topAnchor.constraint(equalTo: monthlyTitleLabel.bottomAnchor, constant: 4),
            monthlyTotalLabel.centerXAnchor.constraint(equalTo: monthlyContainer.centerXAnchor),
            
            // Yearly labels
            yearlyTitleLabel.topAnchor.constraint(equalTo: yearlyContainer.topAnchor, constant: 12),
            yearlyTitleLabel.centerXAnchor.constraint(equalTo: yearlyContainer.centerXAnchor),
            
            totalSpendLabel.topAnchor.constraint(equalTo: yearlyTitleLabel.bottomAnchor, constant: 4),
            totalSpendLabel.centerXAnchor.constraint(equalTo: yearlyContainer.centerXAnchor)
        ])
        
        updateTotals()
    }
    
    private func updateTotals() {
        let monthlyTotal = subscriptions.reduce(0) { $0 + $1.price }
        let yearlyTotal = monthlyTotal * 12
        
        monthlyTotalLabel?.text = String(format: "$%.2f", monthlyTotal)
        totalSpendLabel?.text = String(format: "$%.2f", yearlyTotal)
    }
    
    private func setupCollectionView() {
        // Modern compositional layout
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(180)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(180)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 10, bottom: 120, trailing: 10)
        section.interGroupSpacing = 16  // Add vertical spacing between rows
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(SubscriptionCell.self, forCellWithReuseIdentifier: "SubscriptionCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupFloatingTabBar() {
        // Create floating tab bar container
        tabBarView = UIView()
        tabBarView.backgroundColor = .secondarySystemBackground
        tabBarView.layer.cornerRadius = 30
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow for floating effect
        tabBarView.layer.shadowColor = UIColor.black.cgColor
        tabBarView.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBarView.layer.shadowOpacity = 0.1
        tabBarView.layer.shadowRadius = 10
        
        view.addSubview(tabBarView)
        
        // Create tab buttons
        let homeButton = createTabButton(icon: "house.fill", isSelected: true)
        let statsButton = createTabButton(icon: "chart.bar.fill", isSelected: false)
        let addButton = createTabButton(icon: "plus.circle.fill", isSelected: false)
        let chatButton = createTabButton(icon: "message.fill", isSelected: false)
        let settingsButton = createTabButton(icon: "gearshape.fill", isSelected: false)
        
        // Set up actions
        homeButton.tag = 0
        statsButton.tag = 1
        addButton.tag = 2
        chatButton.tag = 3
        settingsButton.tag = 4
        
        chatButton.addTarget(self, action: #selector(openChatTapped), for: .touchUpInside)
        homeButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        statsButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        
        // Store chat button reference for SDK state updates
        let buttons = [homeButton, statsButton, addButton, chatButton, settingsButton]
        
        // Create stack view for tabs
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        tabBarView.addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            tabBarView.heightAnchor.constraint(equalToConstant: 60),
            
            stackView.leadingAnchor.constraint(equalTo: tabBarView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: tabBarView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: tabBarView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: tabBarView.bottomAnchor)
        ])
    }
    
    private func createTabButton(icon: String, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = isSelected ? .systemBlue : .secondaryLabel
        return button
    }
    
    @objc private func tabTapped(_ sender: UIButton) {
        // Update button states
        for subview in (sender.superview as? UIStackView)?.arrangedSubviews ?? [] {
            if let button = subview as? UIButton {
                button.tintColor = (button == sender) ? .systemBlue : .secondaryLabel
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Handle tab selection
        switch sender.tag {
        case 0:
            print("Home tapped")
        case 1:
            print("Stats tapped")
        case 2:
            print("Add subscription tapped")
        case 4:
            print("Settings tapped")
        default:
            break
        }
    }
    
    private func setupSDKObserver() {
        YourGPTWrapper.shared.onStateChange = { [weak self] state in
            self?.updateUIForSDKState(state)
        }
    }
    
    private func initializeSDK() {
        // Set global event listener for SDK and notification events
        YourGPTSDK.setEventListener(self)

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
        // Find chat button in tab bar
        guard let stackView = tabBarView?.subviews.first(where: { $0 is UIStackView }) as? UIStackView,
              stackView.arrangedSubviews.count > 3,
              let chatButton = stackView.arrangedSubviews[3] as? UIButton else { return }
        
        UIView.animate(withDuration: 0.3) {
            switch state.connectionState {
            case .connected:
                chatButton.isEnabled = true
                chatButton.alpha = 1.0
            case .connecting:
                chatButton.isEnabled = false
                chatButton.alpha = 0.6
            case .error, .disconnected:
                chatButton.isEnabled = false
                chatButton.alpha = 0.6
            }
        }
    }
    
    @objc private func openChatTapped() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        YourGPTWrapper.shared.openChatbot(from: self, delegate: self)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate

@available(iOS 13.0, *)
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subscriptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriptionCell", for: indexPath) as! SubscriptionCell
        cell.configure(with: subscriptions[indexPath.item])
        return cell
    }
}

// MARK: - Subscription Cell

@available(iOS 13.0, *)
class SubscriptionCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let cycleLabel = UILabel()
    private let nextBillingLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        // Clean container with subtle background
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(containerView)
        
        // Icon container - simple colored circle
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 20
        containerView.addSubview(iconContainer)
        
        // Icon setup
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        // Labels with system fonts
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        priceLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        priceLabel.textColor = .label
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cycleLabel.font = .preferredFont(forTextStyle: .caption1)
        cycleLabel.textColor = .secondaryLabel
        cycleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nextBillingLabel.font = .preferredFont(forTextStyle: .caption2)
        nextBillingLabel.textColor = .tertiaryLabel
        nextBillingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(cycleLabel)
        containerView.addSubview(nextBillingLabel)
        
        // Clean card styling
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = false
        
        // Subtle shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 6
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            nameLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            priceLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 20),
            priceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            cycleLabel.centerYAnchor.constraint(equalTo: priceLabel.lastBaselineAnchor),
            cycleLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 4),
            
            nextBillingLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 8),
            nextBillingLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nextBillingLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            nextBillingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with subscription: Subscription) {
        // Simple colored background for icon
        iconContainer.backgroundColor = subscription.color.withAlphaComponent(0.15)
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImageView.image = UIImage(systemName: subscription.icon, withConfiguration: config)
        iconImageView.tintColor = subscription.color
        
        nameLabel.text = subscription.name
        priceLabel.text = String(format: "$%.2f", subscription.price)
        cycleLabel.text = "/ \(subscription.cycle)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        nextBillingLabel.text = "Next: \(formatter.string(from: subscription.nextBilling))"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = .identity
        }
    }
}

// MARK: - YourGPTChatbotDelegate

@available(iOS 13.0, *)
extension ViewController: YourGPTChatbotDelegate {
    
    func chatbotDidReceiveMessage(_ message: [String : Any]) {
        print("📨 New message received: \(message)")
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

// MARK: - YourGPTEventListener (Global SDK Events)

@available(iOS 13.0, *)
extension ViewController: YourGPTEventListener {

    func onMessageReceived(_ message: [String: Any]) {
        print("[EventListener] Message received: \(message)")
    }

    func onChatOpened() {
        print("[EventListener] Chat opened")
    }

    func onChatClosed() {
        print("[EventListener] Chat closed")
    }

    func onError(_ error: String) {
        print("[EventListener] Error: \(error)")
    }

    func onLoadingStarted() {
        print("[EventListener] Loading started")
    }

    func onLoadingFinished() {
        print("[EventListener] Loading finished")
    }

    // Notification events (optional - using defaults for the rest)
    func onAPNsTokenReceived(_ token: String) {
        print("[EventListener] APNs token received: \(token)")
    }

    func onNotificationPermissionGranted() {
        print("[EventListener] Notification permission granted")
    }

    func onNotificationPermissionDenied() {
        print("[EventListener] Notification permission denied")
    }
}