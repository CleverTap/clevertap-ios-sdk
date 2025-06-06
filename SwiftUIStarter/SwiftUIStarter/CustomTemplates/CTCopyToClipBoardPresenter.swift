import Foundation
import CleverTapSDK
import SwiftUI

class CTCopyToClipBoardPresenter: CTTemplatePresenter {
    
    public func onPresent(context: CTTemplateContext) {
        let text = context.string(name: "Text")
        if let text = text {
            UIPasteboard.general.string = text
        }
    }
    
    func onCloseClicked(context: CTTemplateContext) {
    }
}

