//
//  CTImpressionManager+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 17.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CTImpressionManager_Tests_h
#define CTImpressionManager_Tests_h

@interface CTImpressionManager(Tests)
@property (nonatomic, strong) NSMutableDictionary *sessionImpressions;
@property (nonatomic, strong) NSMutableDictionary *impressions;
@property (nonatomic, assign) int sessionImpressionsTotal;
- (NSInteger)getImpressionCount:(NSString *)campaignId;
@end

#endif /* CTImpressionManager_Tests_h */
