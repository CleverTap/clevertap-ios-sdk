//
//  CTValidatorBase.m
//  CleverTap-iOS-SDK-iOS
//
//  Created by Sonal Kachare on 19/01/26.
//

#import "CTValidatorBase.h"

@implementation CTValidatorBase

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

@end
