import Foundation
import CleverTapSDK
import SwiftUI

struct InterstitialConfiguration {
    let title: String
    let message: String
    let image: UIImage?
    let showCloseButton: Bool
    let autoCloseAfter: Double
    
    public static var `default`: InterstitialConfiguration {
        .init(
            title: CustomInterstitialTemplate.DefaultValues.title,
            message: CustomInterstitialTemplate.DefaultValues.message,
            image: UIImage(named: CustomInterstitialTemplate.DefaultValues.image),
            showCloseButton: CustomInterstitialTemplate.DefaultValues.showCloseButton,
            autoCloseAfter: CustomInterstitialTemplate.DefaultValues.autoCloseAfter
        )
    }
}

class CTCustomInterstitialPresenter: CTTemplatePresenter {
    
    static let shared: CTCustomInterstitialPresenter = .init()
    
    weak var viewModel: CTCustomInterstitialViewModel?
    
    private var autoCloseTimer: Timer?
    
    private init() {}
    
    deinit {
        autoCloseTimer?.invalidate()
    }
    
    func onPresent(context: CTTemplateContext) {
        let configuration = extractConfiguration(from: context)
        
        let cancelAction: (() -> Void) = { [weak self] in
            self?.close(context: context)
        }
        
        let confirmAction = { [weak self] in
            context.triggerAction(name: CustomInterstitialTemplate.ArgumentNames.openAction)
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
    
    func show(
        configuration: InterstitialConfiguration,
        confirmAction: (() -> Void)?,
        cancelAction: (() -> Void)?
    ) {
        guard let viewModel = viewModel else {
            print("Warning: ViewModel not set for CustomInterstitialPresenter")
            return
        }
        
        viewModel.configure(with: configuration)
        viewModel.confirmAction = confirmAction
        viewModel.cancelAction = cancelAction
        viewModel.isVisible = true
    }
    
    private func extractConfiguration(from context: CTTemplateContext) -> InterstitialConfiguration {
        let config = InterstitialConfiguration.default
        
        let title = context.string(name: CustomInterstitialTemplate.ArgumentNames.title)
        let message = context.string(name: CustomInterstitialTemplate.ArgumentNames.message)
        let showCloseButton = context.boolean(name: CustomInterstitialTemplate.ArgumentNames.showCloseButton)
        let autoCloseAfter = context.double(name: CustomInterstitialTemplate.ArgumentNames.autoCloseAfter)
        
        let image: UIImage? = {
            if let imageURL = context.file(name: CustomInterstitialTemplate.ArgumentNames.image) {
                return UIImage(contentsOfFile: imageURL)
            } else {
                return config.image
            }
        }()
        
        return InterstitialConfiguration(
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
        
        viewModel?.isVisible = false
        context.dismissed()
    }
}

