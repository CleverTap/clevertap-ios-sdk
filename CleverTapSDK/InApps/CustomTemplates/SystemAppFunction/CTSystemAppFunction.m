//
//  CTSystemAppFunction.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 19/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSystemAppFunction.h"
#import "CTConstants.h"
#import "CTPushPermissionSystemAppFunction.h"

@interface CTSystemAppFunction ()

@property (nonatomic, strong) CTSystemTemplateActionHandler *systemTemplateActionHandler;

@end

@implementation CTSystemAppFunction

- (instancetype)initWithSystemTemplateActionHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler {
    self = [super init];
    if (self) {
        self.systemTemplateActionHandler = systemTemplateActionHandler;
    }
    return self;
}

- (NSDictionary<NSString *, CTCustomTemplate *> *)getSystemAppFunctions {
    NSMutableDictionary *systemAppFunctions = [NSMutableDictionary new];
    systemAppFunctions[CLTAP_PUSH_PERMISSION_TEMPLATE_NAME] = [CTPushPermissionSystemAppFunction buildTemplateWithHanlder:self.systemTemplateActionHandler];
    return systemAppFunctions;
}

@end
