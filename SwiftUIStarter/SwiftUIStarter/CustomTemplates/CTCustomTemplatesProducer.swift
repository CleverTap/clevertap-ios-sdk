import Foundation
import CleverTapSDK

class CustomInterstitialTemplate {
    enum Constants {
        static let title = "Title text"
        static let message = "Message text"
        static let image = "logo"
    }
}

class CTCustomTemplatesProducer: CTTemplateProducer {
    static var templates: [String: CTCustomTemplate] {
        let templateBuilder = CTInAppTemplateBuilder()
        templateBuilder.setName("Custom Interstitial")
        templateBuilder.addArgument("Title", string: CustomInterstitialTemplate.Constants.title)
        templateBuilder.addArgument("Message", string: CustomInterstitialTemplate.Constants.message)
        templateBuilder.addFileArgument("Image")
        templateBuilder.addActionArgument("Open action")
        templateBuilder.setPresenter(CTCustomInterstitialPresenter.shared)
        let template = templateBuilder.build()
        
        return [template.name: template]
    }
    
    public func defineTemplates(_ instanceConfig: CleverTapInstanceConfig) -> Set<CTCustomTemplate> {
        return Set(CTCustomTemplatesProducer.templates.values)
    }
}
