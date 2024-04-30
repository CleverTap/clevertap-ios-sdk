//
//  CTCustomTemplate.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTCustomTemplate.h"
#import "CTCustomTemplate-Internal.h"

@interface CTCustomTemplate ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *templateType;
@property (nonatomic, strong) NSArray<CTTemplateArgument *> *arguments;
@property (nonatomic, strong) id<CTTemplatePresenter> presenter;

@end

@implementation CTCustomTemplate

- (instancetype)initWithTemplateName:(NSString *)templateName
                        templateType:(NSString *)templateType
                           arguments:(NSArray *)arguments
                           presenter:(id<CTTemplatePresenter>)presenter {
    if (self = [super init]) {
        _name = [templateName copy];
        _templateType = [templateType copy];
        _arguments = arguments;
        _presenter = presenter;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    }
    if (![other isKindOfClass:[CTCustomTemplate class]]) {
        return NO;
    }
    CTCustomTemplate *otherTemplate = (CTCustomTemplate *)other;
    return [self.name isEqualToString:otherTemplate.name];
}

- (NSUInteger)hash {
    return [self.name hash];
}

@end