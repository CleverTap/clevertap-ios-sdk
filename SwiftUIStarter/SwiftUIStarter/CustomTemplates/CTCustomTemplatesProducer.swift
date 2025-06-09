import Foundation
import CleverTapSDK

class CustomInterstitialTemplate {
    enum DefaultValues {
        static let title = "Title text"
        static let message = "Message text"
        static let image = "logo"
        static let showCloseButton = true
    }
    enum ArgumentNames {
        static let title = "Title"
        static let message = "Message"
        static let image = "Image"
        static let openAction = "Open action"
        static let showCloseButton = "Show close button"
        static let autoCloseAfter = "Auto close after"
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
        customInterstitialBuilder.addArgument(CustomInterstitialTemplate.ArgumentNames.showCloseButton, boolean: CustomInterstitialTemplate.DefaultValues.showCloseButton)
        customInterstitialBuilder.addArgument(CustomInterstitialTemplate.ArgumentNames.autoCloseAfter, number: 0.0)
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
