import SwiftUI
import CleverTapSDK

struct InboxMessage: Identifiable {
    let id: String
    let title: String
    let message: String
    var isRead: Bool
}

struct InboxView: View {
    @State private var messages: [InboxMessage] = []
    @StateObject private var viewModel = InboxViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: CTAppInboxRepresentable()) {
                    Text("Show App Inbox")
                }
                List {
                    ForEach(viewModel.messages) { msg in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title: \(msg.title)")
                            Text("Message: \(msg.message)")
                            Text("Read: \(msg.isRead.description)")
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    print("Click tapped for message: \(msg.id)")
                                     CleverTap.sharedInstance()?.recordInboxNotificationClickedEvent(forID: msg.id)
                                }) {
                                    Text("Click")
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    print("View tapped for message: \(msg.id)")
                                     CleverTap.sharedInstance()?.recordInboxNotificationViewedEvent(forID: msg.id)
                                }) {
                                    Text("View")
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    print("Mark Read tapped for message: \(msg.id)")
                                    CleverTap.sharedInstance()?.markReadInboxMessage(forID: msg.id)
                                    viewModel.markAsRead(msg.id)
                                }) {
                                    Text("Mark Read")
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    print("Delete tapped for message: \(msg.id)")
                                    CleverTap.sharedInstance()?.deleteInboxMessage(forID: msg.id)
                                    viewModel.deleteMessage(msg.id)
                                }) {
                                    Text("Delete")
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .onAppear {
                viewModel.loadInboxMessages()
            }
            .navigationBarTitle("Inbox", displayMode: .inline)
        }
    }
}
