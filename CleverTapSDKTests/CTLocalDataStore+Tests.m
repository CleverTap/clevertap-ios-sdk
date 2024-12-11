//
//  CTLocalDataStore+Tests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 11/12/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTLocalDataStore+Tests.h"
#import <objc/runtime.h>

@implementation CTLocalDataStore (Tests)

- (dispatch_queue_t)backgroundQueue {
    Ivar ivar = class_getInstanceVariable([self class], "_backgroundQueue");
    return object_getIvar(self, ivar);
}

@end
