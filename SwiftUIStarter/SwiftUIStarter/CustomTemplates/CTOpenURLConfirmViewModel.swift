import Foundation
import SwiftUI

final class CTOpenURLConfirmViewModel: CTBaseViewModel {
    @Published var isVisible = false
    @Published var url = ""
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    var displayText: String {
        return "Do you want to open the URL: \(displayURL)?"
    }
    
    var displayURL: String {
        // Truncate very long URLs for display
        if url.count > 50 {
            return String(url.prefix(47)) + "..."
        }
        return url
    }
}
