import Foundation

var eventList = [  "Record User Profile",
                               "Record User Profile with Properties",
                                "Record User Event with Properties",
                                "Record User Charged Event",
                                "Record User Event to an Additional Instance",
                                "Show App Inbox",
                                "Analytics in a WebView",
                                "Increment User Profile Property",
                                "Decrement User Profile Property",
                                "Activate Custom domain proxy"
                                     ]

struct CTEvent: Identifiable {
    var id: Int
    let name: String
//    let isNavigatable: Bool

}

extension CTEvent {
    static func getContactList() -> [CTEvent] {
        
        var events: [CTEvent] = []
        
        
        let iterationCount = eventList.count
        
        for index in 0..<iterationCount {
            let event = CTEvent(
                id: index,
                name: eventList[index]
//                isNavigatable: <#T##Bool#>
            )
            
            events.append(event)
        }
        
        return events
    }
}

