//
//  CTTestTemplateProducer.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 11.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplateProducer.h"
#import "CTCustomTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTTestTemplateProducer : NSObject<CTTemplateProducer>

@property (nonatomic, strong) NSSet<CTCustomTemplate *> *templates;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTemplates:(NSSet<CTCustomTemplate *> *)templates;

@end

NS_ASSUME_NONNULL_END
