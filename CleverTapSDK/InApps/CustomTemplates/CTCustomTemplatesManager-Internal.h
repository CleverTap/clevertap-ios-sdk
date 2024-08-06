//
//  CTCustomTemplatesManager-Internal.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTCustomTemplatesManager_Internal_h
#define CTCustomTemplatesManager_Internal_h

#import "CTCustomTemplatesManager.h"
#import "CleverTapInstanceConfig.h"
#import "CTInAppNotification.h"
#import "CTInAppNotificationDisplayDelegate.h"
#import "CTFileDownloader.h"

@interface CTCustomTemplatesManager (Internal)

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)instanceConfig;

- (NSSet<NSString *> *)fileArgsURLsForInAppData:(CTCustomTemplateInAppData *)inAppData;
- (NSSet<NSString *> *)fileArgsURLs:(NSDictionary *)inAppJSON;

- (BOOL)presentNotification:(CTInAppNotification *)notification
               withDelegate:(id<CTInAppNotificationDisplayDelegate>)delegate
          andFileDownloader:(CTFileDownloader *)fileDownloader;

- (void)closeNotification:(CTInAppNotification *)notification;

@end

#endif /* CTCustomTemplatesManager_Internal_h */
