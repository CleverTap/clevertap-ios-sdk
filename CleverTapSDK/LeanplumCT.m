//
//  LeanplumCT.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 22.05.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "LeanplumCT.h"

@implementation LeanplumCT

+ (void)load {
    [self setInstance: [CleverTap sharedInstance]];
}

static CleverTap * _instance;
+ (CleverTap *)instance {
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
    
    
}

+ (nullable NSString *)deviceId {
    return @"";
}

+ (nullable NSString *)userId {
    return @"";
}

+ (void)setUserAttributes:(NSDictionary *)attributes {
    [self setUserId:@"" withUserAttributes:attributes];
}

+ (void)setUserId:(NSString *)userId {
    [self setUserId:userId withUserAttributes:@{}];
}

+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes {
    
}

+ (void)setTrafficSourceInfo:(NSDictionary *)info {
    
}

+ (void)start {
    
}

+ (void)startWithResponseHandler:(LeanplumStartBlock)response {
    
}

+ (void)startWithUserAttributes:(NSDictionary<NSString *, id> *)attributes {
    
}

+ (void)startWithUserId:(NSString *)userId {
    
}

+ (void)startWithUserId:(NSString *)userId
        responseHandler:(nullable LeanplumStartBlock)response {
    
}

+ (void)startWithUserId:(NSString *)userId
         userAttributes:(NSDictionary<NSString *, id> *)attributes {
    
}

+ (void)startWithUserId:(nullable NSString *)userId
         userAttributes:(nullable NSDictionary<NSString *, id> *)attributes
        responseHandler:(nullable LeanplumStartBlock)startResponse {
    
}

+ (void)trackPurchase:(NSString *)event
            withValue:(double)value
      andCurrencyCode:(nullable NSString *)currencyCode
        andParameters:(nullable NSDictionary<NSString *, id> *)params {
    
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
    
    
    
}

@end
