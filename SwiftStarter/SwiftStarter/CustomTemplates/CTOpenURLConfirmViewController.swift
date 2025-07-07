import UIKit

class CTOpenURLConfirmViewController: UIViewController {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let messageLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let noButton = UIButton(type: .system)
    private let yesButton = UIButton(type: .system)
    
    var viewModel: CTOpenURLConfirmViewModel? {
        didSet {
            if view.superview != nil {
                setupBindings()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        // Container view
        containerView.backgroundColor = UIColor.groupTableViewBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.isAccessibilityElement = false
        containerView.accessibilityLabel = "URL confirmation dialog"
        
        // Title label
        titleLabel.text = "Open URL"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityLabel = "URL confirmation dialog title"
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isAccessibilityElement = false
        
        // Message label
        messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.isAccessibilityElement = true
        messageLabel.accessibilityLabel = "URL to open"
        messageLabel.accessibilityTraits = .staticText
        
        // Button stack view
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // No button
        noButton.setTitle("No", for: .normal)
        noButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        noButton.backgroundColor = UIColor.lightGray
        noButton.setTitleColor(.darkGray, for: .normal)
        noButton.layer.cornerRadius = 8
        noButton.layer.borderWidth = 1
        noButton.layer.borderColor = UIColor.gray.cgColor
        noButton.addTarget(self, action: #selector(noButtonTapped), for: .touchUpInside)
        
        noButton.isAccessibilityElement = true
        noButton.accessibilityLabel = "Don't open URL"
        noButton.accessibilityHint = "Cancels opening the URL"
        noButton.accessibilityTraits = .button
        
        // Yes button
        yesButton.setTitle("Yes", for: .normal)
        yesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        yesButton.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
        yesButton.setTitleColor(.white, for: .normal)
        yesButton.layer.cornerRadius = 8
        yesButton.addTarget(self, action: #selector(yesButtonTapped), for: .touchUpInside)
        
        yesButton.isAccessibilityElement = true
        yesButton.accessibilityLabel = "Open URL"
        yesButton.accessibilityHint = "Opens the URL in the default browser"
        yesButton.accessibilityTraits = .button
        
        // Add subviews
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        scrollView.addSubview(messageLabel)
        containerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(noButton)
        buttonStackView.addArrangedSubview(yesButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            containerView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.4),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -20),
            scrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 150),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            messageLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Button stack view
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func setupBindings() {
        guard let viewModel = viewModel else { return }
        
        messageLabel.text = viewModel.displayText
        
        messageLabel.accessibilityLabel = viewModel.displayText
        noButton.accessibilityLabel = "Do not open \(viewModel.displayURL)"
        yesButton.accessibilityLabel = "Open \(viewModel.displayURL)"
        
        setupAccessibilityElements()
    }
    
    private func setupAccessibilityElements() {
        let accessibilityElements = [titleLabel, messageLabel, noButton, yesButton]
        containerView.accessibilityElements = accessibilityElements
        
        UIAccessibility.post(notification: .screenChanged, argument: self.titleLabel)
    }
    
    @objc private func noButtonTapped() {
        viewModel?.executeCancelAction()
    }
    
    @objc private func yesButtonTapped() {
        viewModel?.executeConfirmAction()
    }
    
    func updateFromViewModel() {
        setupBindings()
    }
}
