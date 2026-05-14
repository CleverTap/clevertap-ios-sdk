//
//  CTAppFunctionBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCustomTemplateBuilder.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 Builder for ``CTCustomTemplate`` functions. See ``CTCustomTemplateBuilder``.
 */
@interface CTAppFunctionBuilder : CTCustomTemplateBuilder

/*!
 Use `isVisual` to set if the template has UI or not. 
 If set to `YES` the template is registered as part of the in-apps queue
 and must be explicitly dismissed before other in-apps can be shown.
 If set to `NO` the template is executed directly and does not require dismissal nor it impedes other in-apps.
 
 @param isVisual Whether the function will present UI.
 */
- (instancetype)initWithIsVisual:(BOOL)isVisual;

@end

NS_ASSUME_NONNULL_END
