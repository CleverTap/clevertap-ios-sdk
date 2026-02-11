//
//  CleverTapTrackedViewController.swift
//  CleverTapSDK
//

import UIKit

@objc(CleverTapTrackedViewController)
@objcMembers
open class CleverTapTrackedViewController: UIViewController {
    public var screenName: String?

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let screenName = screenName {
            CleverTap.sharedInstance()?.recordScreenView(screenName)
        }
    }
}
