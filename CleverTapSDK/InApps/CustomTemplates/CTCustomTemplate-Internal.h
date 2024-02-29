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

@interface CTCustomTemplate ()

@property (nonatomic, strong) NSArray<CTTemplateArgument *> *arguments;

- (instancetype)initWithTemplateName:(NSString *)templateName
                        templateType:(NSString *)templateType
                           arguments:(NSArray *)arguments
                           presenter:(id<CTTemplatePresenter>)presenter
                   fileArgumentNames:(NSSet *)fileArgumentNames;

@end

#endif /* CTCustomTemplate_Internal_h */
