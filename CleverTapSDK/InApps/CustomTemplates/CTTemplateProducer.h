//
//  CTTemplateProducer.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTTemplateProducer_h
#define CTTemplateProducer_h

#import "CTCustomTemplate.h"
#import "CleverTapInstanceConfig.h"

@protocol CTTemplateProducer <NSObject>

- (NSSet<CTCustomTemplate *> *)defineTemplates:(CleverTapInstanceConfig *)instanceConfig;

@end
#endif /* TemplateProducer_h */
