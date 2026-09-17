//
//  NativeDisplayViewController.swift
//  SwiftStarter
//
//  Copyright © 2025 CleverTap. All rights reserved.
//

import UIKit
import CleverTapSDK

class NativeDisplayViewController: UITableViewController, CleverTapDisplayUnitDelegate {
    
    var displayUnits: [CleverTapDisplayUnit] = []
    enum DisplaySection: Int, CaseIterable {
        case nativeDisplay
        case allDisplayUnits
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nativeDisplayNib = UINib(nibName: "NativeDisplayTableViewCell", bundle: nil)
        tableView.register(nativeDisplayNib, forCellReuseIdentifier: "NativeDisplayTableViewCell")
        
        let buttonsNib = UINib(nibName: "NativeDisplayButtonsTableViewCell", bundle: nil)
        tableView.register(buttonsNib, forCellReuseIdentifier: "NativeDisplayButtonsTableCell")
        
        CleverTap.sharedInstance()?.setDisplayUnitDelegate(self)
    }
    
    // Called after a server response carries display unit content. The array is the whole cache,
    // not only the units that just arrived. Units held back by their frequency caps never appear here.
    func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
        print("[Native Display] displayUnitsUpdated, cache now holds \(displayUnits.count) unit(s)")
        for unit in displayUnits {
            let ti = NativeDisplayTableViewCell.campaignId(of: unit)
            print("[Native Display] displayUnitsUpdated ti=\(ti) unitID=\(unit.unitID ?? "nil") title=\(unit.contents?.first?.title ?? "nil")")
        }
        self.displayUnits = displayUnits
        updateAllDisplayUnitsSection()
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return DisplaySection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch DisplaySection(rawValue: section)! {
        case .allDisplayUnits:
            return displayUnits.count  // If needed, you can show fetched display units here
        case .nativeDisplay:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch DisplaySection(rawValue: section)! {
        case .allDisplayUnits:
            return "ALL DISPLAY UNITS"
        case .nativeDisplay:
            return "NATIVE DISPLAY\nNOTE: CLICKING ON BELOW BUTTON WILL RECORD EVENT WITH SAME NAME."
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let displaySection = DisplaySection(rawValue: indexPath.section)
        
        switch displaySection {
        case .nativeDisplay:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NativeDisplayButtonsTableCell", for: indexPath) as? NativeDisplayButtonsTableViewCell else {
                fatalError("Failed to dequeue NativeDisplayButtonsTableViewCell")
            }
            
            cell.onShowDetails = { [weak self] in
                self?.displayUnits = CleverTap.sharedInstance()?.getAllDisplayUnits() ?? []
                self?.updateAllDisplayUnitsSection()
            }
            
            cell.onShowDisplayUnit = { [weak self] displayUnit in
                self?.displayUnits = [displayUnit]
                self?.updateAllDisplayUnitsSection()
            }
            return cell
            
        case .allDisplayUnits:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NativeDisplayTableViewCell", for: indexPath) as? NativeDisplayTableViewCell else {
                fatalError("Failed to dequeue NativeDisplayTableViewCell")
            }
            let displayUnit = displayUnits[indexPath.row]
            cell.configure(with: displayUnit)
            cell.onShowDetails = { [weak self] in
                self?.showNativeDisplayAlert(displayUnit)
            }
            return cell
            
        default:
            //Adds to avoid force unwrapping
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NativeDisplayButtonsTableCell", for: indexPath) as? NativeDisplayButtonsTableViewCell else {
                fatalError("Failed to dequeue NativeDisplayButtonsTableViewCell")
            }
            return cell
        }
    }
    
    func updateAllDisplayUnitsSection() {
        DispatchQueue.main.async {
            let sectionIndex = DisplaySection.allDisplayUnits.rawValue
            let indexSet = IndexSet(integer: sectionIndex)
            
            // Reload only the native display section with animation
            self.tableView.reloadSections(indexSet, with: .fade)
        }
    }
    
    func showNativeDisplayAlert(_ displayUnit: CleverTapDisplayUnit) {
        let fullMessage = getDisplayUnitText(displayUnit)
        
        let alert = UIAlertController(title: "Native Display", message: fullMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDisplayUnitText(_ displayUnit: CleverTapDisplayUnit) -> String {
        guard let contentArray = displayUnit.contents,
              let content = contentArray.first else {
            return ""
        }
        var kvPairs = ""
        if let ce = displayUnit.customExtras{
            kvPairs = String(describing: (ce as? [String:String] ?? [:]))
        }
        
        let title = content.title ?? "No Title"
        let message = content.message ?? "No Message"
        let imageURL = content.mediaUrl ?? "No Image URL"
        let link = content.actionUrl ?? ""
        
        let fullMessage = """
        Title: \(title)
        Message: \(message)
        CustomKeyValue: \(kvPairs)
        URL: \(link)
        Image: \(imageURL)
        """
        return fullMessage
    }
}
