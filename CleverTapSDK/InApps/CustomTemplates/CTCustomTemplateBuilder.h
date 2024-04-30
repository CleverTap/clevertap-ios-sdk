//
//  CTCustomTemplateBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 6.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplatePresenter.h"
#import "CTCustomTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCustomTemplateBuilder : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (void)setName:(NSString *)name;

- (void)addArgument:(NSString *)name withString:(NSString *)defaultValue;
- (void)addArgument:(NSString *)name withNumber:(NSNumber *)defaultValue;
- (void)addArgument:(NSString *)name withBool:(BOOL)defaultValue;
- (void)addArgument:(nonnull NSString *)name withDictionary:(nonnull NSDictionary *)defaultValue;
- (void)addFileArgument:(NSString *)name;

- (void)setOnPresentWithPresenter:(id<CTTemplatePresenter>)presenter;

- (CTCustomTemplate *)build;

@end

NS_ASSUME_NONNULL_END
