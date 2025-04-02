//
//  CTAppRatingSystemAppFunction.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 28/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTAppRatingSystemAppFunction.h"
#import "CTAppFunctionBuilder-Internal.h"
#import "CTSystemAppFunctionPresenter.h"
#import "CTConstants.h"

@implementation CTAppRatingSystemAppFunction

+ (CTCustomTemplate *)buildTemplateWithHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler {
    CTCustomTemplateBuilder *appRatingbuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO isSystemDefined:YES];
    [appRatingbuilder setName:CLTAP_APP_RATING_TEMPLATE_NAME];
    CTSystemAppFunctionPresenter *presenter = [[CTSystemAppFunctionPresenter alloc] initWithSystemTemplateActionHandler:systemTemplateActionHandler];
    [appRatingbuilder setPresenter:presenter];

    CTCustomTemplate *appRatingTemplate = [appRatingbuilder build];
    return appRatingTemplate;
}

@end
