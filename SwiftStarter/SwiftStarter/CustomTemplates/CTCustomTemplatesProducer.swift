import Foundation
import CleverTapSDK

enum CTCustomInterstitialTemplate {
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

enum CTCopyToClipboardTemplate {
    static let name = "Copy to clipboard"
    static let visible = false
    
    enum DefaultValues {
        static let text = ""
    }
    
    enum ArgumentNames {
        static let text = "Text"
    }
}

enum CTOpenURLConfirmTemplate {
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
        builder.setName(CTCustomInterstitialTemplate.name)
        
        builder.addArgument(
            CTCustomInterstitialTemplate.ArgumentNames.title,
            string: CTCustomInterstitialTemplate.DefaultValues.title
        )
        builder.addArgument(
            CTCustomInterstitialTemplate.ArgumentNames.message,
            string: CTCustomInterstitialTemplate.DefaultValues.message
        )
        builder.addArgument(
            CTCustomInterstitialTemplate.ArgumentNames.showCloseButton,
            boolean: CTCustomInterstitialTemplate.DefaultValues.showCloseButton
        )
        builder.addArgument(
            CTCustomInterstitialTemplate.ArgumentNames.autoCloseAfter,
            number: NSNumber(value: CTCustomInterstitialTemplate.DefaultValues.autoCloseAfter)
        )
        
        builder.addFileArgument(CTCustomInterstitialTemplate.ArgumentNames.image)
        builder.addActionArgument(CTCustomInterstitialTemplate.ArgumentNames.openAction)
        builder.setPresenter(CTCustomInterstitialPresenter())
        
        return builder.build()
    }
    
    private static func buildCopyToClipboardTemplate() -> CTCustomTemplate {
        let builder = CTAppFunctionBuilder(isVisual: CTCopyToClipboardTemplate.visible)
        builder.setName(CTCopyToClipboardTemplate.name)
        builder.addArgument(
            CTCopyToClipboardTemplate.ArgumentNames.text,
            string: CTCopyToClipboardTemplate.DefaultValues.text
        )
        builder.setPresenter(CTCopyToClipBoardPresenter())
        return builder.build()
    }
    
    private static func buildOpenURLConfirmTemplate() -> CTCustomTemplate {
        let builder = CTAppFunctionBuilder(isVisual: CTOpenURLConfirmTemplate.visible)
        builder.setName(CTOpenURLConfirmTemplate.name)
        builder.addArgument(
            CTOpenURLConfirmTemplate.ArgumentNames.url,
            string: CTOpenURLConfirmTemplate.DefaultValues.url
        )
        builder.setPresenter(CTOpenURLConfirmPresenter())
        return builder.build()
    }
    
    // MARK: - CTTemplateProducer
    func defineTemplates(_ instanceConfig: CleverTapInstanceConfig) -> Set<CTCustomTemplate> {
        let templates = Self.templates.values
        print("Defining \(templates.count) custom templates for instance: \(instanceConfig.accountId)")
        return Set(templates)
    }
}
