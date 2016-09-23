
import WatchKit
import WatchConnectivity

public class CleverTapWatchOS: NSObject {
    
    private var session: WCSession
    
    public init(session: WCSession) {
        self.session = session
        super.init()
    }
    
    private func sendMessage(type: String, content: [String: Any]) {
        if !self.session.isReachable {
            return
        }
        var message = content
        message["clevertap_type"] = type
        self.session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    public func record(event: String, withProps props: [String: String]? = nil) {
        var content: [String: Any] = ["event": event]
        if let _props = props {
            content["props"] = _props
        }
        sendMessage(type: "recordEventWithProps", content: content)
    }
}
