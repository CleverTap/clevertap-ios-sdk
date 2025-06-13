import UIKit

extension UIViewController {
    fileprivate static func topViewControllerInHierarchy(_ controller: UIViewController) -> UIViewController {
        if let navController = controller as? UINavigationController {
            if let visibleController = navController.visibleViewController {
                return topViewControllerInHierarchy(visibleController)
            }
            return controller
        }
        
        if let tabController = controller as? UITabBarController {
            if let selectedController = tabController.selectedViewController {
                return topViewControllerInHierarchy(selectedController)
            }
            return controller
        }
        
        if let splitController = controller as? UISplitViewController {
            if let detailController = splitController.viewControllers.last {
                return topViewControllerInHierarchy(detailController)
            }
            return controller
        }
        
        if let pageController = controller as? UIPageViewController {
            if let currentController = pageController.viewControllers?.first {
                return topViewControllerInHierarchy(currentController)
            }
            return controller
        }
        
        return controller
    }
    
    fileprivate static func presentedController(_ controller: UIViewController) -> UIViewController {
        var topController = topViewControllerInHierarchy(controller)
        
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
