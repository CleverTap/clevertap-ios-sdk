//
//  CTEncryptionTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 28/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTap.h"
#import "CTEncryptionManager.h"
#import "CTConstants.h"

@interface CTEncryptionTests : XCTestCase
@end

@implementation CTEncryptionTests

- (void)testInAppEncryption {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSData *inAppData = [NSData dataWithContentsOfFile:[bundle pathForResource:@"inapp_interstitial" ofType:@"json"]];
    NSError *error;
    NSArray *objectToEncrypt = [NSJSONSerialization JSONObjectWithData:inAppData options:kNilOptions error:&error];
    CTEncryptionManager *ctAES = [[CTEncryptionManager alloc] initWithAccountID:@"test"];
    
    NSString *encryptedString = [ctAES encryptObject:objectToEncrypt];
    NSArray *decryptedObject = [ctAES decryptObject:encryptedString];
    XCTAssertEqualObjects(objectToEncrypt, decryptedObject);
}

- (void)testCGKEncryption {
    // Create a dictionary representing the CGK data structure
    // Format: Email_value -> GUID or Identity_value -> GUID
    NSDictionary *originalData = @{
        @"Email_kush@gmail.com": @"550e8400-e29b-41d4-a716-446655440000",
        @"Identity_12345": @"7c9e6679-7425-40de-944b-e07fc1f90ae7"
    };
    
    // Initialize the encryption manager with explicit encryption level
    CTEncryptionManager *ctAES = [[CTEncryptionManager alloc] initWithAccountID:@"test" encryptionLevel:CleverTapEncryptionMedium];
    
    // Create a new dictionary where we encrypt just the value part in the keys
    NSMutableDictionary *encryptedCGK = [NSMutableDictionary dictionary];
    for (NSString *key in originalData) {
        // Extract the prefix and the value part from the key
        NSArray *keyComponents = [key componentsSeparatedByString:@"_"];
        NSString *prefix = keyComponents[0]; // "Email" or "Identity"
        NSString *valueToEncrypt = keyComponents[1]; // "kush@gmail.com" or "12345"
        
        // Encrypt the value part
        NSString *encryptedValue = [ctAES encryptString:valueToEncrypt];
        
        // Create new key with encrypted value
        NSString *newKey = [NSString stringWithFormat:@"%@_%@", prefix, encryptedValue];
        
        // Store with same GUID value
        encryptedCGK[newKey] = originalData[key];
    }
    
    // Verify actual encryption occurred by checking if keys changed
    BOOL encryptionOccurred = NO;
    for (NSString *originalKey in originalData) {
        BOOL keyFound = [encryptedCGK objectForKey:originalKey] != nil;
        if (!keyFound) {
            encryptionOccurred = YES;
            break;
        }
    }
    XCTAssertTrue(encryptionOccurred, @"Encryption did not occur. Keys remained unchanged.");
    
    // Verify keys are different but values (GUIDs) remain the same
    XCTAssertEqual(originalData.count, encryptedCGK.count);
    
    // The values (GUIDs) should be identical when sorted
    NSArray *originalValues = [originalData.allValues sortedArrayUsingSelector:@selector(compare:)];
    NSArray *encryptedValues = [encryptedCGK.allValues sortedArrayUsingSelector:@selector(compare:)];
    XCTAssertEqualObjects(originalValues, encryptedValues);
    
    // Now test decryption to ensure we can recover the original keys
    NSMutableDictionary *decryptedCGK = [NSMutableDictionary dictionary];
    for (NSString *encryptedKey in encryptedCGK) {
        // Extract the prefix and the encrypted value part
        NSArray *keyComponents = [encryptedKey componentsSeparatedByString:@"_"];
        NSString *prefix = keyComponents[0]; // "Email" or "Identity"
        NSString *encryptedPortion = keyComponents[1]; // Encrypted value
        
        // Decrypt the value part
        NSString *decryptedValue = [ctAES decryptString:encryptedPortion];
        
        // Reconstruct the original key
        NSString *originalKey = [NSString stringWithFormat:@"%@_%@", prefix, decryptedValue];
        
        // Store with same GUID value
        decryptedCGK[originalKey] = encryptedCGK[encryptedKey];
    }
    
    // Verify the original and decrypted dictionaries match
    XCTAssertEqualObjects(originalData, decryptedCGK);
}

- (void)testUserDataEncryption {
    // Define a sample user profile with PII data to test encryption
    NSDictionary *userProfile = @{
        @"Identity": @"user123",
        @"Email": @"user@example.com",
        @"Phone": @"+19876543210",
        @"Name": @"John Doe",
        // Non-PII data that shouldn't be encrypted
        @"Age": @30,
        @"Country": @"USA",
        @"Language": @"English",
        @"LastVisit": @"2023-04-23T12:34:56Z"
    };
    
    // Initialize the encryption manager with encryption level
    CTEncryptionManager *ctAES = [[CTEncryptionManager alloc] initWithAccountID:@"test" encryptionLevel:CleverTapEncryptionMedium];
    
    // Encrypt the user profile
    NSMutableDictionary *encryptedProfile = [NSMutableDictionary dictionaryWithDictionary:userProfile];
    NSArray *piiKeys = CLTAP_ENCRYPTION_PII_DATA; // This should be defined in your code as (@[@"Identity", @"Email", @"Phone", @"Name"])
    
    for (NSString *key in piiKeys) {
        if (userProfile[key]) {
            NSString *valueToEncrypt = [userProfile[key] description];
            NSString *encryptedValue = [ctAES encryptString:valueToEncrypt];
            encryptedProfile[key] = encryptedValue;
        }
    }
    
    // Verify that PII data was encrypted
    for (NSString *piiKey in piiKeys) {
        if (userProfile[piiKey]) {
            XCTAssertNotEqualObjects(userProfile[piiKey], encryptedProfile[piiKey],
                                     @"PII field %@ was not encrypted", piiKey);
        }
    }
    
    // Verify that non-PII data remained unchanged
    NSMutableSet *allKeys = [NSMutableSet setWithArray:userProfile.allKeys];
    [allKeys minusSet:[NSSet setWithArray:piiKeys]];
    
    for (NSString *nonPiiKey in allKeys) {
        XCTAssertEqualObjects(userProfile[nonPiiKey], encryptedProfile[nonPiiKey],
                              @"Non-PII field %@ should not be encrypted", nonPiiKey);
    }
    
    // Now decrypt the profile and verify it matches the original
    NSMutableDictionary *decryptedProfile = [NSMutableDictionary dictionaryWithDictionary:encryptedProfile];
    
    for (NSString *key in piiKeys) {
        if (encryptedProfile[key]) {
            NSString *encryptedValue = [encryptedProfile[key] description];
            NSString *decryptedValue = [ctAES decryptString:encryptedValue];
            decryptedProfile[key] = decryptedValue;
        }
    }
    
    // Verify that the decrypted profile matches the original
    XCTAssertEqualObjects(userProfile, decryptedProfile, @"Decrypted profile should match original profile");
    
    // Test boundary conditions
    
    // 1. Empty profile
    NSDictionary *emptyProfile = @{};
    NSMutableDictionary *encryptedEmptyProfile = [NSMutableDictionary dictionary];
    for (NSString *key in piiKeys) {
        if (emptyProfile[key]) {
            NSString *valueToEncrypt = [emptyProfile[key] description];
            NSString *encryptedValue = [ctAES encryptString:valueToEncrypt];
            encryptedEmptyProfile[key] = encryptedValue;
        }
    }
    XCTAssertEqual(encryptedEmptyProfile.count, 0, @"Empty profile should remain empty after encryption");
    
    // 2. Profile with nil values
    NSDictionary *profileWithNil = @{
        @"Identity": [NSNull null],
        @"Email": @"user@example.com",
    };
    
    NSMutableDictionary *encryptedProfileWithNil = [NSMutableDictionary dictionaryWithDictionary:profileWithNil];
    for (NSString *key in piiKeys) {
        if (profileWithNil[key] && ![profileWithNil[key] isEqual:[NSNull null]]) {
            NSString *valueToEncrypt = [profileWithNil[key] description];
            NSString *encryptedValue = [ctAES encryptString:valueToEncrypt];
            encryptedProfileWithNil[key] = encryptedValue;
        }
    }
    
    XCTAssertEqualObjects(profileWithNil[@"Identity"], encryptedProfileWithNil[@"Identity"],
                         @"Null values should not be encrypted");
    XCTAssertNotEqualObjects(profileWithNil[@"Email"], encryptedProfileWithNil[@"Email"],
                            @"Non-null values should be encrypted");
    
    // 3. Profile with empty strings
    NSDictionary *profileWithEmpty = @{
        @"Identity": @"",
        @"Email": @"user@example.com",
    };
    
    NSMutableDictionary *encryptedProfileWithEmpty = [NSMutableDictionary dictionaryWithDictionary:profileWithEmpty];
    for (NSString *key in piiKeys) {
        if (profileWithEmpty[key]) {
            NSString *valueToEncrypt = [profileWithEmpty[key] description];
            NSString *encryptedValue = [ctAES encryptString:valueToEncrypt];
            encryptedProfileWithEmpty[key] = encryptedValue;
        }
    }
    
    // Test depends on how your encryptString method handles empty strings
    // Assuming it returns empty strings as is (similar to nil), adjust test accordingly
    if ([ctAES encryptString:@""].length == 0) {
        XCTAssertEqualObjects(profileWithEmpty[@"Identity"], encryptedProfileWithEmpty[@"Identity"],
                             @"Empty strings should not be encrypted");
    } else {
        XCTAssertNotEqualObjects(profileWithEmpty[@"Identity"], encryptedProfileWithEmpty[@"Identity"],
                                @"Empty strings should be encrypted");
    }
    
    XCTAssertNotEqualObjects(profileWithEmpty[@"Email"], encryptedProfileWithEmpty[@"Email"],
                            @"Non-empty values should be encrypted");
}

@end
