import UIKit

/// UIButton subclass for in-app action buttons on tvOS.
/// Replaces the platform's default floating-card focus effect (scale-up +
/// white rounded halo) with a contained white border highlight so buttons
/// stay within their layout frame and keep their configured corner radius.
@objc(CTInAppActionButton)
class CTInAppActionButton: UIButton {

#if os(tvOS)
    private var unfocusedBorderColor: UIColor?
    private var unfocusedBorderWidth: CGFloat = 0

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        // Do NOT call super — that triggers the default tvOS floating-card
        // effect (scale-up + white rounded halo).
        coordinator.addCoordinatedAnimations {
            if context.nextFocusedView === self {
                if self.unfocusedBorderColor == nil {
                    self.unfocusedBorderColor = self.layer.borderColor.map(UIColor.init) ?? .clear
                    self.unfocusedBorderWidth = self.layer.borderWidth
                }
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 3.0
            } else if context.previouslyFocusedView === self {
                self.layer.borderColor = self.unfocusedBorderColor?.cgColor
                self.layer.borderWidth = self.unfocusedBorderWidth
            }
        }
    }
#endif
}
