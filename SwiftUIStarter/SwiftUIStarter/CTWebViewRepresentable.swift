import SwiftUI
import WebKit
import CleverTapSDK

struct CTWebViewRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = CTWebviewVC
    func makeUIViewController(context: Context) -> CTWebviewVC {
        let webViewVC = CTWebviewVC()
        return webViewVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}

class CTWebviewVC: UIViewController {
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        addWebview()
    }
    
    func addWebview() {
        let ctInterface: CleverTapJSInterface = CleverTapJSInterface(config: nil)
        self.webView = WKWebView (frame: self.view.frame)
        self.webView.configuration.userContentController.add(ctInterface, name: "clevertap")
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
}

