//
//  LeanplumCT.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 22.05.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "LeanplumCT.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"

NSString *const LP_STATE_PREFIX = @"state_";
NSString *const LP_VALUE_PARAM_NAME = @"value";
NSString *const LP_INFO_PARAM_NAME = @"info";
NSString *const LP_CHARGED_EVENT_PARAM_NAME = @"event";
NSString *const LP_CURRENCY_CODE_PARAM_NAME = @"currencyCode";

@implementation LeanplumCT

static CleverTap * _instance;
+ (CleverTap *)instance {
    if (!_instance) {
        _instance = [CleverTap sharedInstance];
    }
    return _instance;
}

+ (void)setInstance:(CleverTap *)instance {
    _instance = instance;
}

+ (void)onStartResponse:(LeanplumStartBlock)block {
    
}

+ (void)advanceTo:(nullable NSString *)state {
    [self advanceTo:state withInfo:nil];
}

+ (void)advanceTo:(nullable NSString *)state
         withInfo:(nullable NSString *)info {
    [self advanceTo:state withInfo:info andParameters:nil];
}

+ (void)advanceTo:(nullable NSString *)state
   withParameters:(nullable NSDictionary<NSString *, id> *)params {
    [self advanceTo:state withInfo:nil andParameters:params];
}

+ (void)advanceTo:(nullable NSString *)state
         withInfo:(nullable NSString *)info
    andParameters:(nullable NSDictionary<NSString *, id> *)params {
    if (state) {
        return;
    }

    NSString *eventName = [NSString stringWithFormat:@"%@%@", LP_STATE_PREFIX, state];
    CleverTapLogDebug(self.instance.config.logLevel,
                      @"%@: LeanplumCT.advance will call track with %@ and %@.", self, eventName, params);
    [self track:eventName withValue:0.0 andInfo:info andParameters:params];
}

+ (nullable NSString *)deviceId {
    return [[self instance] profileGetCleverTapID];
}

+ (nullable NSString *)userId {
    return [[self instance] profileGet:CLTAP_PROFILE_IDENTITY_KEY];
}

+ (void)setUserAttributes:(NSDictionary *)attributes {
    NSDictionary *profileAttributes = [self filterNullDictionaryValues:[self transformArrayValues:attributes]];
    CleverTapLogDebug(self.instance.config.logLevel,
                      @"%@: LeanplumCT.setUserAttributes will call profilePush with %@.", self, profileAttributes);
    [[self instance] profilePush:profileAttributes];
    
    for (NSString* key in attributes) {
        id value = attributes[key];
        if (!value || [value isEqual:[NSNull null]]) {
            CleverTapLogDebug(self.instance.config.logLevel,
                              @"%@: LeanplumCT.setUserAttributes will call profileRemoveValue forKey: %@.", self, key);
            [[self instance] profileRemoveValueForKey:key];
        }
    }
}

+ (void)setUserId:(NSString *)userId {
    [self setUserId:userId withUserAttributes:@{}];
}

+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes {
    if (userId) {
        // TODO: check if setting the Identity is enough
        CleverTapLogDebug(self.instance.config.logLevel,
                          @"%@: LeanplumCT.setUserId will call onUserLogin with %@: %@.", self, CLTAP_PROFILE_IDENTITY_KEY, userId);
        [[self instance] onUserLogin:@{ CLTAP_PROFILE_IDENTITY_KEY: userId }];
    }

    if (attributes && [attributes count] > 0) {
        [self setUserAttributes:attributes];
    }
}

+ (void)setTrafficSourceInfo:(NSDictionary *)info {
    NSString* source = info[@"publisherName"];
    NSString* medium = info[@"publisherSubPublisher"];
    NSString* campaign = info[@"publisherSubCampaign"];
    
    CleverTapLogDebug(self.instance.config.logLevel,
                      @"%@: LeanplumCT.setTrafficSourceInfo will call pushInstallReferrerSource \
                        with %@, %@ and %@.", self, source, medium, campaign);
    [[self instance] pushInstallReferrerSource:source medium:medium campaign:campaign];
}

+ (void)trackPurchase:(NSString *)event
            withValue:(double)value
      andCurrencyCode:(nullable NSString *)currencyCode
        andParameters:(nullable NSDictionary<NSString *, id> *)params {
    if (!event) {
        return;
    }
    
    NSMutableDictionary<NSString *, id> *details = [[self transformArrayValues:params] mutableCopy];
    [details setObject:event forKey:LP_CHARGED_EVENT_PARAM_NAME];
    [details setObject:@(value) forKey:LP_VALUE_PARAM_NAME];
    
    if (currencyCode) {
        [details setObject:currencyCode forKey:LP_CURRENCY_CODE_PARAM_NAME];
    }
    NSArray *items = @[];

    CleverTapLogDebug(self.instance.config.logLevel,
                      @"%@: LeanplumCT.trackPurchase will call will call recordChargedEvent \
                        with %@ and %@.", self, details, items);
    [[self instance] recordChargedEventWithDetails:details andItems:items];
}

+ (void)track:(NSString *)event {
    [self track:event withValue:0.0 andInfo:nil andParameters:nil];
}

+ (void)track:(NSString *)event
    withValue:(double)value {
    [self track:event withValue:value andInfo:nil andParameters:nil];
}

+ (void)track:(NSString *)event
     withInfo:(nullable NSString *)info {
    [self track:event withValue:0.0 andInfo:info andParameters:nil];
}

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(nullable NSString *)info {
    [self track:event withValue:value andInfo:info andParameters:nil];
}

+ (void)track:(NSString *)event withParameters:(nullable NSDictionary<NSString *, id> *)params {
    [self track:event withValue:0.0 andInfo:nil andParameters:params];
}

+ (void)track:(NSString *)event
    withValue:(double)value
andParameters:(nullable NSDictionary<NSString *, id> *)params {
    [self track:event withValue:value andInfo:nil andParameters:params];
}

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(nullable NSString *)info
andParameters:(nullable NSDictionary<NSString *, id> *)params {
    if (!event) {
        return;
    }
    
    NSMutableDictionary<NSString *, id> *eventParams = [[self transformArrayValues:params] mutableCopy];
    [eventParams setObject:@(value) forKey:LP_VALUE_PARAM_NAME];
    
    if (info) {
        [eventParams setObject:info forKey:LP_INFO_PARAM_NAME];
    }

    CleverTapLogDebug(self.instance.config.logLevel,
                      @"%@: LeanplumCT.track will call recordEvent \
                        with %@ and %@.", self, event, eventParams);
    [[self instance] recordEvent:event withProps:eventParams];
}

+ (NSDictionary<NSString *, id> *)transformArrayValues:(NSDictionary<NSString *, id> *)dictionary {
    return [self transformDictionaryValues:dictionary usingBlock:^id(id value) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)value;
            NSArray *filteredArray =
            [array filteredArrayUsingPredicate:
             [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
                return evaluatedObject && ![evaluatedObject isEqual:[NSNull null]];
            }]];
            NSArray *stringArray = [filteredArray valueForKey:@"description"];
            NSString *joinedString = [stringArray componentsJoinedByString:@","];
            NSString *finalString = [NSString stringWithFormat:@"[%@]", joinedString];
            return finalString;
        }
        return value;
    }];
}

// TODO: Add to category or utils
+ (NSDictionary<NSString *, id> *)transformDictionaryValues:(NSDictionary<NSString *, id> *)dictionary
                                                  usingBlock:(id(^)(id))block {
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
    for (NSString *key in dictionary) {
        id value = dictionary[key];
        // If the value is mutable and modified in the block,
        // this will modify the original dictionary value
        id transformedValue = block(value);
        result[key] = transformedValue;
    }
    
    return [result copy];
}

+ (NSDictionary<NSString *, id> *)filterNullDictionaryValues:(NSDictionary<NSString *, id> *)dictionary {
    NSSet *keys = [dictionary keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop){
        return obj && ![obj isEqual:[NSNull null]];
    }];
    return [dictionary dictionaryWithValuesForKeys:[keys allObjects]];
}

@end
