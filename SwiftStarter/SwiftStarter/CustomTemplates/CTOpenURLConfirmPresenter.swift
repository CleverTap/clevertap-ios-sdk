import Foundation
import CleverTapSDK
import UIKit

class CTOpenURLConfirmPresenter: CTTemplatePresenter {
    
    static let shared: CTOpenURLConfirmPresenter = .init()
    
    var viewController: UIViewController?
    
    private init() {}
    
    func onPresent(context: CTTemplateContext) {
        guard let urlString = context.string(name: CTOpenURLConfirmTemplate.ArgumentNames.url),
              !urlString.isEmpty else {
            print("Error: URL is missing or empty in OpenURLConfirmPresenter")
            self.close(context: context)
            return
        }
        
        guard URL(string: urlString) != nil else {
            print("Error: Invalid URL format: \(urlString)")
            self.close(context: context)
            return
        }
        
        let cancelAction: (() -> Void) = { [weak self] in
            self?.close(context: context)
        }
        
        let confirmAction: (() -> Void) = { [weak self] in
            self?.openURL(urlString)
            self?.close(context: context)
        }
        
        show(url: urlString, confirmAction: confirmAction, cancelAction: cancelAction)
        context.presented()
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Error: Failed to create URL from string: \(urlString)")
            return
        }
        
        guard UIApplication.shared.canOpenURL(url) else {
            print("Error: Cannot open URL: \(urlString)")
            return
        }
        
        UIApplication.shared.open(url) { success in
            if !success {
                print("Error: Failed to open URL: \(urlString)")
            }
        }
    }
        
    func show(url: String, confirmAction: (() -> Void)?, cancelAction: (() -> Void)?) {
        let viewModel = CTOpenURLConfirmViewModel()
        viewModel.url = url
        viewModel.confirmAction = confirmAction
        viewModel.cancelAction = cancelAction
        
        let openURLVC = CTOpenURLConfirmViewController()
        openURLVC.viewModel = viewModel
        openURLVC.modalPresentationStyle = .overFullScreen
        openURLVC.modalTransitionStyle = .crossDissolve
        viewController = openURLVC
        CTCustomInterstitialPresenter.topViewController?.present(openURLVC, animated: true)
    }
    
    func onCloseClicked(context: CTTemplateContext) {
        self.close(context: context)
    }
    
    func close(context: CTTemplateContext) {
        if let viewController = viewController {
            viewController.dismiss(animated: true) {
                context.dismissed()
            }
        }
    }
    
    class var topViewController: UIViewController? {
        var topController = UIApplication.shared.keyWindow!.rootViewController
        while (topController?.presentedViewController != nil) {
            topController = topController?.presentedViewController;
        }
        return topController
    }
}

