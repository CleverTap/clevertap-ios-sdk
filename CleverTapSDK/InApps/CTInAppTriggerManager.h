//
//  CTInAppTriggerManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppTriggerManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId;

- (NSUInteger)getTriggers:(NSString *)campaignId;
- (void)incrementTrigger:(NSString *)campaignId;
- (void)removeTriggers:(NSString *)campaignId;

@end

NS_ASSUME_NONNULL_END
