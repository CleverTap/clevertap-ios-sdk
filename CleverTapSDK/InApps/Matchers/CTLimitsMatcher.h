//
//  CTLimitsMatcher.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTImpressionManager.h"
#import "CTLimitAdapter.h"
#import "CTInAppTriggerManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTLimitsMatcher : NSObject

/*!
 @param triggerManager Source of trigger counts for `onEvery` / `onExactly` limits. Normally the
 live `CTInAppTriggerManager`; a dry run passes an offsetting counter so limits are evaluated
 against the count the real path would have written, without writing it.
 */
- (BOOL)matchWhenLimits:(NSArray *)whenLimits forCampaignId:(NSString *)campaignId
  withImpressionManager:(CTImpressionManager *)impressionManager andTriggerManager:(id<CTTriggerCounting>)triggerManager;

@end

NS_ASSUME_NONNULL_END
