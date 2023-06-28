//
//  CTWebviewVC.swift
//  SPMStarter
//
//  Created by Aishwarya Nanna on 30/06/22.
//  Copyright © 2022 CleverTap. All rights reserved.
//

import UIKit
import WebKit
import CleverTapSDK

class CTWebviewVC: UIViewController {
   
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        addWebview()

        // Do any additional setup after loading the view.
    }
    
    func addWebview() {
        let ctInterface: CleverTapJSInterface = CleverTapJSInterface(config: nil)
        self.webView = WKWebView (frame: self.view.frame)
        // Ensure using a unique identifier for addScriptMessageHandler to avoid interfering with other apps leading to namespace issues.
        // We recommend using your app's package name, For example: com.clevertap.SPMStarter if your app package name is com.clevertap.SPMStarter.
        self.webView.configuration.userContentController.add(ctInterface, name: "com_clevertap_SPMStarter")
        self.webView.loadHTMLString(self.htmlStringFromFile(with: "sampleHTMLCode"), baseURL: nil)
        self.view.addSubview(self.webView)
    }
    
    private func htmlStringFromFile(with name: String) -> String {
        let path = Bundle.main.path(forResource: name, ofType: "html")
        if let result = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8) {
            return result
        }
        return ""
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
