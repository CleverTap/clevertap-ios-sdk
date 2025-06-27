import Foundation
import UIKit
import CleverTapSDK

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
    
    func onCloseClicked(context: CTTemplateContext) {
        // NOOP: Non-visual function without actions
    }
}
