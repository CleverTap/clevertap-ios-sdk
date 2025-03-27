//
//  CTSystemAppFunctionPresenter.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 20/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTSystemAppFunctionPresenter_h
#define CTSystemAppFunctionPresenter_h

#import "CTTemplatePresenter.h"
#import "CTSystemTemplateActionHandler.h"

@interface CTSystemAppFunctionPresenter :  NSObject <CTTemplatePresenter>

- (instancetype)initWithSystemTemplateActionHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler;

@end

#endif /* CTSystemAppFunctionPresenter_h */
