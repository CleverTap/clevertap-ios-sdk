//
//  CTInAppStore+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 17.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CTInAppStore_Tests_h
#define CTInAppStore_Tests_h

@interface CTInAppStore(Tests)
@property (nonatomic, strong) NSArray *serverSideInApps;
@property (nonatomic, strong) NSArray *clientSideInApps;

- (void)removeClientSideInApps;
- (void)removeServerSideInApps;
- (void)migrateInAppQueueKeys;

- (NSString *)storageKeyWithSuffix:(NSString *)suffix;
@end

#endif /* CTInAppStore_Tests_h */
