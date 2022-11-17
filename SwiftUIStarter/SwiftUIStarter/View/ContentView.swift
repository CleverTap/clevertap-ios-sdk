import SwiftUI

struct ContentView: View {
    let events = CTEvent.getContactList()
    
    var body: some View {
        EventsScreen(events: events)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

