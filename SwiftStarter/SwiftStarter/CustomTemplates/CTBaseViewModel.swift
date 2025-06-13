protocol CTBaseViewModel {
    var confirmAction: (() -> Void)? { get set }
    var cancelAction: (() -> Void)? { get set }
    
    func executeConfirmAction()
    func executeCancelAction()
}

extension CTBaseViewModel {
    func executeConfirmAction() {
        confirmAction?()
    }
    
    func executeCancelAction() {
        cancelAction?()
    }
}
