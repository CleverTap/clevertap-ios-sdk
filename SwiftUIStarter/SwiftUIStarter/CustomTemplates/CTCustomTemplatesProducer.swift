import Foundation
import CleverTapSDK

enum CustomInterstitialTemplate {
    static let name = "Custom Interstitial"
    
    enum DefaultValues {
        static let title = "Title text"
        static let message = "Message text"
        static let image = "logo"
        static let showCloseButton = true
        static let autoCloseAfter = 0.0
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

enum CopyToClipboardTemplate {
    static let name = "Copy to clipboard"
    static let visible = false
    
    enum DefaultValues {
        static let text = ""
    }
    
    enum ArgumentNames {
        static let text = "Text"
    }
}

enum OpenURLConfirmTemplate {
    static let name = "Open URL with confirm"
    static let visible = true
    
    enum DefaultValues {
        static let url = ""
    }
    
    enum ArgumentNames {
        static let url = "URL"
    }
}

final class CTCustomTemplatesProducer: CTTemplateProducer {
    
    static var templates: [String: CTCustomTemplate] {
            let interstitial = buildCustomInterstitialTemplate()
            let copyFunction = buildCopyToClipboardTemplate()
            let urlConfirm = buildOpenURLConfirmTemplate()
            
            return [
                interstitial.name: interstitial,
                copyFunction.name: copyFunction,
                urlConfirm.name: urlConfirm
            ]
    }
    
    // MARK: - Template Builders
    private static func buildCustomInterstitialTemplate() -> CTCustomTemplate {
        let builder = CTInAppTemplateBuilder()
        builder.setName(CustomInterstitialTemplate.name)
        
        builder.addArgument(
            CustomInterstitialTemplate.ArgumentNames.title,
            string: CustomInterstitialTemplate.DefaultValues.title
        )
        builder.addArgument(
            CustomInterstitialTemplate.ArgumentNames.message,
            string: CustomInterstitialTemplate.DefaultValues.message
        )
        builder.addArgument(
            CustomInterstitialTemplate.ArgumentNames.showCloseButton,
            boolean: CustomInterstitialTemplate.DefaultValues.showCloseButton
        )
        builder.addArgument(
            CustomInterstitialTemplate.ArgumentNames.autoCloseAfter,
            number: NSNumber(floatLiteral: CustomInterstitialTemplate.DefaultValues.autoCloseAfter)
        )
        
        builder.addFileArgument(CustomInterstitialTemplate.ArgumentNames.image)
        builder.addActionArgument(CustomInterstitialTemplate.ArgumentNames.openAction)
        builder.setPresenter(CTCustomInterstitialPresenter.shared)
        
        return builder.build()
    }
    
    private static func buildCopyToClipboardTemplate() -> CTCustomTemplate {
        let builder = CTAppFunctionBuilder(isVisual: CopyToClipboardTemplate.visible)
        builder.setName(CopyToClipboardTemplate.name)
        builder.addArgument(
            CopyToClipboardTemplate.ArgumentNames.text,
            string: CopyToClipboardTemplate.DefaultValues.text
        )
        builder.setPresenter(CTCopyToClipBoardPresenter())
        return builder.build()
    }
    
    private static func buildOpenURLConfirmTemplate() -> CTCustomTemplate {
        let builder = CTAppFunctionBuilder(isVisual: OpenURLConfirmTemplate.visible)
        builder.setName(OpenURLConfirmTemplate.name)
        builder.addArgument(
            OpenURLConfirmTemplate.ArgumentNames.url,
            string: OpenURLConfirmTemplate.DefaultValues.url
        )
        builder.setPresenter(CTOpenURLConfirmPresenter.shared)
        return builder.build()
    }
    
    // MARK: - CTTemplateProducer
    func defineTemplates(_ instanceConfig: CleverTapInstanceConfig) -> Set<CTCustomTemplate> {
        let templates = Self.templates.values
        print("Defining \(templates.count) custom templates for instance: \(instanceConfig.accountId)")
        return Set(templates)
    }
}
