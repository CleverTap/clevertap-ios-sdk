//
//  CTVarCache+Tests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 02/03/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTVarCache+Tests.h"

@interface CTVarCache (Tests)
- (NSString*)dataArchiveFileName;
@end

@implementation CTVarCache (Tests)

- (NSString *)getArchiveFileName {
    return [self dataArchiveFileName];
}

@end
