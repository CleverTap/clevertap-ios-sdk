import SwiftUI

final class CTCustomInterstitialViewModel: CTBaseViewModel {
    @Published var isVisible = false
    @Published var title = CTCustomInterstitialTemplate.DefaultValues.title
    @Published var message = CTCustomInterstitialTemplate.DefaultValues.message
    @Published var image: UIImage?
    @Published var showCloseButton = CTCustomInterstitialTemplate.DefaultValues.showCloseButton
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    func configure(with configuration: CTInterstitialConfiguration) {
        title = configuration.title
        message = configuration.message
        image = configuration.image
        showCloseButton = configuration.showCloseButton
    }
}
