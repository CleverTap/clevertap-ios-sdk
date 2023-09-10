//
//  TriggerValue.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggerValue.h"

@interface CTTriggerValue()

@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, strong) NSArray *arrayValue;

@end

@implementation CTTriggerValue

- (instancetype)initWithValue:(id)value {
    if (self = [super init]) {
        self.value = value;
        if ([value isKindOfClass:[NSString class]]) {
            self.stringValue = value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            self.numberValue = value;
        } else if ([value isKindOfClass:[NSArray class]]) {
            self.arrayValue = value;
        }
    }
    return self;
}

- (BOOL)isArray {
    return self.arrayValue != nil;
}

@end
