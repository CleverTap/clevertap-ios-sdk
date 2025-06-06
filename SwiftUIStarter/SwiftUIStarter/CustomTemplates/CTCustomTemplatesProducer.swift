import Foundation
import CleverTapSDK

class CustomInterstitialTemplate {
    enum DefaultValues {
        static let title = "Title text"
        static let message = "Message text"
        static let image = "logo"
    }
    enum ArgumentNames {
        static let title = "Title"
        static let message = "Message"
        static let image = "Image"
        static let openAction = "Open action"
    }
}

class CopyToClipboardTemplate {
    enum ArgumentNames {
        static let text = "Text"
    }
}

class OpenURLConfirmTemplate {
    enum ArgumentNames {
        static let url = "URL"
    }
}

class CTCustomTemplatesProducer: CTTemplateProducer {
    static var templates: [String: CTCustomTemplate] {
        let customInterstitialBuilder = CTInAppTemplateBuilder()
        customInterstitialBuilder.setName("Custom Interstitial")
        customInterstitialBuilder.addArgument(CustomInterstitialTemplate.ArgumentNames.title, string: CustomInterstitialTemplate.DefaultValues.title)
        customInterstitialBuilder.addArgument(CustomInterstitialTemplate.ArgumentNames.message, string: CustomInterstitialTemplate.DefaultValues.message)
        customInterstitialBuilder.addFileArgument(CustomInterstitialTemplate.ArgumentNames.image)
        customInterstitialBuilder.addActionArgument(CustomInterstitialTemplate.ArgumentNames.openAction)
        customInterstitialBuilder.setPresenter(CTCustomInterstitialPresenter.shared)
        let customInterstitial = customInterstitialBuilder.build()
        
        let copyFunctionBuilder = CTAppFunctionBuilder(isVisual: false)
        copyFunctionBuilder.setName("Copy to clipboard")
        copyFunctionBuilder.addArgument(CopyToClipboardTemplate.ArgumentNames.text, string: "")
        copyFunctionBuilder.setPresenter(CTCopyToClipBoardPresenter())
        let copyFunction = copyFunctionBuilder.build()
        
        let openURLConfirmBuilder = CTAppFunctionBuilder(isVisual: true)
        openURLConfirmBuilder.setName("Open URL with confirm")
        openURLConfirmBuilder.addArgument(OpenURLConfirmTemplate.ArgumentNames.url, string: "")
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
