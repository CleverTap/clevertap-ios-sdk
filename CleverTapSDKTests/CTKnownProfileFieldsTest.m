//
//  CTKnownProfileFieldsTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTKnownProfileFields.h"

@interface CTKnownProfileFieldsTest : XCTestCase
@end

@implementation CTKnownProfileFieldsTest

- (void)test_getKnownFieldForKey_Name {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Name"], Name);
}

- (void)test_getKnownFieldForKey_Email {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Email"], Email);
}

- (void)test_getKnownFieldForKey_Education {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Education"], Education);
}

- (void)test_getKnownFieldForKey_Married {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Married"], Married);
}

- (void)test_getKnownFieldForKey_DOB {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"DOB"], DOB);
}

- (void)test_getKnownFieldForKey_Birthday {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Birthday"], Birthday);
}

- (void)test_getKnownFieldForKey_Employed {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Employed"], Employed);
}

- (void)test_getKnownFieldForKey_Gender {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Gender"], Gender);
}

- (void)test_getKnownFieldForKey_Phone {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Phone"], Phone);
}

- (void)test_getKnownFieldForKey_Age {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Age"], Age);
}

- (void)test_getKnownFieldForKey_unknownKey {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"Unknown"], UNKNOWN);
}

- (void)test_getKnownFieldForKey_emptyString {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@""], UNKNOWN);
}

- (void)test_getKnownFieldForKey_nilKey {
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:nil], UNKNOWN);
}

- (void)test_getKnownFieldForKey_caseSensitive {
    // Keys are case-sensitive; lowercase should not match known fields
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"name"], UNKNOWN);
    XCTAssertEqual([CTKnownProfileFields getKnownFieldIfPossibleForKey:@"email"], UNKNOWN);
}

@end
