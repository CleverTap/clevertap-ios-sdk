//
//  CTPushPermissionSystemAppFunction.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 20/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTPushPermissionSystemAppFunction_h
#define CTPushPermissionSystemAppFunction_h
#import "CTCustomTemplate.h"
#import "CTSystemTemplateActionHandler.h"

@interface CTPushPermissionSystemAppFunction : NSObject

+ (CTCustomTemplate *)buildTemplateWithHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler;

@end

#endif /* CTPushPermissionSystemAppFunction_h */
