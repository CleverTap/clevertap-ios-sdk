//
//  CTPushPermissionSystemAppFunction.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 20/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTPushPermissionSystemAppFunction.h"
#import "CTAppFunctionBuilder-Internal.h"
#import "CTSystemAppFunctionPresenter.h"
#import "CTConstants.h"

@implementation CTPushPermissionSystemAppFunction

+ (CTCustomTemplate *)buildTemplateWithHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler {
    CTCustomTemplateBuilder *pushPermissionbuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO isSystemDefined:YES];
    [pushPermissionbuilder setName:CLTAP_PUSH_PERMISSION_TEMPLATE_NAME];
    [pushPermissionbuilder addArgument:CLTAP_FB_SETTINGS_KEY withBool:NO];
    CTSystemAppFunctionPresenter *presenter = [[CTSystemAppFunctionPresenter alloc] initWithSystemTemplateActionHandler:systemTemplateActionHandler];
    [pushPermissionbuilder setPresenter:presenter];

    CTCustomTemplate *pushPermissionTemplate = [pushPermissionbuilder build];
    return pushPermissionTemplate;
}

@end
