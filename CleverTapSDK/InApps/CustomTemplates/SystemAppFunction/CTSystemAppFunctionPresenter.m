//
//  CTSystemAppFunctionPresenter.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 20/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSystemAppFunctionPresenter.h"
#import "CTConstants.h"

@interface CTSystemAppFunctionPresenter ()

@property (nonatomic, strong) CTSystemTemplateActionHandler *systemTemplateActionHandler;

@end

@implementation CTSystemAppFunctionPresenter

- (instancetype)initWithSystemTemplateActionHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler {
    self = [super init];
    if (self) {
        self.systemTemplateActionHandler = systemTemplateActionHandler;
    }
    return self;
}

- (void)onCloseClicked:(nonnull CTTemplateContext *)context { 
    CleverTapLogStaticDebug(@"System App Function dismissed: %@", [context templateName]);
}

- (void)onPresent:(nonnull CTTemplateContext *)context { 
    if ([context.templateName isEqual: CLTAP_PUSH_PERMISSION_TEMPLATE_NAME]) {
        BOOL fbSettings = [context boolNamed:CLTAP_FB_SETTINGS_KEY];
        [self.systemTemplateActionHandler promptPushPermission:fbSettings];
        [context dismissed];
    }
}

@end
