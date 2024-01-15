//
//  CTEncryptionTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 28/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTap.h"
#import "CTAES.h"

@interface CTEncryptionTests : XCTestCase
@end

@implementation CTEncryptionTests

- (void)testInAppEncryption {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSData *inAppData = [NSData dataWithContentsOfFile:[bundle pathForResource:@"inapp_interstitial" ofType:@"json"]];
    NSError *error;
    NSArray *objectToEncrypt = [NSJSONSerialization JSONObjectWithData:inAppData options:kNilOptions error:&error];
    CTAES *ctAES = [[CTAES alloc] initWithAccountID:@"test"];
    
    NSString *encryptedString = [ctAES getEncryptedBase64String:objectToEncrypt];
    NSArray *decryptedObject = [ctAES getDecryptedObject:encryptedString];
    XCTAssertEqualObjects(objectToEncrypt, decryptedObject);
}

@end
