//
//  CTOpenUrlSystemAppFunction.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 27/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTOpenUrlSystemAppFunction.h"
#import "CTAppFunctionBuilder-Internal.h"
#import "CTSystemAppFunctionPresenter.h"
#import "CTConstants.h"

@implementation CTOpenUrlSystemAppFunction

+ (CTCustomTemplate *)buildTemplateWithHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler {
    CTCustomTemplateBuilder *openUrlbuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO isSystemDefined:YES];
    [openUrlbuilder setName:CLTAP_OPEN_URL_TEMPLATE_NAME];
    [openUrlbuilder addArgument:CLTAP_OPEN_URL_ACTION_KEY withString:@""];
    CTSystemAppFunctionPresenter *presenter = [[CTSystemAppFunctionPresenter alloc] initWithSystemTemplateActionHandler:systemTemplateActionHandler];
    [openUrlbuilder setPresenter:presenter];

    CTCustomTemplate *openUrlTemplate = [openUrlbuilder build];
    return openUrlTemplate;
}

@end
