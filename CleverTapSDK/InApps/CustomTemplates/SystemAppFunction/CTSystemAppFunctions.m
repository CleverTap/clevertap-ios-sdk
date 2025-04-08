//
//  CTSystemAppFunctions.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 19/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSystemAppFunctions.h"
#import "CTConstants.h"
#import "CTPushPermissionSystemAppFunction.h"

@implementation CTSystemAppFunctions

+ (NSDictionary<NSString *, CTCustomTemplate *> *)systemAppFunctionsWithHandler:(CTSystemTemplateActionHandler *)handler {
    NSMutableDictionary *systemAppFunctions = [NSMutableDictionary new];
    systemAppFunctions[CLTAP_PUSH_PERMISSION_TEMPLATE_NAME] = [CTPushPermissionSystemAppFunction buildTemplateWithHanlder:handler];
    return systemAppFunctions;
}

@end
