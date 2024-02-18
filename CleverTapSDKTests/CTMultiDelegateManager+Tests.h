//
//  CTMultiDelegateManager+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 3.01.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTMultiDelegateManager.h"

@interface CTMultiDelegateManager (Tests)

@property (nonatomic, strong) NSHashTable<id<CTAttachToBatchHeaderDelegate>> *attachToHeaderDelegates;
@property (nonatomic, strong) NSHashTable<id<CTSwitchUserDelegate>> *switchUserDelegates;
@property (nonatomic, strong) NSHashTable<id<CTBatchSentDelegate>> *batchSentDelegates;

@end
