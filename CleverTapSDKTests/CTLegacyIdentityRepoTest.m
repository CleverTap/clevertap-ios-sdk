//
//  CTLegacyIdentityRepoTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTLegacyIdentityRepo.h"
#import "CTConstants.h"

@interface CTLegacyIdentityRepoTest : XCTestCase
@property (nonatomic, strong) CTLegacyIdentityRepo *repo;
@end

@implementation CTLegacyIdentityRepoTest

- (void)setUp {
    [super setUp];
    self.repo = [[CTLegacyIdentityRepo alloc] init];
}

- (void)tearDown {
    self.repo = nil;
    [super tearDown];
}

- (void)test_init_setsIdentitiesFromConstant {
    NSArray *identities = [self.repo getIdentities];
    XCTAssertNotNil(identities);
    XCTAssertEqual(identities.count, 2u);
    XCTAssertTrue([identities containsObject:@"Identity"]);
    XCTAssertTrue([identities containsObject:@"Email"]);
}

- (void)test_isIdentity_identityKey_returnsTrue {
    XCTAssertTrue([self.repo isIdentity:@"Identity"]);
}

- (void)test_isIdentity_emailKey_returnsTrue {
    XCTAssertTrue([self.repo isIdentity:@"Email"]);
}

- (void)test_isIdentity_unknownKey_returnsFalse {
    XCTAssertFalse([self.repo isIdentity:@"Unknown"]);
}

- (void)test_isIdentity_emptyString_returnsFalse {
    XCTAssertFalse([self.repo isIdentity:@""]);
}

@end
