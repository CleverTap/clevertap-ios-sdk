//
//  CTValidationResultStack.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "CTValidationResultStack.h"
#import "CTConstants.h"

@interface CTValidationResultStack () {}
@property (nonatomic, strong) NSMutableArray<CTValidationResult *> *pendingValidationResults;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTValidationResultStack

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.pendingValidationResults = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Validation Error Handling

- (void)pushValidationResults:(NSArray<CTValidationResult *> *)results {
    if (!results) {
        return;
    }
    for (CTValidationResult *vr in results) {
        [self pushValidationResult:vr];
    }
}

- (void)pushValidationResult:(CTValidationResult *)vr {
    if (!vr) {
        CleverTapLogInternal(self.config.logLevel, @"%@: no object in the validation result", self);
        return;
    }
    
    @synchronized (self.pendingValidationResults) {
        [self.pendingValidationResults addObject:vr];
        if (self.pendingValidationResults.count > 50) {
            [self.pendingValidationResults removeObjectAtIndex:0];
        }
    }
}

- (CTValidationResult *)popValidationResult {
    CTValidationResult *vr = nil;
    
    @synchronized (self.pendingValidationResults) {
        if (self.pendingValidationResults.count > 0) {
            vr = self.pendingValidationResults[0];
            [self.pendingValidationResults removeObjectAtIndex:0];
        }
    }
    
    return vr;
}

@end
