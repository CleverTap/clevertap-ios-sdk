//
//  CTAppFunctionBuilder-Internal.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 28.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTAppFunctionBuilder_Internal_h
#define CTAppFunctionBuilder_Internal_h

@interface CTAppFunctionBuilder ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *templateType;
@property (nonatomic, strong) NSMutableSet<NSString *> *argumentNames;
@property (nonatomic, strong) NSMutableSet<NSString *> *fileArgumentNames;
@property (nonatomic, strong) NSMutableArray *arguments;
@property (nonatomic, strong) id<CTTemplatePresenter> presenter;

- (void)addArgumentWithName:(NSString *)name type:(NSString *)type defaultValue:(id)defaultValue;

@end

#endif /* CTAppFunctionBuilder_Internal_h */
