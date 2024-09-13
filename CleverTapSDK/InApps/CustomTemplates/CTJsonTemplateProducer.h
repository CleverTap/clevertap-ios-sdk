//
//  CTJsonTemplateProducer.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 13.09.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplatePresenter.h"
#import "CTCustomTemplate.h"
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTJsonTemplateProducer : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithJsonTemplateDefinitions:(nonnull NSString *)jsonTemplateDefinitions
                                      templatePresenter:(nonnull id<CTTemplatePresenter>)templatePresenter
                                      functionPresenter:(nonnull id<CTTemplatePresenter>)functionPresenter;

- (NSSet<CTCustomTemplate *> * _Nonnull)defineTemplates:(CleverTapInstanceConfig * _Nonnull)instanceConfig;

@end

NS_ASSUME_NONNULL_END
