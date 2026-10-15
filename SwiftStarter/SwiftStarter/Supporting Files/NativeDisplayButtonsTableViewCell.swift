//
//  NativeDisplayTableViewCell.swift
//  SwiftStarter
//
//  Copyright © 2025 CleverTap. All rights reserved.
//

import UIKit
import CleverTapSDK

class NativeDisplayButtonsTableViewCell: UITableViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var displayUnitText: UITextField!
    @IBOutlet weak var eventNameText: UITextField!
    var onShowDetails: (() -> Void)?
    var onShowDisplayUnit: (( _ displayUnit: CleverTapDisplayUnit) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func simpleEventAction(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("NativeDisplaySimple")
    }

    // Records whatever event name is typed in the field. Each Native Display campaign is triggered
    // by its own event name. The name is set on the dashboard. It is not known to this app.
    @IBAction func recordEventAction(_ sender: Any) {
        let name = eventNameText.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else {
            print("[Native Display] enter an event name first")
            return
        }
        print("[Native Display] recording event \(name)")
        CleverTap.sharedInstance()?.recordEvent(name)
        eventNameText.resignFirstResponder()
    }
    
    // Charged has its own method. The Event name field above cannot send it. A Native Display
    // campaign triggered by Charged needs this button.
    @IBAction func recordChargedEventAction(_ sender: Any) {
        let chargeDetails: [String: Any] = [
            "Amount": 300,
            "Payment mode": "Credit Card",
            "Charged ID": 24052013
        ]
        let item: [String: Any] = [
            "Category": "books",
            "Book name": "The Millionaire next door",
            "Quantity": 1
        ]
        print("[Native Display] recording Charged event")
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: chargeDetails, andItems: [item])
    }

    @IBAction func carouselEventAction(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("NativeDisplayCarousel")
    }
    
    @IBAction func getUnitAction(_ sender: Any) {
        if let unitID = displayUnitText.text,
           let displayUnit = CleverTap.sharedInstance()?.getDisplayUnit(forID: unitID) {
            onShowDisplayUnit?(displayUnit)
        }
    }
    
    @IBAction func getAllDisplayUnitsAction(_ sender: Any) {
        onShowDetails?()
    }
}
