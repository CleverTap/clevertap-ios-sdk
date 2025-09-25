//
//  SessionManager.swift
//  SPMStarter
//
//  Copyright © 2025 CleverTap. All rights reserved.
//


import Foundation
import WatchConnectivity
import CleverTapWatchOS

class SessionManager: NSObject, ObservableObject, WCSessionDelegate {
    private var cleverTapWatchOS: CleverTapWatchOS?
    private var session: WCSession?
    
    override init() {
        super.init()
    }
    
    func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            self.session = session
        }
    }
    
    func recordEvent() {
        guard let cleverTapWatchOS = cleverTapWatchOS else {
            print("CleverTap not initialized yet")
            return
        }
        cleverTapWatchOS.recordEvent("CustomWatchOSEvent", withProps: ["foo": "bar"])
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("WCSession activated")
            self.cleverTapWatchOS = CleverTapWatchOS(session: session)
        } else {
            print("WCSession failed to activate: \(error?.localizedDescription ?? "unknown error")")
        }
    }
}
