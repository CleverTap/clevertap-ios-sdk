//
//  CTDeviceInfoTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 17/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UserNotifications/UserNotifications.h>
#import <OCMock/OCMock.h>
#import "CTDeviceInfo.h"
#import "CTUIUtils.h"
#import "CleverTapInstanceConfig.h"

@interface CTDeviceInfo (Tests)
+ (NSString *)textSizeForContentSizeCategory:(UIContentSizeCategory)category;
+ (NSNumber *)darkModeForInterfaceStyle:(UIUserInterfaceStyle)style;
+ (NSNumber *)batteryBandForLevel:(float)level;
+ (NSNumber *)ramTierForBytes:(unsigned long long)bytes;
- (void)handleReachabilityUpdate:(SCNetworkReachabilityFlags)flags;
@end

@interface CTDeviceInfoTest : XCTestCase
@property (nonatomic, strong) CTDeviceInfo *classObject;
@end

@implementation CTDeviceInfoTest

- (void)setUp {
    self.classObject = [[CTDeviceInfo alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_initWithConfig{
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    _classObject = [_classObject initWithConfig:config andCleverTapID:@"testAccount"];
    
    XCTAssertNotNil([_classObject deviceId]);
}

- (void)test_forceUpdateDeviceID{
    [_classObject forceUpdateDeviceID:@"test_device_id"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertEqualObjects([_classObject deviceId], @"test_device_id");
}

- (void)test_forceNewDeviceID{
    [_classObject forceNewDeviceID];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertEqual([[[_classObject deviceId] componentsSeparatedByString:@"-"] count], 2);
    XCTAssertTrue([[_classObject deviceId] hasPrefix:@"-"]);
}

- (void)test_forceUpdateCustomDeviceID{
    [_classObject forceUpdateCustomDeviceID:@"test_custom_ctID"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertEqualObjects([_classObject deviceId], @"-htest_custom_ctID");
    XCTAssertTrue([[_classObject deviceId] hasPrefix:@"-h"]);
}

- (void)test_forceUpdateCustomDeviceID_withInvalidCTid{
    [_classObject forceUpdateCustomDeviceID:@"#test_custom_ctID"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertNotNil([_classObject fallbackDeviceId]);
    XCTAssertEqualObjects([_classObject deviceId], [_classObject fallbackDeviceId]);
}

- (void)test_isErrorDeviceID_withErrorID{
    [_classObject forceUpdateDeviceID:@"-itest_error_device_id"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertTrue([_classObject isErrorDeviceID]);
}

- (void)test_isErrorDeviceID_withoutErrorID{
    [_classObject forceUpdateDeviceID:@"test_error_device_id"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertFalse([_classObject isErrorDeviceID]);
}

- (void)test_textSizeForContentSizeCategory{
    XCTAssertEqualObjects([CTDeviceInfo textSizeForContentSizeCategory:UIContentSizeCategoryExtraSmall], @"xs");
    XCTAssertEqualObjects([CTDeviceInfo textSizeForContentSizeCategory:UIContentSizeCategoryLarge], @"l");
    XCTAssertEqualObjects([CTDeviceInfo textSizeForContentSizeCategory:UIContentSizeCategoryExtraExtraExtraLarge], @"xxxl");
    XCTAssertEqualObjects([CTDeviceInfo textSizeForContentSizeCategory:UIContentSizeCategoryAccessibilityMedium], @"ax1");
    XCTAssertEqualObjects([CTDeviceInfo textSizeForContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge], @"ax5");
    XCTAssertNil([CTDeviceInfo textSizeForContentSizeCategory:UIContentSizeCategoryUnspecified]);
    XCTAssertNil([CTDeviceInfo textSizeForContentSizeCategory:nil]);
}

- (void)test_refreshDisplaySettings_fromBackgroundQueue_readsOnMainThread{
    // Stub the key window so the test doesn't depend on the host's windows.
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    __block BOOL readOnMainThread = NO;
    id mockUIUtils = OCMClassMock([CTUIUtils class]);
    [self addTeardownBlock:^{
        [mockUIUtils stopMocking];
    }];
    OCMStub([mockUIUtils getKeyWindow]).andDo(^(NSInvocation *invocation) {
        readOnMainThread = [NSThread isMainThread];
        __unsafe_unretained UIWindow *keyWindow = window;
        [invocation setReturnValue:&keyWindow];
    });

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self.classObject refreshDisplaySettings];
    });
    NSPredicate *refreshed = [NSPredicate predicateWithBlock:^BOOL(CTDeviceInfo *deviceInfo, NSDictionary *bindings) {
        return deviceInfo.reduceMotion != nil;
    }];
    [self waitForExpectations:@[[self expectationForPredicate:refreshed evaluatedWithObject:_classObject handler:nil]] timeout:2.0];

    XCTAssertTrue(readOnMainThread);
    XCTAssertEqualObjects([_classObject darkMode], @YES);
    XCTAssertNotNil([_classObject textSize]);
}

- (void)test_batteryBandForLevel_roundsDownToTenPercentSteps{
    XCTAssertEqualObjects([CTDeviceInfo batteryBandForLevel:0.47f], @40);
    XCTAssertEqualObjects([CTDeviceInfo batteryBandForLevel:0.0f], @0);
    XCTAssertEqualObjects([CTDeviceInfo batteryBandForLevel:0.09f], @0);
    XCTAssertEqualObjects([CTDeviceInfo batteryBandForLevel:0.999f], @100);
    XCTAssertEqualObjects([CTDeviceInfo batteryBandForLevel:1.0f], @100);
    XCTAssertNil([CTDeviceInfo batteryBandForLevel:-1.0f]);
}

- (void)test_ramTierForBytes_roundsUpToTheNextTier{
    unsigned long long gigabyte = 1024ULL * 1024ULL * 1024ULL;
    XCTAssertEqualObjects([CTDeviceInfo ramTierForBytes:gigabyte / 2], @1);
    XCTAssertEqualObjects([CTDeviceInfo ramTierForBytes:3 * gigabyte], @3);
    XCTAssertEqualObjects([CTDeviceInfo ramTierForBytes:(unsigned long long)(5.6 * gigabyte)], @6);
    XCTAssertEqualObjects([CTDeviceInfo ramTierForBytes:(unsigned long long)(7.5 * gigabyte)], @8);
    XCTAssertEqualObjects([CTDeviceInfo ramTierForBytes:(unsigned long long)(11.2 * gigabyte)], @12);
    XCTAssertEqualObjects([CTDeviceInfo ramTierForBytes:24 * gigabyte], @16);
}

- (void)test_ramTierAndCpuCount_comeFromProcessInfo{
    XCTAssertEqualObjects([_classObject cpuCount], @([NSProcessInfo processInfo].processorCount));
    XCTAssertEqualObjects([_classObject ramTier], [CTDeviceInfo ramTierForBytes:[NSProcessInfo processInfo].physicalMemory]);
}

- (void)test_refreshDisplaySettings_readsBoldText{
    [_classObject refreshDisplaySettings];

    XCTAssertEqualObjects([_classObject boldText], @(UIAccessibilityIsBoldTextEnabled()));
    XCTAssertEqual(CFGetTypeID((__bridge CFTypeRef)[_classObject boldText]), CFBooleanGetTypeID());
}

// The simulator's battery is always unknown, so these mock the device.
- (void)test_refreshDisplaySettings_leavesBatteryOutAndNeverTurnsOnMonitoring{
    id device = OCMClassMock([UIDevice class]);
    id deviceClass = OCMClassMock([UIDevice class]);
    [self addTeardownBlock:^{
        [deviceClass stopMocking];
    }];
    OCMStub([deviceClass currentDevice]).andReturn(device);
    OCMStub([device isBatteryMonitoringEnabled]).andReturn(NO);
    OCMReject([device setBatteryMonitoringEnabled:YES]);

    [_classObject refreshDisplaySettings];

    XCTAssertNil([_classObject batteryLevelBand]);
    XCTAssertNil([_classObject charging]);
    OCMVerifyAll(device);
}

- (void)test_refreshDisplaySettings_readsBatteryWhenTheAppMonitorsIt{
    id device = OCMClassMock([UIDevice class]);
    id deviceClass = OCMClassMock([UIDevice class]);
    [self addTeardownBlock:^{
        [deviceClass stopMocking];
    }];
    OCMStub([deviceClass currentDevice]).andReturn(device);
    OCMStub([device isBatteryMonitoringEnabled]).andReturn(YES);
    OCMStub([device batteryLevel]).andReturn(0.47f);
    OCMStub([device batteryState]).andReturn(UIDeviceBatteryStateCharging);

    [_classObject refreshDisplaySettings];

    XCTAssertEqualObjects([_classObject batteryLevelBand], @40);
    XCTAssertEqualObjects([_classObject charging], @YES);
}

- (void)test_darkModeForInterfaceStyle{
    NSNumber *dark = [CTDeviceInfo darkModeForInterfaceStyle:UIUserInterfaceStyleDark];
    NSNumber *light = [CTDeviceInfo darkModeForInterfaceStyle:UIUserInterfaceStyleLight];
    XCTAssertEqualObjects(dark, @YES);
    XCTAssertEqualObjects(light, @NO);
    XCTAssertNil([CTDeviceInfo darkModeForInterfaceStyle:UIUserInterfaceStyleUnspecified]);

    // JSON writes only CFBoolean numbers as true/false.
    XCTAssertEqual(CFGetTypeID((__bridge CFTypeRef)dark), CFBooleanGetTypeID());
    XCTAssertEqual(CFGetTypeID((__bridge CFTypeRef)light), CFBooleanGetTypeID());
}

- (void)test_deviceType_matchesIdiom{
    NSNumber *expected = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @2 : @1;
    XCTAssertEqualObjects([_classObject deviceType], expected);
}

- (void)test_handleReachabilityUpdate_setsWifiAndOnline{
    [_classObject handleReachabilityUpdate:kSCNetworkReachabilityFlagsReachable];
    XCTAssertTrue([_classObject wifi]);
    XCTAssertTrue([_classObject isOnline]);

    [_classObject handleReachabilityUpdate:kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN];
    XCTAssertFalse([_classObject wifi]);
    XCTAssertTrue([_classObject isOnline]);

    [_classObject handleReachabilityUpdate:kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsConnectionRequired];
    XCTAssertTrue([_classObject wifi]);
    XCTAssertFalse([_classObject isOnline]);

    [_classObject handleReachabilityUpdate:0];
    XCTAssertFalse([_classObject wifi]);
    XCTAssertFalse([_classObject isOnline]);
}

- (void)test_reachabilityState_isPerInstance{
    CTDeviceInfo *other = [[CTDeviceInfo alloc] init];
    [_classObject handleReachabilityUpdate:kSCNetworkReachabilityFlagsReachable];
    [other handleReachabilityUpdate:0];

    XCTAssertTrue([_classObject wifi]);
    XCTAssertTrue([_classObject isOnline]);
    XCTAssertFalse([other wifi]);
    XCTAssertFalse([other isOnline]);
}

- (void)test_dealloc_withReachability_doesNotCrash{
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    @autoreleasepool {
        CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:nil];
        XCTAssertNotNil(deviceInfo);
    }
    // A new instance after the first is freed still gets working reachability.
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:nil];
    [deviceInfo handleReachabilityUpdate:kSCNetworkReachabilityFlagsReachable];
    XCTAssertTrue([deviceInfo isOnline]);
}

- (void)test_initWithConfig_readsOnlineStateWithoutWaitingForAChange{
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:nil];

    NSPredicate *online = [NSPredicate predicateWithBlock:^BOOL(CTDeviceInfo *info, NSDictionary *bindings) {
        return info.isOnline;
    }];
    [self waitForExpectations:@[[self expectationForPredicate:online evaluatedWithObject:deviceInfo handler:nil]] timeout:5.0];
}

- (void)test_initWithConfig_startsThePushStatusRead{
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:nil];

    NSPredicate *cached = [NSPredicate predicateWithBlock:^BOOL(CTDeviceInfo *info, NSDictionary *bindings) {
        return info.pushStatus != nil;
    }];
    [self waitForExpectations:@[[self expectationForPredicate:cached evaluatedWithObject:deviceInfo handler:nil]] timeout:2.0];
}

- (void)test_radio_updatesOnRadioAccessTechnologyChange{
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:nil];
    [deviceInfo setValue:@"stale" forKey:@"currentRadio"];
    XCTAssertEqualObjects([deviceInfo radio], @"stale");

    [[NSNotificationCenter defaultCenter] postNotificationName:CTServiceRadioAccessTechnologyDidChangeNotification object:nil];
    XCTAssertNotEqualObjects([deviceInfo radio], @"stale");
}

- (void)test_refreshPushStatus_matchesSystemStatus{
    XCTAssertNil([_classObject pushStatus]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"System push status read."];
    __block UNAuthorizationStatus systemStatus;
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        systemStatus = settings.authorizationStatus;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [_classObject refreshPushStatus];
    NSPredicate *cached = [NSPredicate predicateWithBlock:^BOOL(CTDeviceInfo *deviceInfo, NSDictionary *bindings) {
        return deviceInfo.pushStatus != nil;
    }];
    [self waitForExpectations:@[[self expectationForPredicate:cached evaluatedWithObject:_classObject handler:nil]] timeout:2.0];
    XCTAssertEqualObjects([_classObject pushStatus], @(systemStatus));
}

@end
