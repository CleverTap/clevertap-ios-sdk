//
//  InterfaceController.swift
//  SwiftWatchOS Extension
//
//  Created by Aditi Agrawal on 11/07/18.
//  Copyright © 2018 Aditi Agrawal. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CleverTapWatchOS

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    var session: WCSession?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        if (session != nil) {
            let cleverTap = CleverTapWatchOS(session: session!)
            cleverTap?.recordEvent("CustomWatchOSEvent", withProps: ["foo": "bar"])
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //MARK: WCSessionDelegate
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // no-op for demo purposes
    }
}
