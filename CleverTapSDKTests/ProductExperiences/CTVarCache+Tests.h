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

@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *valuesFromClient;
@property (strong, nonatomic) id merged;

- (NSString*)dataArchiveFileName;
- (id)traverse:(id)collection withKey:(id)key autoInsert:(BOOL)autoInsert;
- (void)saveDiffs;

@end

NS_ASSUME_NONNULL_END
