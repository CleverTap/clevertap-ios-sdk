//
//  CTCustomTemplateBuilder-Internal.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 6.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//
#import "CTCustomTemplateBuilder.h"
#import "CTTemplateArgument.h"

#ifndef CTCustomTemplateBuilder_Internal_h
#define CTCustomTemplateBuilder_Internal_h

NS_ASSUME_NONNULL_BEGIN

@interface CTCustomTemplateBuilder ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *templateType;
@property (nonatomic, assign) BOOL isVisual;

@property (nonatomic, strong) NSSet<NSNumber *> *nullableArgumentTypes;
@property (nonatomic, strong) NSMutableSet<NSString *> *argumentNames;
@property (nonatomic, strong) NSMutableSet<NSString *> *parentArgumentNames;
@property (nonatomic, strong) NSMutableArray *arguments;

@property (nonatomic, strong) id<CTTemplatePresenter> presenter;

- (instancetype)initWithType:(NSString *)type isVisual:(BOOL)isVisual;
- (instancetype)initWithType:(NSString *)type isVisual:(BOOL)isVisual nullableArgumentTypes:(NSSet *)nullableArgumentTypes;

- (void)addArgumentWithName:(NSString *)name type:(CTTemplateArgumentType)type defaultValue:(nullable id)defaultValue;

@end

NS_ASSUME_NONNULL_END

#endif /* CTCustomTemplateBuilder_Internal_h */
