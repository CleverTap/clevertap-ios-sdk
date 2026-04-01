//
//  CTSwizzleTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTSwizzle.h"

// Helper class for instance method swizzle tests
@interface CTSwizzleInstanceTarget : NSObject
- (NSString *)methodA;
- (NSString *)methodB;
@end

@implementation CTSwizzleInstanceTarget
- (NSString *)methodA { return @"A"; }
- (NSString *)methodB { return @"B"; }
@end

// Helper class for class method swizzle tests
@interface CTSwizzleClassTarget : NSObject
+ (NSString *)classMethodA;
+ (NSString *)classMethodB;
@end

@implementation CTSwizzleClassTarget
+ (NSString *)classMethodA { return @"classA"; }
+ (NSString *)classMethodB { return @"classB"; }
@end

// Helper class for block swizzle test (separate to avoid state pollution)
@interface CTSwizzleBlockTarget : NSObject
- (NSString *)blockableMethod;
@end

@implementation CTSwizzleBlockTarget
- (NSString *)blockableMethod { return @"original"; }
@end

@interface CTSwizzleTest : XCTestCase
@property (nonatomic, strong) CTSwizzleInstanceTarget *instanceTarget;
@end

@implementation CTSwizzleTest

- (void)setUp {
    [super setUp];
    self.instanceTarget = [CTSwizzleInstanceTarget new];
}

- (void)tearDown {
    self.instanceTarget = nil;
    [super tearDown];
}

#pragma mark - ct_swizzleMethod:withMethod:error:

- (void)test_swizzleMethod_returnsYes_whenBothSelectorsExist {
    NSError *error = nil;
    BOOL result = [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA)
                                                 withMethod:@selector(methodB)
                                                      error:&error];
    // Restore immediately
    [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA) withMethod:@selector(methodB) error:nil];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)test_swizzleMethod_swapsImplementations {
    [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA) withMethod:@selector(methodB) error:nil];
    NSString *result = [self.instanceTarget methodA];
    // Restore before asserting so tearDown isn't affected
    [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA) withMethod:@selector(methodB) error:nil];
    XCTAssertEqualObjects(result, @"B");
}

- (void)test_swizzleMethod_doubleSwizzle_restoresOriginalBehavior {
    [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA) withMethod:@selector(methodB) error:nil];
    [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA) withMethod:@selector(methodB) error:nil];
    NSString *result = [self.instanceTarget methodA];
    XCTAssertEqualObjects(result, @"A");
}

- (void)test_swizzleMethod_originalNotFound_returnsNO_setsError {
    NSError *error = nil;
    SEL missing = NSSelectorFromString(@"nonExistentSwizzleMethod");
    BOOL result = [CTSwizzleInstanceTarget ct_swizzleMethod:missing
                                                 withMethod:@selector(methodB)
                                                      error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

- (void)test_swizzleMethod_alternateNotFound_returnsNO_setsError {
    NSError *error = nil;
    SEL missing = NSSelectorFromString(@"nonExistentSwizzleMethodAlt");
    BOOL result = [CTSwizzleInstanceTarget ct_swizzleMethod:@selector(methodA)
                                                 withMethod:missing
                                                      error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

#pragma mark - ct_swizzleClassMethod:withClassMethod:error:

- (void)test_swizzleClassMethod_swapsImplementations {
    [CTSwizzleClassTarget ct_swizzleClassMethod:@selector(classMethodA)
                                withClassMethod:@selector(classMethodB)
                                          error:nil];
    NSString *result = [CTSwizzleClassTarget classMethodA];
    // Restore
    [CTSwizzleClassTarget ct_swizzleClassMethod:@selector(classMethodA)
                                withClassMethod:@selector(classMethodB)
                                          error:nil];
    XCTAssertEqualObjects(result, @"classB");
}

#pragma mark - ct_swizzleMethod:withBlock:error:

- (void)test_swizzleMethodWithBlock_returnsNonNilInvocation {
    NSInvocation *invocation = [CTSwizzleBlockTarget ct_swizzleMethod:@selector(blockableMethod)
                                                            withBlock:^(id obj) {}
                                                               error:nil];
    XCTAssertNotNil(invocation);
}

- (void)test_swizzleMethodWithBlock_blockIsInvokedOnMethodCall {
    __block BOOL blockCalled = NO;
    [CTSwizzleBlockTarget ct_swizzleMethod:@selector(blockableMethod)
                                 withBlock:^(id obj) { blockCalled = YES; }
                                     error:nil];
    CTSwizzleBlockTarget *target = [CTSwizzleBlockTarget new];
    [target blockableMethod];
    XCTAssertTrue(blockCalled);
}

@end
