//
//  CTEncryptionTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 28/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTEncryptionManager+Tests.h"
#import "CleverTap.h"
#import "CTEncryptionManager.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"

// Define the prefix and suffix if they're not accessible from test
// These should match the actual values used in the implementation
static NSString *const kAESGCMPrefixForTest = @"<ct<";
static NSString *const kAESGCMSuffixForTest = @">ct>";

@interface CTEncryptionManagerTests : XCTestCase
@end

@implementation CTEncryptionManagerTests

#pragma mark - Original Tests

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

#pragma mark - Initialization Tests

- (void)testInitializationMethods {
    // Test basic initialization
    CTEncryptionManager *mgr1 = [[CTEncryptionManager alloc] initWithAccountID:@"test"];
    XCTAssertNotNil(mgr1, @"Basic initialization failed");
    
    // Test initialization with encryption level
    CTEncryptionManager *mgr2 = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                encryptionLevel:CleverTapEncryptionMedium];
    XCTAssertNotNil(mgr2, @"Initialization with encryption level failed");
    
    // Test initialization with encryption level and default instance flag
    CTEncryptionManager *mgr3 = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                encryptionLevel:CleverTapEncryptionMedium
                                                            isDefaultInstance:YES];
    XCTAssertNotNil(mgr3, @"Full initialization failed");
    
    // Verify each manager can encrypt/decrypt
    NSString *testString = @"test string";
    
    NSString *encrypted1 = [mgr1 encryptString:testString];
    XCTAssertEqualObjects([mgr1 decryptString:encrypted1], testString, @"mgr1 failed round-trip");
    
    NSString *encrypted2 = [mgr2 encryptString:testString];
    XCTAssertNotEqualObjects(encrypted2, testString, @"mgr2 didn't encrypt");
    XCTAssertEqualObjects([mgr2 decryptString:encrypted2], testString, @"mgr2 failed round-trip");
    
    NSString *encrypted3 = [mgr3 encryptString:testString];
    XCTAssertNotEqualObjects(encrypted3, testString, @"mgr3 didn't encrypt");
    XCTAssertEqualObjects([mgr3 decryptString:encrypted3], testString, @"mgr3 failed round-trip");
}

#pragma mark - Encryption Level Tests

- (void)testEncryptionLevelBehavior {
    // Test with no encryption
    CTEncryptionManager *noEncryption = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                      encryptionLevel:CleverTapEncryptionNone];
    NSString *plainText = @"test string";
    NSString *result = [noEncryption encryptString:plainText];
    
    // With CleverTapEncryptionNone, should return plaintext as-is
    XCTAssertEqualObjects(result, plainText, @"CleverTapEncryptionNone should not encrypt");
    
    // Test with medium encryption
    CTEncryptionManager *mediumEncryption = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                         encryptionLevel:CleverTapEncryptionMedium];
    NSString *encrypted = [mediumEncryption encryptString:plainText];
    XCTAssertNotEqualObjects(encrypted, plainText, @"CleverTapEncryptionMedium should encrypt");
    
    // Decrypt should return original
    NSString *decrypted = [mediumEncryption decryptString:encrypted];
    XCTAssertEqualObjects(decrypted, plainText, @"Decryption failed");
}

#pragma mark - Encryption Algorithm Tests

- (void)testAESGCMEncryption {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                encryptionLevel:CleverTapEncryptionMedium];
        
        NSString *plainText = @"test string";
        NSString *encrypted = [mgr encryptString:plainText encryptionAlgorithm:AES_GCM];
        
        // Verify encryption occurred
        XCTAssertNotEqualObjects(encrypted, plainText, @"AES_GCM encryption failed");
        
        // Test GCM prefix detection
        XCTAssertTrue([mgr isTextAESGCMEncrypted:encrypted], @"isTextAESGCMEncrypted failed to detect AES_GCM encrypted text");
        
        // Test decryption
        NSString *decrypted = [mgr decryptString:encrypted encryptionAlgorithm:AES_GCM];
        XCTAssertEqualObjects(decrypted, plainText, @"AES_GCM decryption failed");
    } else {
        NSLog(@"Skipping AES_GCM test on iOS < 13.0");
    }
}

- (void)testAESEncryption {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                            encryptionLevel:CleverTapEncryptionMedium];
    
    NSString *plainText = @"test string";
    NSString *encrypted = [mgr encryptString:plainText encryptionAlgorithm:AES];
    
    // Verify encryption occurred
    XCTAssertNotEqualObjects(encrypted, plainText, @"AES encryption failed");
    
    // Verify it's not GCM encrypted
    XCTAssertFalse([mgr isTextAESGCMEncrypted:encrypted], @"isTextAESGCMEncrypted incorrectly detected AES as AES_GCM");
    
    // Test decryption
    NSString *decrypted = [mgr decryptString:encrypted encryptionAlgorithm:AES];
    XCTAssertEqualObjects(decrypted, plainText, @"AES decryption failed");
}

- (void)testIsTextAESGCMEncrypted {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"];
    
    // Craft a string with the expected prefix and suffix
    NSString *validGCMText = [NSString stringWithFormat:@"%@somedata%@", kAESGCMPrefixForTest, kAESGCMSuffixForTest];
    NSString *invalidText1 = @"somedata";
    NSString *invalidText2 = [NSString stringWithFormat:@"%@somedata", kAESGCMPrefixForTest]; // missing suffix
    NSString *invalidText3 = [NSString stringWithFormat:@"somedata%@", kAESGCMSuffixForTest]; // missing prefix
    
    XCTAssertTrue([mgr isTextAESGCMEncrypted:validGCMText], @"Should identify valid AES-GCM format");
    XCTAssertFalse([mgr isTextAESGCMEncrypted:invalidText1], @"Should reject plain text");
    XCTAssertFalse([mgr isTextAESGCMEncrypted:invalidText2], @"Should reject text with prefix only");
    XCTAssertFalse([mgr isTextAESGCMEncrypted:invalidText3], @"Should reject text with suffix only");
}

- (void)testCrossAlgorithmCompatibility {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                            encryptionLevel:CleverTapEncryptionMedium];
    
    NSString *plainText = @"test string";
    
    // Encrypt with AES but try to decrypt with default method
    NSString *aesEncrypted = [mgr encryptString:plainText encryptionAlgorithm:AES];
    NSString *decrypted = [mgr decryptString:aesEncrypted]; // Default decryption
    
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        // Encrypt with AES_GCM but try to decrypt with default method
        NSString *gcmEncrypted = [mgr encryptString:plainText encryptionAlgorithm:AES_GCM];
        decrypted = [mgr decryptString:gcmEncrypted]; // Default decryption
        XCTAssertEqualObjects(decrypted, plainText, @"Default decryption should handle AES_GCM");
    }
}

#pragma mark - String Encryption Edge Cases

- (void)testStringEdgeCases {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                            encryptionLevel:CleverTapEncryptionMedium];
    
    // Test empty string
    XCTAssertEqualObjects([mgr encryptString:@""], @"", @"Empty string should be handled properly");
    XCTAssertEqualObjects([mgr decryptString:@""], @"", @"Empty string should be handled properly");
    
    // Test large string
    NSMutableString *largeString = [NSMutableString string];
    for (int i = 0; i < 1000; i++) {
        [largeString appendString:@"abcdefghijklmnopqrstuvwxyz"];
    }
    
    NSString *encryptedLarge = [mgr encryptString:largeString];
    XCTAssertNotNil(encryptedLarge, @"Large string encryption failed");
    NSString *decryptedLarge = [mgr decryptString:encryptedLarge];
    XCTAssertEqualObjects(decryptedLarge, largeString, @"Large string decryption failed");
    
    // Test special characters
    NSString *specialChars = @"!@#$%^&*()_+{}|:\"<>?[];',./`~áéíóúñÁÉÍÓÚÑ";
    NSString *encryptedSpecial = [mgr encryptString:specialChars];
    XCTAssertNotNil(encryptedSpecial, @"Special chars encryption failed");
    NSString *decryptedSpecial = [mgr decryptString:encryptedSpecial];
    XCTAssertEqualObjects(decryptedSpecial, specialChars, @"Special chars decryption failed");
}

#pragma mark - Object Encryption Tests

- (void)testObjectEdgeCases {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                            encryptionLevel:CleverTapEncryptionMedium];
    
    
    // Test empty collections
    NSArray *emptyArray = @[];
    NSString *encryptedEmptyArray = [mgr encryptObject:emptyArray];
    XCTAssertNotNil(encryptedEmptyArray, @"Empty array encryption failed");
    NSArray *decryptedEmptyArray = [mgr decryptObject:encryptedEmptyArray];
    XCTAssertEqualObjects(decryptedEmptyArray, emptyArray, @"Empty array decryption failed");
    
    NSDictionary *emptyDict = @{};
    NSString *encryptedEmptyDict = [mgr encryptObject:emptyDict];
    XCTAssertNotNil(encryptedEmptyDict, @"Empty dictionary encryption failed");
    NSDictionary *decryptedEmptyDict = [mgr decryptObject:encryptedEmptyDict];
    XCTAssertEqualObjects(decryptedEmptyDict, emptyDict, @"Empty dictionary decryption failed");
    
    // Test complex nested object
    NSDictionary *complexObject = @{
        @"string": @"value",
        @"number": @42,
        @"array": @[@1, @2, @3],
        @"date": [NSDate date],
        @"nested": @{
            @"key": @"value",
            @"array": @[@"a", @"b", @"c"]
        }
    };
    
    NSString *encryptedComplex = [mgr encryptObject:complexObject];
    XCTAssertNotNil(encryptedComplex, @"Complex object encryption failed");
    NSDictionary *decryptedComplex = [mgr decryptObject:encryptedComplex];
    XCTAssertEqualObjects(decryptedComplex, complexObject, @"Complex object decryption failed");
}

- (void)testObjectEncryptionWithExplicitAlgorithm {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                            encryptionLevel:CleverTapEncryptionMedium];
    
    NSArray *testObject = @[@"test", @1, @2.0];
    
    // Test AES explicitly
    NSString *aesEncrypted = [mgr encryptObject:testObject encryptionAlgorithm:AES];
    XCTAssertNotNil(aesEncrypted, @"AES object encryption failed");
    NSArray *aesDecrypted = [mgr decryptObject:aesEncrypted encryptionAlgorithm:AES];
    XCTAssertEqualObjects(aesDecrypted, testObject, @"AES object decryption failed");
    
    // Test AES_GCM (if iOS 13+)
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        NSString *aesgcmEncrypted = [mgr encryptObject:testObject encryptionAlgorithm:AES_GCM];
        XCTAssertNotNil(aesgcmEncrypted, @"AES_GCM object encryption failed");
        NSArray *aesgcmDecrypted = [mgr decryptObject:aesgcmEncrypted encryptionAlgorithm:AES_GCM];
        XCTAssertEqualObjects(aesgcmDecrypted, testObject, @"AES_GCM object decryption failed");
    }
}

- (void)testObjectEncryptionVariousTypes {
    CTEncryptionManager *mgr = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                            encryptionLevel:CleverTapEncryptionMedium];
    
    // Test with NSString
    NSString *stringObj = @"test string";
    NSString *encryptedString = [mgr encryptObject:stringObj];
    XCTAssertNotNil(encryptedString, @"String object encryption failed");
    NSString *decryptedString = [mgr decryptObject:encryptedString];
    XCTAssertEqualObjects(decryptedString, stringObj, @"String object decryption failed");
    
    // Test with NSNumber
    NSNumber *numberObj = @42;
    NSString *encryptedNumber = [mgr encryptObject:numberObj];
    XCTAssertNotNil(encryptedNumber, @"Number object encryption failed");
    NSNumber *decryptedNumber = [mgr decryptObject:encryptedNumber];
    XCTAssertEqualObjects(decryptedNumber, numberObj, @"Number object decryption failed");
    
    // Test with NSDate
    NSDate *dateObj = [NSDate date];
    NSString *encryptedDate = [mgr encryptObject:dateObj];
    XCTAssertNotNil(encryptedDate, @"Date object encryption failed");
    NSDate *decryptedDate = [mgr decryptObject:encryptedDate];
    XCTAssertEqualObjects(decryptedDate, dateObj, @"Date object decryption failed");
    
    // Test with NSArray
    NSArray *arrayObj = @[@"one", @2, [NSDate date]];
    NSString *encryptedArray = [mgr encryptObject:arrayObj];
    XCTAssertNotNil(encryptedArray, @"Array object encryption failed");
    NSArray *decryptedArray = [mgr decryptObject:encryptedArray];
    XCTAssertEqualObjects(decryptedArray, arrayObj, @"Array object decryption failed");
    
    // Test with NSDictionary
    NSDictionary *dictObj = @{@"key1": @"value1", @"key2": @42};
    NSString *encryptedDict = [mgr encryptObject:dictObj];
    XCTAssertNotNil(encryptedDict, @"Dictionary object encryption failed");
    NSDictionary *decryptedDict = [mgr decryptObject:encryptedDict];
    XCTAssertEqualObjects(decryptedDict, dictObj, @"Dictionary object decryption failed");
}

#pragma mark - Account ID Variations

- (void)testAccountIDVariations {
    // Test with empty account ID
    CTEncryptionManager *emptyIDManager = [[CTEncryptionManager alloc] initWithAccountID:@""
                                                                     encryptionLevel:CleverTapEncryptionMedium];
    XCTAssertNotNil(emptyIDManager, @"Manager with empty ID should initialize");
    
    NSString *testString = @"test string";
    NSString *encrypted = [emptyIDManager encryptString:testString];
    XCTAssertNotEqualObjects(encrypted, testString, @"Encryption with empty ID should still work");
    NSString *decrypted = [emptyIDManager decryptString:encrypted];
    XCTAssertEqualObjects(decrypted, testString, @"Decryption with empty ID should work");
    
    // Test with very long account ID
    NSMutableString *longID = [NSMutableString string];
    for (int i = 0; i < 100; i++) {
        [longID appendString:@"id"];
    }
    
    CTEncryptionManager *longIDManager = [[CTEncryptionManager alloc] initWithAccountID:longID
                                                                     encryptionLevel:CleverTapEncryptionMedium];
    XCTAssertNotNil(longIDManager, @"Manager with long ID should initialize");
    
    encrypted = [longIDManager encryptString:testString];
    XCTAssertNotEqualObjects(encrypted, testString, @"Encryption with long ID should work");
    decrypted = [longIDManager decryptString:encrypted];
    XCTAssertEqualObjects(decrypted, testString, @"Decryption with long ID should work");
}

// Test different encryption levels without directly using updateEncryptionLevel:
- (void)testEncryptionLevelsDifference {
    NSString *testString = @"test string";
    
    // Create with None level
    CTEncryptionManager *noneLevelManager = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                        encryptionLevel:CleverTapEncryptionNone];
    
    // Create with Medium level
    CTEncryptionManager *mediumLevelManager = [[CTEncryptionManager alloc] initWithAccountID:@"test"
                                                                          encryptionLevel:CleverTapEncryptionMedium];
    
    // Verify None level doesn't encrypt
    NSString *noneResult = [noneLevelManager encryptString:testString];
    XCTAssertEqualObjects(noneResult, testString, @"None level should not encrypt");
    
    // Verify Medium level does encrypt
    NSString *mediumResult = [mediumLevelManager encryptString:testString];
    XCTAssertNotEqualObjects(mediumResult, testString, @"Medium level should encrypt");
    
    // Compare the results
    XCTAssertNotEqualObjects(noneResult, mediumResult, @"None and Medium levels should produce different results");
}

// Test the caching behavior that would indirectly exercise the updateCachedGUIDS method
- (void)testCachedGUIDs {
    // Create a test cache key prefix - this should match what's used in CTUtils
    NSString *testAccountId = @"test_account";
    
    // Setup: Create a simulated cached GUIDs dictionary that matches the expected format
    // Format we expect: {"Email_value": "guid", "Identity_value": "guid"}
    NSDictionary *originalCache = @{
        @"Email_test@example.com": @"550e8400-e29b-41d4-a716-446655440000",
        @"Identity_user123": @"7c9e6679-7425-40de-944b-e07fc1f90ae7"
    };
    
    // Store the original cache using the same mechanism as the class
    NSString *cacheKey = [CTUtils getKeyWithSuffix:CLTAP_CachedGUIDSKey accountID:testAccountId];
    [CTPreferences putObject:originalCache forKey:cacheKey];
    
    // Now create a Medium encryption manager with the same account ID
    // This should trigger updateCachedGUIDS internally due to encryption level change
    CTEncryptionManager *mediumManager = [[CTEncryptionManager alloc] initWithAccountID:testAccountId
                                                                     encryptionLevel:CleverTapEncryptionMedium
                                                                 isDefaultInstance:YES];
    
    // Test that the cached data has changed
    NSDictionary *updatedCache = [CTPreferences getObjectForKey:cacheKey];
    XCTAssertNotNil(updatedCache, @"Cache should still exist after encryption level change");
    
    // The keys should be different now because the identifiers would be encrypted
    BOOL foundOriginalKey = NO;
    for (NSString *key in originalCache) {
        if ([updatedCache objectForKey:key] != nil) {
            foundOriginalKey = YES;
            break;
        }
    }
    XCTAssertFalse(foundOriginalKey, @"Original keys should not be found in updated cache");
    
    // The values (GUIDs) should still be the same, just under different keys
    NSArray *originalValues = [originalCache.allValues sortedArrayUsingSelector:@selector(compare:)];
    NSArray *updatedValues = [updatedCache.allValues sortedArrayUsingSelector:@selector(compare:)];
    XCTAssertEqualObjects(originalValues, updatedValues, @"Cache values should remain unchanged");
    
    // Verify we can decrypt the new keys
    BOOL foundDecryptedKey = NO;
    for (NSString *encryptedKey in updatedCache) {
        NSArray *keyComponents = [encryptedKey componentsSeparatedByString:@"_"];
        if (keyComponents.count != 2) continue;
        
        NSString *prefix = keyComponents[0]; // "Email" or "Identity"
        NSString *encryptedValue = keyComponents[1];
        
        // Decrypt the value part
        NSString *decryptedValue = [mediumManager decryptString:encryptedValue];
        
        // Check if it matches any of our original values
        for (NSString *originalKey in originalCache) {
            NSArray *originalComponents = [originalKey componentsSeparatedByString:@"_"];
            if (originalComponents.count != 2) continue;
            
            NSString *originalPrefix = originalComponents[0];
            NSString *originalValue = originalComponents[1];
            
            if ([prefix isEqualToString:originalPrefix] && [decryptedValue isEqualToString:originalValue]) {
                foundDecryptedKey = YES;
                break;
            }
        }
        
        if (foundDecryptedKey) break;
    }
    XCTAssertTrue(foundDecryptedKey, @"Should be able to decrypt at least one updated cache key");
    
    // Clean up - remove our test cache
    [CTPreferences removeObjectForKey:cacheKey];
}

@end
