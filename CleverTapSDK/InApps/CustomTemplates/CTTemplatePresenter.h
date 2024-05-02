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

@protocol CTTemplatePresenter

- (void)OnPresentWithContext:(CTTemplateContext *)context;
- (void)OnCloseClickedWithContext:(CTTemplateContext *)context;

@end

#endif /* TemplatePresenter_h */
