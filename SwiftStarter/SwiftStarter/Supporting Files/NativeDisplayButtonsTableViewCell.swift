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
    var onShowDetails: (() -> Void)?
    var onShowDisplayUnit: (( _ displayUnit: CleverTapDisplayUnit) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func simpleEventAction(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("NativeDisplaySimple")
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
