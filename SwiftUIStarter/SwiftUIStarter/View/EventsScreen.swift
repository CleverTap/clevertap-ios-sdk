//
//  EventsScreen.swift
//  SwiftUIStarter
//
//  Created by Kushagra Mishra on 17/11/22.
//
import SwiftUI

struct EventsScreen: View {
    let events: [CTEvent]
    
    var body: some View {
        
        NavigationView {
            VStack{
                Image("logo")
                    .scaledToFit()
                    .frame( height: 124)
                List(events) { event in
                    EventRow(event: event)
                }
            }
            
        }}
}

struct EventsScreen_Previews: PreviewProvider {
    static var previews: some View {
        EventsScreen(events: CTEvent.getContactList())
    }
}
