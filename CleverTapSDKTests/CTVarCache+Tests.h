//
//  CTVarCache+Tests.h
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 02/03/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTVarCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTVarCache (Tests)
- (NSString *)getArchiveFileName;
- (id)traverse:(id)collection withKey:(id)key autoInsert:(BOOL)autoInsert;
- (void)saveDiffs;
@end

NS_ASSUME_NONNULL_END
