//
//  CTVarCacheMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTVarCacheMock.h"
#import "CTVarCache+Tests.h"

@implementation CTVarCacheMock

- (void)loadDiffs {
    self.loadCount++;
    [super loadDiffs];
}

- (void)applyVariableDiffs:(NSDictionary<NSString *,id> *)diffs_ {
    self.applyCount++;
    [super applyVariableDiffs:diffs_];
}

- (void)saveDiffs {
    // Do NOT save to file
    self.saveCount++;
}

- (void)originalSaveDiffs {
    // Save to file
    [super saveDiffs];
}

@end
