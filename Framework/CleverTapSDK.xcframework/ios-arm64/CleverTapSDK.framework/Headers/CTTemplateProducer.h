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

@protocol CTTemplateProducer

/*!
 Defines custom templates.
 
 @param instanceConfig Use the config to decide which instance the templates are defined for.
 
 @return A set of ``CTCustomTemplate`` definitions. ``CTCustomTemplate``s are uniquely identified by their name.
 */
- (NSSet<CTCustomTemplate *> * _Nonnull)defineTemplates:(CleverTapInstanceConfig * _Nonnull)instanceConfig;

@end
#endif /* TemplateProducer_h */
