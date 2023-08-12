//
//  CTRetryManager.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 10/08/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTRetryManager.h"
#import "CTConstants.h"

@interface CTRetryManager ()
@property (nonatomic, assign) int currentDelayFrequency;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTRetryManager

- (NSString *)description
{
    return [NSString stringWithFormat:@"CleverTap.%@", self.config.accountId];
}

- (int)getDelayFrequency {
    if (self.sendQueueFails < 10) {
        self.currentDelayFrequency = CLTAP_PUSH_DELAY_SECONDS;
    }
    else {
        srandom((unsigned int)time(NULL));
        int randomDelay = (arc4random_uniform(10) + 1);
        self.currentDelayFrequency += randomDelay;
        
        if (self.currentDelayFrequency >= CLTAP_MAX_DELAY) {
            self.currentDelayFrequency = CLTAP_PUSH_DELAY_SECONDS;
        }
    }
    CleverTapLogDebug(self.config.logLevel, @"%@: scheduling queue flush in %i seconds", self, self.currentDelayFrequency);
    return self.currentDelayFrequency;
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config {
    self = [super init];
    if (self) {
        self.config = config;
    }
    return self;
}

- (void)resetFailsCounter {
    self.sendQueueFails = 0;
}

- (void)incrementFailsCounter {
    self.sendQueueFails += 1;
}

@end
