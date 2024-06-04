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
#import "CTInAppNotificationDisplayDelegate.h"

@protocol CTTemplateContextDismissDelegate <NSObject>

- (void)onDismissContext:(CTTemplateContext *)context;

@end

@interface CTTemplateContext (Internal)

- (instancetype)initWithTemplate:(CTCustomTemplate *)customTemplate andNotification:(CTInAppNotification *)notification;

- (void)setNotificationDelegate:(id<CTInAppNotificationDisplayDelegate>)delegate;

- (void)setDismissDelegate:(id<CTTemplateContextDismissDelegate>)delegate;

@end

#endif /* CTTemplateContext_Internal_h */
