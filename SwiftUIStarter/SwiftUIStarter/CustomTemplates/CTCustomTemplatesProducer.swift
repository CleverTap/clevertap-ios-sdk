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
        let customInterstitialBuilder = CTInAppTemplateBuilder()
        customInterstitialBuilder.setName("Custom Interstitial")
        customInterstitialBuilder.addArgument("Title", string: CustomInterstitialTemplate.Constants.title)
        customInterstitialBuilder.addArgument("Message", string: CustomInterstitialTemplate.Constants.message)
        customInterstitialBuilder.addFileArgument("Image")
        customInterstitialBuilder.addActionArgument("Open action")
        customInterstitialBuilder.setPresenter(CTCustomInterstitialPresenter.shared)
        let customInterstitial = customInterstitialBuilder.build()
        
        let copyFunctionBuilder = CTAppFunctionBuilder(isVisual: false)
        copyFunctionBuilder.setName("Copy to clipboard")
        copyFunctionBuilder.addArgument("Text", string: "")
        copyFunctionBuilder.setPresenter(CTCopyToClipBoardPresenter())
        let copyFunction = copyFunctionBuilder.build()
        
        let openURLConfirmBuilder = CTAppFunctionBuilder(isVisual: true)
        openURLConfirmBuilder.setName("Open URL with confirm")
        openURLConfirmBuilder.addArgument("URL", string: "")
        openURLConfirmBuilder.setPresenter(CTOpenURLConfirmPresenter.shared)
        let openURLConfirm = openURLConfirmBuilder.build()
        
        return [
            customInterstitial.name: customInterstitial,
            copyFunction.name: copyFunction,
            openURLConfirm.name: openURLConfirm
        ]
    }
    
    public func defineTemplates(_ instanceConfig: CleverTapInstanceConfig) -> Set<CTCustomTemplate> {
        return Set(CTCustomTemplatesProducer.templates.values)
    }
}
