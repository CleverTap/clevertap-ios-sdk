//
//  CTAppFunctionBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCustomTemplate.h"
#import "CTTemplatePresenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTAppFunctionBuilder : NSObject

- (void)setName:(NSString *)name;

- (void)addArgument:(NSString *)name withString:(NSString *)defaultValue;
- (void)addArgument:(NSString *)name withNumber:(NSNumber *)defaultValue;
- (void)addArgument:(NSString *)name withBool:(BOOL)defaultValue;
- (void)addFileArgument:(NSString *)name;

- (void)setOnPresentWithPresenter:(id<CTTemplatePresenter>)presenter;

- (CTCustomTemplate *)build;

@end

NS_ASSUME_NONNULL_END
