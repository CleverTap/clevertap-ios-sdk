//
//  LimitAdapter.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTLimitAdapter.h"

@interface CTLimitAdapter()

@property (nonatomic, assign) NSDictionary *limitJSON;

@end

@implementation CTLimitAdapter

- (instancetype)initWithJSON:(NSDictionary *)limitJSON {
    if (self = [super init]) {
        self.limitJSON = limitJSON;
    }
    return self;
}

- (CTLimitType)limitType {
    NSString *limitType = self.limitJSON[@"type"];
    if ([limitType isEqualToString:@"ever"]) {
        return CTLimitTypeEver;
    } else if ([limitType isEqualToString:@"session"]) {
        return CTLimitTypeSession;
    } else if ([limitType isEqualToString:@"seconds"]) {
        return CTLimitTypeSeconds;
    } else if ([limitType isEqualToString:@"minutes"]) {
        return CTLimitTypeMinutes;
    } else if ([limitType isEqualToString:@"hours"]) {
        return CTLimitTypeHours;
    } else if ([limitType isEqualToString:@"days"]) {
        return CTLimitTypeDays;
    } else if ([limitType isEqualToString:@"weeks"]) {
        return CTLimitTypeWeeks;
    } else if ([limitType isEqualToString:@"onEvery"]) {
        return CTLimitTypeOnEvery;
    } else if ([limitType isEqualToString:@"onExactly"]) {
        return CTLimitTypeOnExactly;
    }
    return CTLimitTypeEver;
}

- (NSInteger)limit {
    NSNumber *limit = self.limitJSON[@"limit"];
    return [limit integerValue];
}

- (NSInteger)frequency {
    NSNumber *frequency = self.limitJSON[@"frequency"];
    return [frequency integerValue];
}

- (BOOL)isEmpty {
    if (self.limitJSON && [self.limitJSON count] > 0) {
        return NO;
    }
    return YES;
}

@end
