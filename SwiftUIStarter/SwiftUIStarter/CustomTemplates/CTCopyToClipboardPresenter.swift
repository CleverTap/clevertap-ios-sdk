import Foundation
import CleverTapSDK
import UIKit

class CTCopyToClipboardPresenter: CTTemplatePresenter {
    
    public func onPresent(context: CTTemplateContext) {
        guard let text = context.string(name: CTCopyToClipboardTemplate.ArgumentNames.text),
                !text.isEmpty else {
            print("\(self): Text argument missing")
            return
        }
        
        UIPasteboard.general.string = text
        context.presented()
        context.dismissed()
    }
    
    public func onCloseClicked(context: CTTemplateContext) {
        // NOOP: Non-visual function without actions
    }
}

