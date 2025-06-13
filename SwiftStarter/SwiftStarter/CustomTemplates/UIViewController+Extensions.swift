import UIKit

extension UIViewController {
    fileprivate static func presentedController(_ controller: UIViewController) -> UIViewController {
        var topController = controller
        while let presented = topController.presentedViewController {
            topController = presented
        }
        return topController
    }
    
    class var topMostViewController: UIViewController? {
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let topController = window.rootViewController else {
                return nil
            }
            return presentedController(topController)
        } else {
            guard let keyWindow = UIApplication.shared.keyWindow,
                  let topController = keyWindow.rootViewController else {
                return nil
            }
            return presentedController(topController)
        }
    }
}
