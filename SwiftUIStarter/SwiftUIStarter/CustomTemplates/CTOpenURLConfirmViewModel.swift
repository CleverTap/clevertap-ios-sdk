import Foundation
import SwiftUI

final class CTOpenURLConfirmViewModel: CTBaseViewModel {
    @Published var isVisible = false
    @Published var url = ""
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    var displayURL: String {
        // Truncate very long URLs for display
        if url.count > 50 {
            return String(url.prefix(47)) + "..."
        }
        return url
    }
    
    var isValidURL: Bool {
        guard let url = URL(string: url) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
