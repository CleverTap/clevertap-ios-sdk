//
//  CTSystemAppFunctions.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 19/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTSystemAppFunctions_h
#define CTSystemAppFunctions_h

#import <Foundation/Foundation.h>
#import "CTCustomTemplate.h"
#import "CTSystemTemplateActionHandler.h"

@interface CTSystemAppFunctions : NSObject

+ (NSDictionary<NSString *, CTCustomTemplate *> *)systemAppFunctionsWithHandler:(CTSystemTemplateActionHandler *)handler;

@end


#endif /* CTSystemAppFunctions_h */
