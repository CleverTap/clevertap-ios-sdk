//
//  CTTemplateArgument.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTTemplateArgument.h"

@implementation CTTemplateArgument

- (instancetype)initWithName:(NSString *)name type:(CTTemplateArgumentType)type defaultValue:(id)defaultValue {
    self = [super init];
    if (self) {
        _name = [name copy];
        _type = type;
        _defaultValue = [defaultValue copy];
    }
    return self;
}

+ (NSString *)templateArgumentTypeToString:(CTTemplateArgumentType)type {
    static NSDictionary *enumStringMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        enumStringMap = @{
            @(CTTemplateArgumentTypeString): @"string",
            @(CTTemplateArgumentTypeNumber): @"number",
            @(CTTemplateArgumentTypeBool): @"boolean",
            @(CTTemplateArgumentTypeAction): @"action",
            @(CTTemplateArgumentTypeFile): @"file",

        };
    });
    return enumStringMap[@(type)];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[CTTemplateArgument class]]) {
        return NO;
    }
    
    CTTemplateArgument *otherArgument = (CTTemplateArgument *)object;
    if (![self.name isEqualToString:otherArgument.name]) {
        return NO;
    }
    if (self.type != otherArgument.type) {
        return NO;
    }
    if (self.defaultValue != otherArgument.defaultValue && ![self.defaultValue isEqual:otherArgument.defaultValue]) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + [self.name hash];
    result = prime * result + self.type;
    result = prime * result + [self.defaultValue hash];
    
    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> name: %@, type: %@, defaultValue: %@",
            [self class],
            self,
            self.name,
            [CTTemplateArgument templateArgumentTypeToString:self.type],
            self.defaultValue];
}

@end
