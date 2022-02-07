//
//  EventDetail.h
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 16/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventDetail : NSObject
@property (nonatomic, retain) NSDictionary *event;
@property (nonatomic, retain) NSString *stubName;
- (instancetype)initWithEvent:(NSDictionary*)event name:(NSString*)name;

@end
