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
        print("[ND] displayUnitsUpdated - \(displayUnits.count) unit(s) on this screen")
        displayUnits.forEach { $0.ndLogSlides() }
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
                let units = CleverTap.sharedInstance()?.getAllDisplayUnits() ?? []
                print("[ND] getAllDisplayUnits - \(units.count) unit(s) in the cache")
                units.forEach { $0.ndLogSlides() }
                self?.displayUnits = units
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
        let sheet = UIAlertController(title: "Native Display",
                                      message: getDisplayUnitText(displayUnit),
                                      preferredStyle: .actionSheet)

        // One row per slide; verify each event carries the slide's own wzrk_element_id/index and unit-level wzrk_id.
        for (index, content) in (displayUnit.contents ?? []).enumerated() {
            let label = content.title ?? "untitled"
            sheet.addAction(UIAlertAction(title: "Slide \(index): \(label)", style: .default) { [weak self] _ in
                self?.showElementEventOptions(for: displayUnit, contentIndex: index)
            })
        }

        sheet.addAction(UIAlertAction(title: "Log all slides to console", style: .default) { _ in
            displayUnit.ndLogSlides()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentSheet(sheet)
    }

    /// Clicked / viewed for one slide, with the exact dictionary handed to the
    func showElementEventOptions(for displayUnit: CleverTapDisplayUnit, contentIndex: Int) {
        guard let unitID = displayUnit.unitID else {
            print("[ND] unit has no unitID - cannot raise element events")
            return
        }
        let metaData = displayUnit.metaData(forContentAt: contentIndex)

        let sheet = UIAlertController(title: "Slide \(contentIndex)",
                                      message: ndMetaDataText(metaData),
                                      preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Element Clicked", style: .default) { _ in
            print("[ND] recordDisplayUnitElementClickedEvent unit=\(unitID) slide=\(contentIndex) props=\(metaData)")
            CleverTap.sharedInstance()?.recordDisplayUnitElementClickedEvent(forID: unitID,
                                                                            additionalProperties: metaData)
        })
        sheet.addAction(UIAlertAction(title: "Element Viewed", style: .default) { _ in
            print("[ND] recordDisplayUnitElementViewedEvent unit=\(unitID) slide=\(contentIndex) props=\(metaData)")
            CleverTap.sharedInstance()?.recordDisplayUnitElementViewedEvent(forID: unitID,
                                                                           additionalProperties: metaData)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentSheet(sheet)
    }

    /// Action sheets need an anchor on iPad or presenting them throws.
    func presentSheet(_ sheet: UIAlertController) {
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(sheet, animated: true)
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

// MARK: - Per-slide attribution logging (split of clicks)

func ndMetaDataText(_ metaData: [String: Any]) -> String {
    guard !metaData.isEmpty else {
        return "metaData empty - the event will carry unit-level wzrk_* only"
    }
    return metaData.keys.sorted().map { "\($0) = \(metaData[$0] ?? "")" }.joined(separator: "\n")
}

extension CleverTapDisplayUnit {

    /// Prints each slide's BE metadata merged with SDK-derived wzrk_action/data.
    /// Empty output means the slide has no metadata.
    func ndLogSlides() {
        let slides = contents ?? []
        print("[ND] unit=\(unitID ?? "nil") type=\(type ?? "nil") slides=\(slides.count)")
        for (index, content) in slides.enumerated() {
            print("[ND]   slide \(index) title=\(content.title ?? "-") actionUrl=\(content.actionUrl ?? "-")")
            let slideMetaData = self.metaData(forContentAt: index)
            if slideMetaData.isEmpty {
                print("[ND]   slide \(index) metaData EMPTY - no `metadata` object on this content item")
            } else {
                for key in slideMetaData.keys.sorted() {
                    print("[ND]   slide \(index) \(key)=\(slideMetaData[key] ?? "")")
                }
            }
        }
    }
}
