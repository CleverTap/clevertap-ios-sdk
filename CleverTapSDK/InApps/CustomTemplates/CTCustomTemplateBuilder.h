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

#define TEMPLATE_TYPE @"template"
#define FUNCTION_TYPE @"function"

NS_ASSUME_NONNULL_BEGIN

@interface CTCustomTemplateBuilder : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (void)setName:(NSString *)name;

- (void)addArgument:(NSString *)name withString:(NSString *)defaultValue
NS_SWIFT_NAME(addArgument(_:string:));

- (void)addArgument:(NSString *)name withNumber:(NSNumber *)defaultValue
NS_SWIFT_NAME(addArgument(_:number:));

- (void)addArgument:(NSString *)name withBool:(BOOL)defaultValue
NS_SWIFT_NAME(addArgument(_:boolean:));

- (void)addFileArgument:(NSString *)name;

- (void)setPresenter:(id<CTTemplatePresenter>)presenter;

- (CTCustomTemplate *)build;

@end

NS_ASSUME_NONNULL_END
