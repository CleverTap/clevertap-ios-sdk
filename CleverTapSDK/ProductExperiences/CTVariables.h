//
//  CTVariables.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTVarCache.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CTFileDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTVariables : NSObject <CTFileVarDelegate>

@property(strong, nonatomic) CTVarCache *varCache;
@property(strong, nonatomic, nullable) CleverTapFetchVariablesBlock fetchVariablesBlock;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config 
                    deviceInfo:(CTDeviceInfo *)deviceInfo
                fileDownloader:(CTFileDownloader *)fileDownloader;

- (CTVar * _Nullable)define:(NSString *)name
             with:(nullable NSObject *)defaultValue
             kind:(nullable NSString *)kind
NS_SWIFT_NAME(define(name:value:kind:));

- (void)handleVariablesResponse:(NSDictionary *)varsResponse;
- (void)handleVariablesError;
- (void)triggerFetchVariables:(BOOL)success;
- (void)onVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull)block;
- (void)onceVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull)block;
- (void)onVariablesChangedAndNoDownloadsPending:(CleverTapVariablesChangedBlock _Nonnull)block;
- (void)onceVariablesChangedAndNoDownloadsPending:(CleverTapVariablesChangedBlock _Nonnull)block;
- (NSDictionary*)flatten:(NSDictionary*)map varName:(NSString*)varName;
- (NSDictionary*)varsPayload;
- (NSDictionary*)unflatten:(NSDictionary*)result;
- (void)clearUserContent;

@end

NS_ASSUME_NONNULL_END
