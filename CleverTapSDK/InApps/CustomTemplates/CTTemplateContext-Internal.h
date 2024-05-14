//
//  CTTemplateContext-Internal.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTTemplateContext_Internal_h
#define CTTemplateContext_Internal_h

#import "CTInAppNotification.h"
#import "CTCustomTemplate.h"
#import "CTTemplateContext.h"

@interface CTTemplateContext (Internal)

- (instancetype)initWithTemplate:(CTCustomTemplate *)template andNotification:(CTInAppNotification *)notification;

@end

#endif /* CTTemplateContext_Internal_h */
