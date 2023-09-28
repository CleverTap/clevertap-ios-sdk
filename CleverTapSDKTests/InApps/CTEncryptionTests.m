//
//  CTEncryptionTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 28/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTEncryptionTests.h"
#import "CTInAppStore.h"

@implementation CTEncryptionTests

- (void)testInAppEncryption {
    
    NSError *error;
    NSArray *objectToEncrypt = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"inapp_interstitial" ofType:@"json"]] options:kNilOptions error:&error];
    CTAES *ctAES = [[CTAES alloc]initWithAccountID:@"test"];
    NSString *encryptedString = [ctAES getEncryptedBase64String:objectToEncrypt];
 
    NSArray *decryptedObject = [ctAES getDecryptedObject:encryptedString];
    
    XCTAssertEqualObjects(objectToEncrypt, decryptedObject);
}

@end
