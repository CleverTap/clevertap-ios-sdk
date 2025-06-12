import UIKit

class CustomInterstitialViewController: UIViewController {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    private let messageLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let closeButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    
    private var scrollViewTopToImageConstraint: NSLayoutConstraint!
    private var scrollViewTopToTitleConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    
    var viewModel: CTCustomInterstitialViewModel? {
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
        containerView.accessibilityLabel = "Custom notification dialog"
        
        // Title label
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityLabel = "Notification title"
        
        // Image view
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Notification image"
        imageView.accessibilityTraits = .image
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isAccessibilityElement = false
        
        // Message label
        messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.isAccessibilityElement = true
        messageLabel.accessibilityLabel = "Notification message"
        messageLabel.accessibilityTraits = .staticText
        
        // Button stack view
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Close button
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        closeButton.backgroundColor = UIColor.lightGray
        closeButton.setTitleColor(.darkGray, for: .normal)
        closeButton.layer.cornerRadius = 8
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.gray.cgColor
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        closeButton.isAccessibilityElement = true
        closeButton.accessibilityLabel = "Close notification"
        closeButton.accessibilityHint = "Dismisses the notification without taking action"
        closeButton.accessibilityTraits = .button
        
        // Confirm button
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        confirmButton.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0) // systemBlue equivalent
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        confirmButton.isAccessibilityElement = true
        confirmButton.accessibilityLabel = "Confirm action"
        confirmButton.accessibilityHint = "Confirms and performs the notification action"
        confirmButton.accessibilityTraits = .button
        
        // Add subviews
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(imageView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(messageLabel)
        containerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(closeButton)
        buttonStackView.addArrangedSubview(confirmButton)
    }
    
    private func setupConstraints() {
        scrollViewTopToImageConstraint = scrollView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20)
        scrollViewTopToTitleConstraint = scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 120)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            // Ensure it doesn't get too small on smaller screens
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30),
            
            // Image view
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: 0.6),
            imageHeightConstraint, // Will be activated/deactivated based on image presence
            
            // Button stack view
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 48),
            
            // Scroll view
            scrollViewTopToImageConstraint,
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -20),

            // Message label
            messageLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            messageLabel.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -8),
            messageLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16)
        ])
    }
    
    private func setupBindings() {
        guard let viewModel = viewModel else { return }
        
        titleLabel.text = viewModel.title
        messageLabel.text = viewModel.message
        imageView.image = viewModel.image
        closeButton.isHidden = !viewModel.showCloseButton
        
        titleLabel.accessibilityLabel = "Notification title: \(viewModel.title)"
        messageLabel.accessibilityLabel = "Notification message: \(viewModel.message)"
        
        buttonStackView.distribution = viewModel.showCloseButton ? .fillEqually : .fill
        
        // Handle image visibility and constraint switching
        if viewModel.image == nil {
            imageView.isHidden = true
            imageHeightConstraint.constant = 0
            imageHeightConstraint.isActive = true

            scrollViewTopToImageConstraint.isActive = false
            scrollViewTopToTitleConstraint.isActive = true
        } else {
            imageView.isHidden = false
            imageHeightConstraint.constant = 120
            imageHeightConstraint.isActive = true
            imageView.accessibilityLabel = "Notification image"


            scrollViewTopToTitleConstraint.isActive = false
            scrollViewTopToImageConstraint.isActive = true
        }
        
        setupAccessibilityElements()
        
        // Force layout update
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func setupAccessibilityElements() {
        var accessibilityElements: [UIView] = []
        
        // Add elements in reading order
        accessibilityElements.append(titleLabel)
        
        if !imageView.isHidden {
            accessibilityElements.append(imageView)
        }
        
        accessibilityElements.append(messageLabel)
        
        if !closeButton.isHidden {
            accessibilityElements.append(closeButton)
        }
        
        accessibilityElements.append(confirmButton)
        
        // Set accessibility elements for the container
        containerView.accessibilityElements = accessibilityElements
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .screenChanged, argument: self.titleLabel)
        }
    }
    
    @objc private func closeButtonTapped() {
        viewModel?.executeCancelAction()
    }
    
    @objc private func confirmButtonTapped() {
        viewModel?.executeConfirmAction()
    }
    
    func updateFromViewModel() {
        setupBindings()
    }
}
