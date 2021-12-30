//
//  StubHelper.h
//  CleverTapSDKTestsApp
//
//  Created by Akash Malhotra on 30/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StubHelper : NSObject
//- (void)stubRequestsWithName:(NSString*)stubName fileName:(NSString*)fileName;
+ (instancetype _Nullable)sharedInstance;
- (void)stubRequests;
@end
