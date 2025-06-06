import SwiftUI

class CTCustomInterstitialViewModel: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var title: String = CustomInterstitialTemplate.Constants.title
    @Published var message: String = CustomInterstitialTemplate.Constants.message
    @Published var image: UIImage?
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
}
