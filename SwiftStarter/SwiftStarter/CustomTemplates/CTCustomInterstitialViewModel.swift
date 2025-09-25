import UIKit

final class CTCustomInterstitialViewModel: CTBaseViewModel {
    var title = CTCustomInterstitialTemplate.DefaultValues.title
    var message = CTCustomInterstitialTemplate.DefaultValues.message
    var image: UIImage?
    var showCloseButton = CTCustomInterstitialTemplate.DefaultValues.showCloseButton
    
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    func configure(with configuration: CTInterstitialConfiguration) {
        title = configuration.title
        message = configuration.message
        image = configuration.image
        showCloseButton = configuration.showCloseButton
    }
}
