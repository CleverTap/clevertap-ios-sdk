//
//  CTSystemAppFunction.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 19/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTSystemAppFunction_h
#define CTSystemAppFunction_h

#import <Foundation/Foundation.h>
#import "CTCustomTemplate.h"
#import "CTSystemTemplateActionHandler.h"

@interface CTSystemAppFunction : NSObject

- (instancetype)initWithSystemTemplateActionHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler;

- (NSDictionary<NSString *, CTCustomTemplate *> *)getSystemAppFunctions;

@end


#endif /* CTSystemAppFunction_h */
