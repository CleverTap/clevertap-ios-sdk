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
#import "CTOpenUrlSystemAppFunction.h"
#import "CTAppRatingSystemAppFunction.h"

@implementation CTSystemAppFunctions

+ (NSDictionary<NSString *, CTCustomTemplate *> *)systemAppFunctionsWithHandler:(CTSystemTemplateActionHandler *)handler {
    NSMutableDictionary *systemAppFunctions = [NSMutableDictionary new];
    systemAppFunctions[CLTAP_PUSH_PERMISSION_TEMPLATE_NAME] = [CTPushPermissionSystemAppFunction buildTemplateWithHandler:handler];
    systemAppFunctions[CLTAP_OPEN_URL_TEMPLATE_NAME] = [CTOpenUrlSystemAppFunction buildTemplateWithHandler:handler];
    systemAppFunctions[CLTAP_APP_RATING_TEMPLATE_NAME] = [CTAppRatingSystemAppFunction buildTemplateWithHandler:handler];
    return systemAppFunctions;
}

@end
