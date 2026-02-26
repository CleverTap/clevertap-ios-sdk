//
//  ViewController.swift
//  SwiftTvOS
//
//  Created by Aditi Agrawal on 09/07/18.
//  Copyright © 2018 Aditi Agrawal. All rights reserved.
//

import UIKit
import CleverTapSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add a button to open the App Inbox
        let button = UIButton(type: .system)
        button.setTitle("Open App Inbox", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 38, weight: .medium)
        button.addTarget(self, action: #selector(openInbox), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 400),
            button.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Initialize inbox and log message counts
        CleverTap.sharedInstance()?.initializeInbox(callback: { [weak self] success in
            guard let self = self else { return }
            if success {
                let total = CleverTap.sharedInstance()?.getInboxMessageCount() ?? 0
                let unread = CleverTap.sharedInstance()?.getInboxMessageUnreadCount() ?? 0
                print("[CT] Inbox initialized — total: \(total), unread: \(unread)")
            } else {
                print("[CT] Inbox initialization failed")
            }
        })
    }

    @objc func openInbox() {
        let config = CleverTapInboxStyleConfig()
        config.title = "App Inbox"
        config.navigationBarTintColor = .darkGray
        config.navigationTintColor = .white

        guard let inboxVC = CleverTap.sharedInstance()?.newInboxViewController(
            with: config,
            andDelegate: nil
        ) else {
            print("[CT] Failed to create inbox view controller")
            return
        }

        let nav = UINavigationController(rootViewController: inboxVC)
        present(nav, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

