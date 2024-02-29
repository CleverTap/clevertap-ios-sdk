//
//  CTTemplateArgument.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTTemplateArgument.h"

@implementation CTTemplateArgument

- (instancetype)initWithName:(NSString *)name type:(NSString *)type defaultValue:(id)defaultValue {
    self = [super init];
    if (self) {
        _name = [name copy];
        _type = [type copy];
        _defaultValue = defaultValue;
    }
    return self;
}

@end
