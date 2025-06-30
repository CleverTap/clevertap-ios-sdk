import SwiftUI
import CleverTapSDK

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @State private var showInboxModal = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    showInboxModal = true
                }) {
                    Text("Show App Inbox")
                        .foregroundColor(.blue)
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
            .sheet(isPresented: $showInboxModal) {
                CTAppInboxRepresentable()
                    .recordScreenView(screenName: "CT App Inbox")
            }
            .onAppear {
                viewModel.loadInboxMessages()
            }
            .navigationBarTitle("Inbox", displayMode: .inline)
        }
    }
}
