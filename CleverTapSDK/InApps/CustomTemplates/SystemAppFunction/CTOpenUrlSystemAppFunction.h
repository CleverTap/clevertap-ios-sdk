//
//  CTOpenUrlSystemAppFunction.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 27/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTOpenUrlSystemAppFunction_h
#define CTOpenUrlSystemAppFunction_h
#import "CTCustomTemplate.h"
#import "CTSystemTemplateActionHandler.h"

@interface CTOpenUrlSystemAppFunction : NSObject

+ (CTCustomTemplate *)buildTemplateWithHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler;

@end

#endif /* CTOpenUrlSystemAppFunction_h */
