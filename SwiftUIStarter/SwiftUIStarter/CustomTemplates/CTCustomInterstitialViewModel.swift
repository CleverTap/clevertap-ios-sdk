import SwiftUI

class CTCustomInterstitialViewModel: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var title: String = CustomInterstitialTemplate.DefaultValues.title
    @Published var message: String = CustomInterstitialTemplate.DefaultValues.message
    @Published var image: UIImage?
    @Published var showCloseButton: Bool = CustomInterstitialTemplate.DefaultValues.showCloseButton
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
}
