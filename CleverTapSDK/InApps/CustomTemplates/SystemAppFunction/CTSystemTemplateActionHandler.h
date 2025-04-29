//
//  CTSystemTemplateActionHandler.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 27/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTSystemTemplateActionHandler_h
#define CTSystemTemplateActionHandler_h

#import "CTPushPrimerManager.h"

@interface CTSystemTemplateActionHandler : NSObject {
    __weak CTPushPrimerManager *pushPrimerManager;
}

- (void)setPushPrimerManager:(CTPushPrimerManager* _Nonnull)pushPrimerManagerObj;

- (void)promptPushPermission:(BOOL)fbSettings withCompletionBlock:(void (^_Nonnull)(BOOL presented))completion;

- (BOOL)handleOpenURL:(NSString *_Nullable)action;

- (void)promptAppRatingWithCompletionBlock:(void (^_Nonnull)(BOOL presented))completion;

@end

#endif /* CTSystemTemplateActionHandler_h */
