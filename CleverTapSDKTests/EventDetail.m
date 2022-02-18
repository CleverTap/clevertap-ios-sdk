//
//  EventDetail.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 16/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "EventDetail.h"

@implementation EventDetail

- (instancetype)initWithEvent:(NSDictionary*)event name:(NSString*)name
{
    self = [super init];
    if (self) {
        self.event = event;
        self.stubName = name;
    }
    return self;
}
@end
