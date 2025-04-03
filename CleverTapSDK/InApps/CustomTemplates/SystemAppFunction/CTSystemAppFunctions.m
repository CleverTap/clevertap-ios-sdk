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

@interface CTSystemAppFunctions ()

@property (nonatomic, strong) CTSystemTemplateActionHandler *systemTemplateActionHandler;

@end

@implementation CTSystemAppFunctions

- (instancetype)initWithSystemTemplateActionHandler:(CTSystemTemplateActionHandler *)systemTemplateActionHandler {
    self = [super init];
    if (self) {
        self.systemTemplateActionHandler = systemTemplateActionHandler;
    }
    return self;
}

- (NSDictionary<NSString *, CTCustomTemplate *> *)systemAppFunctions {
    NSMutableDictionary *systemAppFunctions = [NSMutableDictionary new];
    systemAppFunctions[CLTAP_PUSH_PERMISSION_TEMPLATE_NAME] = [CTPushPermissionSystemAppFunction buildTemplateWithHanlder:self.systemTemplateActionHandler];
    return systemAppFunctions;
}

@end
