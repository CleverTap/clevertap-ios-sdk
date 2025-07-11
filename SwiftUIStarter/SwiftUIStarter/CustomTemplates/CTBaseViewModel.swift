import SwiftUI

protocol CTBaseViewModel: ObservableObject {
    var isVisible: Bool { get set }
    var confirmAction: (() -> Void)? { get set }
    var cancelAction: (() -> Void)? { get set }
    
    func hide()
    func executeConfirmAction()
    func executeCancelAction()
}

extension CTBaseViewModel {
    func hide() {
        isVisible = false
    }
    
    func executeConfirmAction() {
        confirmAction?() ?? hide()
    }
    
    func executeCancelAction() {
        cancelAction?() ?? hide()
    }
}
