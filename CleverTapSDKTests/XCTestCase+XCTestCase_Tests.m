//
//  XCTestCase+XCTestCase_Tests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 11/10/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "XCTestCase+XCTestCase_Tests.h"

@implementation XCTestCase (XCTestCase_Tests)

- (NSString*)randomString {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz";

    NSMutableString *randomString = [NSMutableString stringWithCapacity: 4];

        for (int i=0; i<4; i++) {
             [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
        }

        return randomString;
}

@end
