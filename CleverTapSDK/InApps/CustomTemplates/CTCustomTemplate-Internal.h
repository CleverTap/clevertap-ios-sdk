//
//  CTCustomTemplate-Internal.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 28.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTCustomTemplate_Internal_h
#define CTCustomTemplate_Internal_h

#import "CTTemplatePresenter.h"
#import "CTCustomTemplate.h"
#import "CTTemplateArgument.h"

@interface CTCustomTemplate (Internal)

@property (nonatomic, strong, readonly) NSString *templateType;
@property (nonatomic, strong, readonly) NSArray<CTTemplateArgument *> *arguments;
@property (nonatomic, strong, readonly) id<CTTemplatePresenter> presenter;

- (instancetype)initWithTemplateName:(NSString *)templateName
                        templateType:(NSString *)templateType
                            isVisual:(BOOL)isVisual
                           arguments:(NSArray *)arguments
                           presenter:(id<CTTemplatePresenter>)presenter;

@end

#endif /* CTCustomTemplate_Internal_h */
