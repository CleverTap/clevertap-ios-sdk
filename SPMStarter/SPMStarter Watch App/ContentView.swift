//
//  ContentView.swift
//  SPMStarter Watch App
//
//  Created by Sonal Kachare on 23/07/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Record event") {
                sessionManager.recordEvent()
            }
        }
        .padding()
        .onAppear {
            sessionManager.activateSession()
        }
    }
}

#Preview {
    ContentView()
}
