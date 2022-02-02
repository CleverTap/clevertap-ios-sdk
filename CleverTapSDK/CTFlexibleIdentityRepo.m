//
//  CTFlexibleIdentityRepo.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "CTFlexibleIdentityRepo.h"
#import "CTConstants.h"
#import "CTLoginInfoProvider.h"
#import "CleverTapInstanceConfigPrivate.h"


@interface CTFlexibleIdentityRepo () {}
@property (nonatomic, strong) NSArray *identities;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTValidationResultStack *validationResultStack;
@property (nonatomic, strong) CTLoginInfoProvider *loginInfoProvider;
@end

@implementation CTFlexibleIdentityRepo

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config deviceInfo:(CTDeviceInfo*)deviceInfo validationResultStack:(CTValidationResultStack*)validationResultStack
{
    self = [super init];
    if (self) {
        self.config = config;
        self.deviceInfo = deviceInfo;
        self.validationResultStack = validationResultStack;
        self.loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:deviceInfo config:config];
        [self loadIdentities];
    }
    return self;
}

- (NSArray *)getIdentities {
    return self.identities;
}

- (BOOL)isIdentity:(NSString *)key {
    return [self.identities containsObject:key];
}

- (void)loadIdentities {
    // CHECK IF ITS A LEGACY USER
    NSString *cachedIdentities = [self.loginInfoProvider getCachedIdentities];
    NSArray *finalIdentityKeys;
    
    // NEW USER
    // GET IDENTIFIERS FROM PLIST IF DEFAULT INSTANCE ELSE CONFIG SETTER
    NSArray *configIdentifiers = [self getConfigIdentifiers];
    
    // RAISE ERROR IF CACHED AND PLIST IDENTITIES ARE NOT EQUAL
    NSArray *cachedIdentityKeys = [cachedIdentities componentsSeparatedByString: @","];
    if (cachedIdentityKeys.count > 0 && ![cachedIdentityKeys isEqualToArray: configIdentifiers]) {
        CTValidationResult *error = [[CTValidationResult alloc] init];
        NSString *errString = @"Profile Identifiers mismatch with the previously saved ones";
        [error setErrorCode:531];
        [error setErrorDesc:errString];
        [self.validationResultStack pushValidationResult:error];
        CleverTapLogDebug(self.config.logLevel, @"%@: %@", self, errString);
    }
    
    // USE CACHED IDENTITIES IF AVAILABLE, ELSE USE PLIST/SETTER, ELSE USE DEFAULT CONSTANTS
    if (cachedIdentityKeys && cachedIdentityKeys.count > 0) {
        finalIdentityKeys = cachedIdentityKeys;
    }
    else if (configIdentifiers && configIdentifiers.count > 0) {
        finalIdentityKeys = configIdentifiers;
    }
    else {
        finalIdentityKeys = CLTAP_PROFILE_IDENTIFIER_KEYS;
    }
    
    // SAVE IDENTITIES TO CACHE IF NOT ALREADY
    if (!cachedIdentityKeys || cachedIdentityKeys.count == 0) {
        [self.loginInfoProvider setCachedIdentities: [configIdentifiers componentsJoinedByString: @","]];
    }
    self.identities = finalIdentityKeys;
}

- (NSArray *)getConfigIdentifiers {
    // IF DEFAULT INSTANCE, GET KEYS FROM PLIST, ELSE GET FROM SETTER
    if (self.config.isDefaultInstance) {
        // ONLY ADD SUPPORTED KEYS
        NSArray *clevertapIdentifiers = [[NSBundle mainBundle].infoDictionary objectForKey:@"CleverTapIdentifiers"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self IN %@", CLTAP_ALL_PROFILE_IDENTIFIER_KEYS];
        NSArray *result = [clevertapIdentifiers filteredArrayUsingPredicate:predicate];
        return result;
    }
    else {
        return self.config.identityKeys;
    }
}

@end
