//
//  CleverTapInboxStyleConfigTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "CleverTap+Inbox.h"

@interface CleverTapInboxStyleConfigTest : XCTestCase
@property (nonatomic, strong) CleverTapInboxStyleConfig *config;
@end

@implementation CleverTapInboxStyleConfigTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInboxStyleConfig alloc] init];
    self.config.title = @"Inbox";
    self.config.backgroundColor = [UIColor redColor];
    NSArray *tags = @[@"sale", @"promo"];
    self.config.messageTags = tags;
    self.config.navigationBarTintColor = [UIColor blueColor];
    self.config.navigationTintColor = [UIColor greenColor];
    self.config.tabSelectedBgColor = [UIColor yellowColor];
    self.config.tabSelectedTextColor = [UIColor blackColor];
    self.config.tabUnSelectedTextColor = [UIColor grayColor];
    self.config.noMessageViewText = @"No messages";
    self.config.noMessageViewTextColor = [UIColor darkGrayColor];
    self.config.firstTabTitle = @"All";
}

- (void)tearDown {
    self.config = nil;
    [super tearDown];
}

#pragma mark - copyWithZone: copies all properties

- (void)test_copy_isNotSameInstance {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertNotEqual(self.config, copy);
}

- (void)test_copy_copiesTitle {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.title, @"Inbox");
}

- (void)test_copy_copiesBackgroundColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.backgroundColor, [UIColor redColor]);
}

- (void)test_copy_copiesMessageTags {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    NSArray *expectedTags = @[@"sale", @"promo"];
    XCTAssertEqualObjects(copy.messageTags, expectedTags);
}

- (void)test_copy_copiesNavigationBarTintColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.navigationBarTintColor, [UIColor blueColor]);
}

- (void)test_copy_copiesNavigationTintColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.navigationTintColor, [UIColor greenColor]);
}

- (void)test_copy_copiesTabSelectedBgColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.tabSelectedBgColor, [UIColor yellowColor]);
}

- (void)test_copy_copiesTabSelectedTextColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.tabSelectedTextColor, [UIColor blackColor]);
}

- (void)test_copy_copiesTabUnSelectedTextColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.tabUnSelectedTextColor, [UIColor grayColor]);
}

- (void)test_copy_copiesNoMessageViewText {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.noMessageViewText, @"No messages");
}

- (void)test_copy_copiesNoMessageViewTextColor {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.noMessageViewTextColor, [UIColor darkGrayColor]);
}

- (void)test_copy_copiesFirstTabTitle {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    XCTAssertEqualObjects(copy.firstTabTitle, @"All");
}

#pragma mark - mutation independence

- (void)test_copy_mutatingOriginalDoesNotAffectCopy {
    CleverTapInboxStyleConfig *copy = [self.config copy];
    self.config.title = @"Changed";
    XCTAssertEqualObjects(copy.title, @"Inbox");
}

#pragma mark - nil properties

- (void)test_copy_nilPropertiesAreNilInCopy {
    CleverTapInboxStyleConfig *empty = [[CleverTapInboxStyleConfig alloc] init];
    CleverTapInboxStyleConfig *copy = [empty copy];
    XCTAssertNil(copy.title);
    XCTAssertNil(copy.backgroundColor);
    XCTAssertNil(copy.messageTags);
    XCTAssertNil(copy.firstTabTitle);
}

@end
