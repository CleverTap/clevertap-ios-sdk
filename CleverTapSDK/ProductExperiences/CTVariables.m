//
//  CTVariables.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTVariables.h"
#import "CTConstants.h"
#import "CTUtils.h"
//#import "CTVarCache.h"

@interface CTVariables()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;

@property(strong, nonatomic) NSMutableArray *variablesChangedBlocks;
@property(strong, nonatomic) NSMutableArray *onceNoDownloadsBlocks;
@end

@implementation CTVariables

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo: (CTDeviceInfo*)deviceInfo {
    if ((self = [super init])) {
        self.varCache = [[CTVarCache alloc]initWithConfig:config deviceInfo:deviceInfo];
    }
    return self;
}

- (CTVar *)define:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([CTUtils isNullOrEmpty:name]) {
        CleverTapLogDebug(_config.logLevel, @"%@: Empty name provided as parameter while defining a variable.", self);
        return nil;
    }

    @synchronized (self.varCache.vars) {
        CT_TRY
        CTVar *existing = [self.varCache getVariable:name];
        if (existing) {
            return existing;
        }
        CT_END_TRY
        CTVar *var = [[CTVar alloc] initWithName:name
                                  withComponents:[self.varCache getNameComponents:name]
                                withDefaultValue:defaultValue
                                        withKind:kind
                                        varCache:self.varCache];
        return var;
    }
}

- (CTVar *)getVariable:(NSString *)name
{
    CTVar *var = [self.varCache getVariable:name];
    if (!var) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Variable with name: %@ not found.", self, name);
    }
    return var;
}

- (void)handleVariablesResponse:(NSDictionary *)varsResponse
{
    if (varsResponse) {
        [[self varCache] setAppLaunchedRecorded:YES];
        [[self varCache] applyVariableDiffs:varsResponse];
    }
}

- (void)addVarListeners {
    [self.varCache onUpdate:^{
        [self triggerVariablesChanged];
    }];
}

- (void)triggerVariablesChanged
{
    for (CleverTapVariablesChangedBlock block in self.variablesChangedBlocks.copy) {
        block();
    }
}

- (void)onVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull )block {
    
    if (!block) {
        CleverTapLogStaticDebug(@"Nil block parameter provided while calling [CleverTap onVariablesChanged].");
        return;
    }
    
    CT_TRY
    if (!self.variablesChangedBlocks) {
        self.variablesChangedBlocks = [NSMutableArray array];
    }
    [self.variablesChangedBlocks addObject:[block copy]];
    CT_END_TRY

    if ([self.varCache hasReceivedDiffs]) {
        block();
    }
}

- (NSDictionary*)varsPayload {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"type"] = @"varsPayload";
    
    NSMutableDictionary *allVars = [NSMutableDictionary dictionary];
    
    [self.varCache.vars
     enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CTVar * _Nonnull varValue, BOOL * _Nonnull stop) {
        
        NSMutableDictionary *varData = [NSMutableDictionary dictionary];
        
        if ([varValue.defaultValue isKindOfClass:[NSDictionary class]]) {
            NSDictionary *flattenedMap = [self flatten:varValue.defaultValue varName:varValue.name];
            [allVars addEntriesFromDictionary:flattenedMap];
        }
        else {
            if ([varValue.kind isEqualToString:CT_KIND_INT] || [varValue.kind isEqualToString:CT_KIND_FLOAT]) {
                varData[@"type"] = @"number";
            }
            else if ([varValue.kind isEqualToString:CT_KIND_BOOLEAN]) {
                varData[@"type"] = @"boolean";
            }
            else {
                varData[@"type"] = varValue.kind;
            }
            varData[@"defaultValue"] = varValue.defaultValue;
            allVars[key] = varData;
        }
    }];
    result[@"vars"] = allVars;
    
    return result;
}

- (NSDictionary*)flatten:(NSDictionary*)map varName:(NSString*)varName {
    NSMutableDictionary *varsPayload = [NSMutableDictionary dictionary];
    
    [map enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        
        if ([value isKindOfClass:[NSString class]] ||
            [value isKindOfClass:[NSNumber class]]) {
            NSString *payloadKey = [NSString stringWithFormat:@"%@.%@",varName,key];
            varsPayload[payloadKey] = @{@"defaultValue": value};
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            NSString *payloadKey = [NSString stringWithFormat:@"%@.%@",varName,key];
            
            NSDictionary* flattenedMap = [self flatten:value varName:payloadKey];
            [varsPayload addEntriesFromDictionary:flattenedMap];
        }
    }];
    
    return varsPayload;
}

- (void)onceVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull )block {
    
    if (!block) {
        CleverTapLogStaticDebug(@"Nil block parameter provided while calling [CleverTap onceVariablesChanged].");
        return;
    }
    
    if ([self.varCache hasReceivedDiffs]) {
        block();
    } else {
        CT_TRY
        static dispatch_once_t onceNoDownloadsBlocksToken;
        dispatch_once(&onceNoDownloadsBlocksToken, ^{
            self.onceNoDownloadsBlocks = [NSMutableArray array];
        });
        @synchronized (self.onceNoDownloadsBlocks) {
            [self.onceNoDownloadsBlocks addObject:[block copy]];
        }
        CT_END_TRY
    }
}

@end
