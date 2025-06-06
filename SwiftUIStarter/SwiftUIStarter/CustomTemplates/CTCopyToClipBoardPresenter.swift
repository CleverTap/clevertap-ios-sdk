import Foundation
import CleverTapSDK
import SwiftUI

class CTCopyToClipBoardPresenter: CTTemplatePresenter {
    
    public func onPresent(context: CTTemplateContext) {
        let text = context.string(name: CopyToClipboardTemplate.ArgumentNames.text)
        if let text = text {
            UIPasteboard.general.string = text
        }
    }
    
    func onCloseClicked(context: CTTemplateContext) {
    }
}

