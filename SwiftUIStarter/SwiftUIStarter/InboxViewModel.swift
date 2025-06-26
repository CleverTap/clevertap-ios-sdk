//
//  InboxViewModel.swift
//  SwiftUIStarter
//
//  Created by CleverTap on 17/06/25.
//

import CleverTapSDK
import Combine

struct InboxMessage: Identifiable {
    let id: String
    let title: String
    let message: String
    var isRead: Bool
}

class InboxViewModel: ObservableObject {
    @Published var messages: [InboxMessage] = []

    func loadInboxMessages() {
        guard let ctMessages = CleverTap.sharedInstance()?.getAllInboxMessages() else { return }
        self.messages = convertToInboxMessages(from: ctMessages)
    }

    private func convertToInboxMessages(from ctMessages: [CleverTapInboxMessage]) -> [InboxMessage] {
        return ctMessages.map { ctMsg in
            InboxMessage(
                id: ctMsg.messageId ?? "",
                title: ctMsg.content?.first?.title ?? "No Title",
                message: ctMsg.content?.first?.message ?? "No Message",
                isRead: ctMsg.isRead
            )
        }
    }
    
    func markAsRead(_ id: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].isRead = true
        }
    }

    func deleteMessage(_ id: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages.remove(at: index)
        }
    }
}
