//
//  CTVariables+Tests.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTVariables+Tests.h"

@implementation CTVariables (Tests)

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo: (CTDeviceInfo *)deviceInfo varCache: (CTVarCacheMock *)varCache {
    self = [super init];
    if (self) {
        self.varCache = varCache;
        [self.varCache setDelegate:self];
    }
    return self;
}

@end
