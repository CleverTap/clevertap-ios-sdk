import Foundation
import CleverTapSDK
import SwiftUI

class CTCustomInterstitialPresenter: CTTemplatePresenter {
    
    static let shared: CTCustomInterstitialPresenter = .init()
    
    weak var interstitialViewModel: CTCustomInterstitialViewModel?
    
    public func onPresent(context: CTTemplateContext) {
        let title = context.string(name: "Title") ?? CustomInterstitialTemplate.Constants.title
        let message = context.string(name: "Message") ?? CustomInterstitialTemplate.Constants.message
        let imageURL = context.file(name: "Image")
        
        var image: UIImage?
        if let imageURL = imageURL {
            image = UIImage(contentsOfFile: imageURL)
        } else {
            image = UIImage(named: CustomInterstitialTemplate.Constants.image)
        }
        
        let cancelAction = {
            print("Close")
            self.close(context: context)
        }
        
        let confirmAction = {
            print("Confirm")
            context.triggerAction(name: "Open action")
            self.close(context: context)
        }
        
        showInterstitial(title: title, message: message, image: image, confirmAction: confirmAction, cancelAction: cancelAction)
        context.presented()
    }
    
    public func showInterstitial(title: String, message: String, image: UIImage?, confirmAction: (() -> Void)?, cancelAction: (() -> Void)?) {
        if let vm = interstitialViewModel {
            vm.title = title
            vm.message = message
            vm.image = image
            vm.confirmAction = confirmAction
            vm.cancelAction = cancelAction
            
            vm.isVisible = true
            print("Presented")
        }
    }
    
    public func onCloseClicked(context: CTTemplateContext) {
        self.close(context: context)
    }
    
    public func close(context: CTTemplateContext) {
        context.dismissed()
        interstitialViewModel?.isVisible = false
    }
}

