import Foundation
import CleverTapSDK
import UIKit

struct CTInterstitialConfiguration {
    let title: String
    let message: String
    let image: UIImage?
    let showCloseButton: Bool
    let autoCloseAfter: Double
    
    public static var `default`: CTInterstitialConfiguration {
        .init(
            title: CTCustomInterstitialTemplate.DefaultValues.title,
            message: CTCustomInterstitialTemplate.DefaultValues.message,
            image: UIImage(named: CTCustomInterstitialTemplate.DefaultValues.image),
            showCloseButton: CTCustomInterstitialTemplate.DefaultValues.showCloseButton,
            autoCloseAfter: CTCustomInterstitialTemplate.DefaultValues.autoCloseAfter
        )
    }
}

class CTCustomInterstitialPresenter: CTTemplatePresenter {
    var viewController: UIViewController?
    private var autoCloseTimer: Timer?
    
    deinit {
        autoCloseTimer?.invalidate()
    }
    
    func onPresent(context: CTTemplateContext) {
        let configuration = extractConfiguration(from: context)
        
        let cancelAction: (() -> Void) = { [weak self] in
            self?.close(context: context)
        }
        
        let confirmAction = { [weak self] in
            context.triggerAction(name: CTCustomInterstitialTemplate.ArgumentNames.openAction)
            self?.close(context: context)
        }
        
        show(
            configuration: configuration,
            confirmAction: confirmAction,
            cancelAction: cancelAction
        )
        
        context.presented()
        setupAutoClose(duration: configuration.autoCloseAfter, context: context)
    }
    
    private func extractConfiguration(from context: CTTemplateContext) -> CTInterstitialConfiguration {
        let config = CTInterstitialConfiguration.default
        
        let title = context.string(name: CTCustomInterstitialTemplate.ArgumentNames.title)
        let message = context.string(name: CTCustomInterstitialTemplate.ArgumentNames.message)
        let showCloseButton = context.boolean(name: CTCustomInterstitialTemplate.ArgumentNames.showCloseButton)
        let autoCloseAfter = context.double(name: CTCustomInterstitialTemplate.ArgumentNames.autoCloseAfter)
        
        let image: UIImage? = {
            if let imageURL = context.file(name: CTCustomInterstitialTemplate.ArgumentNames.image) {
                return UIImage(contentsOfFile: imageURL)
            } else {
                return config.image
            }
        }()
        
        return CTInterstitialConfiguration(
            title: title ?? config.title,
            message: message ?? config.message,
            image: image,
            showCloseButton: showCloseButton,
            autoCloseAfter: autoCloseAfter
        )
    }
    
    private func setupAutoClose(duration: Double, context: CTTemplateContext) {
        guard duration > 0 else { return }
        
        autoCloseTimer?.invalidate()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.close(context: context)
        }
    }
    
    func onCloseClicked(context: CTTemplateContext) {
        self.close(context: context)
    }
    
    func close(context: CTTemplateContext) {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        
        if let viewController = viewController {
            viewController.dismiss(animated: true) {
                context.dismissed()
            }
        } else {
            context.dismissed()
        }
    }
    
    func show(
        configuration: CTInterstitialConfiguration,
        confirmAction: (() -> Void)?,
        cancelAction: (() -> Void)?
    ) {
        guard let topViewController = UIViewController.topMostViewController else {
            print("\(self): Cannot resolve the top UIViewController")
            cancelAction?()
            return
        }
        
        let viewModel = CTCustomInterstitialViewModel()
        viewModel.configure(with: configuration)
        viewModel.confirmAction = confirmAction
        viewModel.cancelAction = cancelAction
        
        let interstitialVC = CustomInterstitialViewController()
        interstitialVC.viewModel = viewModel
        interstitialVC.modalPresentationStyle = .overFullScreen
        interstitialVC.modalTransitionStyle = .crossDissolve
        
        viewController = interstitialVC
        topViewController.present(interstitialVC, animated: true)
    }
}

