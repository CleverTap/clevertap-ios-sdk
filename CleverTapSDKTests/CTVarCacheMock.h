//
//  CTVarCacheMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTVarCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTVarCacheMock : CTVarCache

@property int loadCount;
@property int applyCount;
@property int saveCount;

- (void)originalSaveDiffs;

@end

NS_ASSUME_NONNULL_END
