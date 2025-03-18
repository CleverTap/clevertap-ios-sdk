//
//  CTInAppTemplateBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCustomTemplateBuilder.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 Builder for ``CTCustomTemplate`` code templates. See ``CTCustomTemplateBuilder``.
 */
@interface CTInAppTemplateBuilder : CTCustomTemplateBuilder

- (instancetype)init;

/*!
 Action arguments are specified by name only. When the ``CTCustomTemplate`` is triggered, the configured action
 can be executed through ``CTTemplateContext/triggerActionNamed:``.
 Action values could either be a predefined action (like close or open-url) or а registered ``CTCustomTemplate`` function.
 */
- (void)addActionArgument:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
