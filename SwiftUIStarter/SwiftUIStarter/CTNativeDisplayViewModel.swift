//
//  CTNativeDisplayViewModel.swift
//  SwiftUIStarter
//
//  Copyright © 2025 CleverTap. All rights reserved.
//

import SwiftUI
import CleverTapSDK

class CTNativeDisplayViewModel: NSObject, ObservableObject, CleverTapDisplayUnitDelegate {
    @Published var displayUnits: [CleverTapDisplayUnit] = []
    
    enum DisplayType {
        case simple
        case carousel
    }
    
    func setupCleverTap() {
        CleverTap.sharedInstance()?.setDisplayUnitDelegate(self)
        getAllDisplayUnits()
    }
    
    func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
        NSLog("displayUnitsUpdated: \(displayUnits.count) units")
        DispatchQueue.main.async {
            self.displayUnits = displayUnits
        }
    }
    
    func handleDisplayType(_ type: DisplayType) {
        let eventName = type == .simple ? "NativeDisplaySimple" : "NativeDisplayCarousel"
        CleverTap.sharedInstance()?.recordEvent(eventName)
        NSLog("Recorded event: \(eventName)")
    }
    
    func getDisplayUnit(withID id: String) {
        NSLog("Getting display unit with ID: \(id)")
        if let displayUnit = CleverTap.sharedInstance()?.getDisplayUnit(forID: id) {
            displayUnits = [displayUnit]
        }
    }
    
    func getAllDisplayUnits() {
        displayUnits = CleverTap.sharedInstance()?.getAllDisplayUnits() ?? []
        NSLog("Retrieved \(displayUnits.count) display units")
    }
    
    func handleClick(_ displayUnit: CleverTapDisplayUnit) {
        NSLog("Display unit clicked: \(displayUnit.unitID ?? "unknown")")
        if let unitID = displayUnit.unitID {
            CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
        }
    }
    
    func handleView(_ displayUnit: CleverTapDisplayUnit) {
        NSLog("Display unit viewed: \(displayUnit.unitID ?? "unknown")")
        if let unitID = displayUnit.unitID {
            CleverTap.sharedInstance()?.recordDisplayUnitViewedEvent(forID: unitID)
        }
    }
}
