//
//  CTNotificationAction.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 9.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCustomTemplateInAppData.h"
#import "CTInAppUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTNotificationAction : NSObject

@property (nonatomic, readonly) CTInAppActionType type;
@property (nonatomic, copy, readonly) NSURL *actionURL;
@property (nonatomic, strong, readonly) NSDictionary *keyValues;
@property (nonatomic, readonly) BOOL fallbackToSettings;
@property (nonatomic, strong, readonly) CTCustomTemplateInAppData *customTemplateInAppData;

@property (nonatomic, readonly) NSString *error;

- (instancetype)init NS_UNAVAILABLE;
#if !CLEVERTAP_NO_INAPP_SUPPORT
- (instancetype)initWithJSON:(NSDictionary *)json;
- (instancetype)initWithOpenURL:(NSURL *)url;
#endif

@end

NS_ASSUME_NONNULL_END
