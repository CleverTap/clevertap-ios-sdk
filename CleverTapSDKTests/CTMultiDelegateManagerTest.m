//
//  CTMultiDelegateManagerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTMultiDelegateManager.h"
#import "CTMultiDelegateManager+Tests.h"
#import "CTSwitchUserDelegate.h"
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTBatchSentDelegate.h"
#import "CTQueueType.h"

#pragma mark - Mock: CTSwitchUserDelegate

@interface CTSwitchUserDelegateMock : NSObject <CTSwitchUserDelegate>
@property (nonatomic, assign) BOOL deviceIdDidChangeCalled;
@property (nonatomic, copy) NSString *receivedDeviceId;
@property (nonatomic, assign) BOOL deviceIdWillChangeCalled;
@end

@implementation CTSwitchUserDelegateMock

- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceIdDidChangeCalled = YES;
    self.receivedDeviceId = newDeviceId;
}

- (void)deviceIdWillChange {
    self.deviceIdWillChangeCalled = YES;
}

@end

#pragma mark - Mock: CTAttachToBatchHeaderDelegate

@interface CTAttachToHeaderDelegateMock : NSObject <CTAttachToBatchHeaderDelegate>
@end

@implementation CTAttachToHeaderDelegateMock

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    return @{@"mockKey": @"mockValue"};
}

@end

#pragma mark - Mock: CTBatchSentDelegate

@interface CTBatchSentDelegateMock : NSObject <CTBatchSentDelegate>
@property (nonatomic, assign) BOOL batchSentCalled;
@end

@implementation CTBatchSentDelegateMock

- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType {
    self.batchSentCalled = YES;
}

@end

#pragma mark - Test class

@interface CTMultiDelegateManagerTest : XCTestCase

@property (nonatomic, strong) CTMultiDelegateManager *manager;

@end

@implementation CTMultiDelegateManagerTest

- (void)setUp {
    [super setUp];
    self.manager = [[CTMultiDelegateManager alloc] init];
}

- (void)tearDown {
    self.manager = nil;
    [super tearDown];
}

#pragma mark - AttachToHeader delegate

- (void)test_addAttachToHeaderDelegate_addsToHashTable {
    CTAttachToHeaderDelegateMock *mock = [[CTAttachToHeaderDelegateMock alloc] init];
    [self.manager addAttachToHeaderDelegate:mock];
    XCTAssertTrue([self.manager.attachToHeaderDelegates containsObject:mock]);
}

- (void)test_removeAttachToHeaderDelegate_removesFromHashTable {
    CTAttachToHeaderDelegateMock *mock = [[CTAttachToHeaderDelegateMock alloc] init];
    [self.manager addAttachToHeaderDelegate:mock];
    [self.manager removeAttachToHeaderDelegate:mock];
    XCTAssertFalse([self.manager.attachToHeaderDelegates containsObject:mock]);
}

#pragma mark - SwitchUser delegate

- (void)test_addSwitchUserDelegate_addsToHashTable {
    CTSwitchUserDelegateMock *mock = [[CTSwitchUserDelegateMock alloc] init];
    [self.manager addSwitchUserDelegate:mock];
    XCTAssertTrue([self.manager.switchUserDelegates containsObject:mock]);
}

- (void)test_removeSwitchUserDelegate_removesFromHashTable {
    CTSwitchUserDelegateMock *mock = [[CTSwitchUserDelegateMock alloc] init];
    [self.manager addSwitchUserDelegate:mock];
    [self.manager removeSwitchUserDelegate:mock];
    XCTAssertFalse([self.manager.switchUserDelegates containsObject:mock]);
}

- (void)test_notifyDeviceIdDidChange_callsDelegate {
    CTSwitchUserDelegateMock *mock = [[CTSwitchUserDelegateMock alloc] init];
    [self.manager addSwitchUserDelegate:mock];
    [self.manager notifyDelegatesDeviceIdDidChange:@"newDeviceId123"];
    XCTAssertTrue(mock.deviceIdDidChangeCalled);
    XCTAssertEqualObjects(mock.receivedDeviceId, @"newDeviceId123");
}

- (void)test_notifyDeviceIdWillChange_callsDelegate {
    CTSwitchUserDelegateMock *mock = [[CTSwitchUserDelegateMock alloc] init];
    [self.manager addSwitchUserDelegate:mock];
    [self.manager notifyDelegatesDeviceIdWillChange];
    XCTAssertTrue(mock.deviceIdWillChangeCalled);
}

- (void)test_notifyDeviceIdDidChange_afterRemoval_doesNotCall {
    CTSwitchUserDelegateMock *mock = [[CTSwitchUserDelegateMock alloc] init];
    [self.manager addSwitchUserDelegate:mock];
    [self.manager removeSwitchUserDelegate:mock];
    [self.manager notifyDelegatesDeviceIdDidChange:@"deviceId"];
    XCTAssertFalse(mock.deviceIdDidChangeCalled);
}

#pragma mark - BatchSent delegate

- (void)test_addBatchSentDelegate_addsToHashTable {
    CTBatchSentDelegateMock *mock = [[CTBatchSentDelegateMock alloc] init];
    [self.manager addBatchSentDelegate:mock];
    XCTAssertTrue([self.manager.batchSentDelegates containsObject:mock]);
}

- (void)test_removeBatchSentDelegate_removesFromHashTable {
    CTBatchSentDelegateMock *mock = [[CTBatchSentDelegateMock alloc] init];
    [self.manager addBatchSentDelegate:mock];
    [self.manager removeBatchSentDelegate:mock];
    XCTAssertFalse([self.manager.batchSentDelegates containsObject:mock]);
}

@end
