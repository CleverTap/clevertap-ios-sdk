import Foundation
import CleverTapSDK
import SwiftUI

class CTOpenURLConfirmPresenter: CTTemplatePresenter {
    
    static let shared: CTOpenURLConfirmPresenter = .init()
    
    weak var viewModel: CTOpenURLConfirmViewModel?
    
    public func onPresent(context: CTTemplateContext) {
        let stringUrl = context.string(name: OpenURLConfirmTemplate.ArgumentNames.url)

        if let stringUrl = stringUrl, let url = URL(string: stringUrl) {
            let cancelAction = {
                self.close(context: context)
            }
            
            let confirmAction = {
                UIApplication.shared.open(url)
                self.close(context: context)
            }
            
            show(url: stringUrl, confirmAction: confirmAction, cancelAction: cancelAction)
            context.presented()
        } else {
            self.close(context: context)
        }
    }
    
    public func show(url: String, confirmAction: (() -> Void)?, cancelAction: (() -> Void)?) {
        if let vm = viewModel {
            vm.url = url
            vm.confirmAction = confirmAction
            vm.cancelAction = cancelAction
            
            vm.isVisible = true
        }
    }
    
    public func onCloseClicked(context: CTTemplateContext) {
        self.close(context: context)
    }
    
    public func close(context: CTTemplateContext) {
        context.dismissed()
        viewModel?.isVisible = false
    }
}

