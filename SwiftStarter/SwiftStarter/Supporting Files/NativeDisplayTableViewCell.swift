//
//  NativeDisplayTableViewCell.swift
//  SwiftStarter
//
//  Copyright © 2025 CleverTap. All rights reserved.
//

import UIKit
import CleverTapSDK

class NativeDisplayTableViewCell: UITableViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var unitID: UILabel!
    var displayUnit: CleverTapDisplayUnit?
    var onShowDetails: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with displayUnit: CleverTapDisplayUnit?) {
        self.displayUnit = displayUnit
        unitID?.text = displayUnit?.unitID ?? "Unknown Unit"
    }
    
    @IBAction func clickAction(_ sender: Any) {
        if let unitID = displayUnit?.unitID {
            CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
        }
    }
    
    @IBAction func viewAction(_ sender: Any) {
        if let unitID = displayUnit?.unitID {
            CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
        }
    }
    
    @IBAction func showDetailsAction(_ sender: Any) {
        onShowDetails?()
    }
}
