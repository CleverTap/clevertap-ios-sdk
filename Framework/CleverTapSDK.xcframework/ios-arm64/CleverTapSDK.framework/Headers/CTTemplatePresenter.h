//
//  TemplatePresenter.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTTemplatePresenter_h
#define CTTemplatePresenter_h

#import "CTTemplateContext.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 A handler of custom code templates ``CTCustomTemplate``. Its methods are called when the corresponding InApp
 message should be presented to the user or closed.
 */
@protocol CTTemplatePresenter

/*!
 Called when a ``CTCustomTemplate`` should be presented or a function should be executed. For visual templates
 (code templates and functions with ``CTCustomTemplate/isVisual`` equals `YES`)  implementing classes should use the provided
 ``CTTemplateContext`` methods ``CTTemplateContext/presented`` and
 ``CTTemplateContext/dismissed`` to notify the SDK of the state of the template invocation. Only
 one visual template or other InApp message can be displayed at a time by the SDK and no new messages can be
 shown until the current one is dismissed.
 */
- (void)onPresent:(CTTemplateContext *)context
NS_SWIFT_NAME(onPresent(context:));

/*!
 Called when a ``CTCustomTemplate`` action Notification Close is executed. Dismiss the custom template InApp and call ``CTTemplateContext/dismissed`` to notify the SDK the template is dismissed.
 */
- (void)onCloseClicked:(CTTemplateContext *)context
NS_SWIFT_NAME(onCloseClicked(context:));

@end

NS_ASSUME_NONNULL_END

#endif /* TemplatePresenter_h */
