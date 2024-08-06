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

@protocol CTTemplatePresenter

- (void)onPresent:(CTTemplateContext *)context
NS_SWIFT_NAME(onPresent(context:));

- (void)onCloseClicked:(CTTemplateContext *)context
NS_SWIFT_NAME(onCloseClicked(context:));

@end

NS_ASSUME_NONNULL_END

#endif /* TemplatePresenter_h */
