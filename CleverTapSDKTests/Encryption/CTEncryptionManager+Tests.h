//
//  CTEncryption+Tests.h
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 14/05/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTEncryptionManager_Tests_h
#define CTEncryptionManager_Tests_h

#import "CTEncryptionManager.h"

@interface CTEncryptionManager(Tests)

- (NSString *)encryptString:(NSString *)plaintext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

- (NSString *)encryptObject:(id)object encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

@end


#endif /* CTEncryptionManager_Tests_h */
