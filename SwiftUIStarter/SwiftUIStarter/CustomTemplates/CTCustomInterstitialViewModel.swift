import SwiftUI

final class CTCustomInterstitialViewModel: CTBaseViewModel {
    @Published var isVisible = false
    @Published var title = CustomInterstitialTemplate.DefaultValues.title
    @Published var message = CustomInterstitialTemplate.DefaultValues.message
    @Published var image: UIImage?
    @Published var showCloseButton = CustomInterstitialTemplate.DefaultValues.showCloseButton
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    func configure(with configuration: InterstitialConfiguration) {
        title = configuration.title
        message = configuration.message
        image = configuration.image
        showCloseButton = configuration.showCloseButton
    }
}
