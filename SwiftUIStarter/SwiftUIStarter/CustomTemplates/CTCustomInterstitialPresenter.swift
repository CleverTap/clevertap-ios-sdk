import Foundation
import CleverTapSDK
import SwiftUI

class CTCustomInterstitialPresenter: CTTemplatePresenter {
    
    static let shared: CTCustomInterstitialPresenter = .init()
    
    weak var viewModel: CTCustomInterstitialViewModel?
    
    private var autoCloseTimer: Timer?
    
    private init() {}
    
    deinit {
        autoCloseTimer?.invalidate()
    }
    
    public func onPresent(context: CTTemplateContext) {
        let title = context.string(name: CustomInterstitialTemplate.ArgumentNames.title) ?? CustomInterstitialTemplate.DefaultValues.title
        let message = context.string(name: CustomInterstitialTemplate.ArgumentNames.message) ?? CustomInterstitialTemplate.DefaultValues.message
        let showCloseButton = context.boolean(name: CustomInterstitialTemplate.ArgumentNames.showCloseButton)
        let imageURL = context.file(name: CustomInterstitialTemplate.ArgumentNames.image)
        
        var image: UIImage?
        if let imageURL = imageURL {
            image = UIImage(contentsOfFile: imageURL)
        } else {
            image = UIImage(named: CustomInterstitialTemplate.DefaultValues.image)
        }
        
        let cancelAction = {
            self.close(context: context)
        }
        
        let confirmAction = {
            context.triggerAction(name: CustomInterstitialTemplate.ArgumentNames.openAction)
            self.close(context: context)
        }
        
        show(title: title, message: message, image: image, confirmAction: confirmAction, cancelAction: cancelAction, showCloseButton: showCloseButton)
        context.presented()
        
        let autoClose = context.double(name: CustomInterstitialTemplate.ArgumentNames.autoCloseAfter)
        if (autoClose > 0) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + autoClose) {
                self.close(context: context)
            }
        }
    }
    
    private func setupAutoClose(duration: Double, context: CTTemplateContext) {
        guard duration > 0 else { return }
        
        autoCloseTimer?.invalidate()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.close(context: context)
        }
    }
    
    public func show(title: String, message: String, image: UIImage?, confirmAction: (() -> Void)?, cancelAction: (() -> Void)?, showCloseButton: Bool = true) {
        if let vm = viewModel {
            vm.title = title
            vm.message = message
            vm.image = image
            vm.confirmAction = confirmAction
            vm.cancelAction = cancelAction
            vm.showCloseButton = showCloseButton
            
            vm.isVisible = true
        }
    }
    
    public func onCloseClicked(context: CTTemplateContext) {
        self.close(context: context)
    }
    
    public func close(context: CTTemplateContext) {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        
        viewModel?.isVisible = false
        context.dismissed()
    }
}

