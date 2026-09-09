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
        // ti is the campaign id. Frequency caps are counted per ti. unitID is the wzrk_id, which is
        // a different value. The label shows both so a row can be matched to a dashboard campaign.
        let ti = displayUnit?.json?["ti"] as? String ?? "no-ti"
        unitID?.text = "ti=\(ti)  \(displayUnit?.unitID ?? "Unknown Unit")"
    }
    
    @IBAction func clickAction(_ sender: Any) {
        if let unitID = displayUnit?.unitID {
            CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
        }
    }
    
    // The SDK does not draw display units. This call is the only way it learns that one was shown.
    // Frequency caps need it. A cap on views is never reached while this call is missing.
    @IBAction func viewAction(_ sender: Any) {
        guard let unitID = displayUnit?.unitID else { return }
        let ti = displayUnit?.json?["ti"] as? String ?? "no-ti"
        print("[Native Display] reporting view ti=\(ti) unitID=\(unitID)")
        CleverTap.sharedInstance()?.recordDisplayUnitViewedEvent(forID: unitID)
    }
    
    @IBAction func showDetailsAction(_ sender: Any) {
        onShowDetails?()
    }
}
