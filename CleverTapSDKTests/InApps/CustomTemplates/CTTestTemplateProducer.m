//
//  CTTestTemplateProducer.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 11.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTTestTemplateProducer.h"

@implementation CTTestTemplateProducer

- (instancetype)initWithTemplates:(NSSet<CTCustomTemplate *> *)templates {
    if (self = [super init]) {
        _templates = templates;
    }
    return self;
}

- (NSSet<CTCustomTemplate *> *)defineTemplates:(NSString *)accountId {
    return self.templates;
}

@end
