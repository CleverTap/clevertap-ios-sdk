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
    
    func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
        // you will get display units here
        print("displayUnitsUpdated")
        self.displayUnits = displayUnits
        updateNativeDisplaySection()
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
        switch DisplaySection(rawValue: indexPath.section)! {
        case .nativeDisplay:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NativeDisplayButtonsTableCell", for: indexPath) as! NativeDisplayButtonsTableViewCell
            cell.onShowDetails = { [weak self] in
                self?.displayUnits = CleverTap.sharedInstance()?.getAllDisplayUnits() ?? []
                self?.updateNativeDisplaySection()
            }
            
            cell.onShowDisplayUnit = { [weak self] displayUnit in
                self?.displayUnits = [displayUnit]
                self?.updateNativeDisplaySection()
            }
            return cell
            
        case .allDisplayUnits:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NativeDisplayTableViewCell", for: indexPath) as! NativeDisplayTableViewCell
            let displayUnit = displayUnits[indexPath.row]
            cell.configure(with: displayUnit)
            cell.onShowDetails = { [weak self] in
                self?.showNativeDisplayAlert(displayUnit)
            }
            return cell
        }
    }
    
    func updateNativeDisplaySection() {
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
            kvPairs = String(describing: (ce as! [String:String]))
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
