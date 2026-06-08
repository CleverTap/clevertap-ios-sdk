//
//  CleverTapFeatureFlagsTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTapFeatureFlagsPrivate.h"

#pragma mark - Mock

@interface CTFeatureFlagsDelegateMock : NSObject <CleverTapPrivateFeatureFlagsDelegate>
@property (atomic, weak) id<CleverTapFeatureFlagsDelegate> featureFlagsDelegate;
@property (nonatomic, assign) BOOL flagValueToReturn;
@property (nonatomic, strong) id<CleverTapFeatureFlagsDelegate> capturedDelegate;
@property (nonatomic, assign) BOOL setDelegateCalled;
@end

@implementation CTFeatureFlagsDelegateMock

- (BOOL)getFeatureFlag:(NSString *)key withDefaultValue:(BOOL)defaultValue {
    return self.flagValueToReturn;
}

- (void)setFeatureFlagsDelegate:(id<CleverTapFeatureFlagsDelegate>)delegate {
    self.capturedDelegate = delegate;
    self.setDelegateCalled = YES;
    _featureFlagsDelegate = delegate;
}

@end

#pragma mark - Tests

@interface CleverTapFeatureFlagsTest : XCTestCase
@property (nonatomic, strong) CTFeatureFlagsDelegateMock *mockDelegate;
@end

@implementation CleverTapFeatureFlagsTest

- (void)setUp {
    [super setUp];
    self.mockDelegate = [[CTFeatureFlagsDelegateMock alloc] init];
}

- (void)tearDown {
    self.mockDelegate = nil;
    [super tearDown];
}

- (void)test_setDelegate_forwardsToPrivateDelegate {
    CleverTapFeatureFlags *flags = [[CleverTapFeatureFlags alloc] initWithPrivateDelegate:self.mockDelegate];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    id<CleverTapFeatureFlagsDelegate> testDelegate = (id<CleverTapFeatureFlagsDelegate>)[[NSObject alloc] init];
    flags.delegate = testDelegate;
#pragma clang diagnostic pop
    XCTAssertTrue(self.mockDelegate.setDelegateCalled);
}

- (void)test_get_withPrivateDelegate_returnsTrue {
    self.mockDelegate.flagValueToReturn = YES;
    CleverTapFeatureFlags *flags = [[CleverTapFeatureFlags alloc] initWithPrivateDelegate:self.mockDelegate];
    BOOL result = [flags get:@"featureKey" withDefaultValue:NO];
    XCTAssertTrue(result);
}

- (void)test_get_withPrivateDelegate_returnsFalse {
    self.mockDelegate.flagValueToReturn = NO;
    CleverTapFeatureFlags *flags = [[CleverTapFeatureFlags alloc] initWithPrivateDelegate:self.mockDelegate];
    BOOL result = [flags get:@"featureKey" withDefaultValue:YES];
    XCTAssertFalse(result);
}

- (void)test_get_withNilPrivateDelegate_returnsDefault {
    // privateDelegate is weak; create flags without retaining the delegate
    CleverTapFeatureFlags *flags;
    @autoreleasepool {
        CTFeatureFlagsDelegateMock *weakDelegate = [[CTFeatureFlagsDelegateMock alloc] init];
        flags = [[CleverTapFeatureFlags alloc] initWithPrivateDelegate:weakDelegate];
        // weakDelegate goes out of scope here, but flags keeps a weak ref
    }
    // privateDelegate is now nil (weakly held and released)
    BOOL result = [flags get:@"featureKey" withDefaultValue:YES];
    XCTAssertTrue(result);
}

@end
