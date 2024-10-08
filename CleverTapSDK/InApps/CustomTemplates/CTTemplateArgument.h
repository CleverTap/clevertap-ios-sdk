//
//  CTTemplateArgument.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CTTemplateArgumentType) {
    CTTemplateArgumentTypeString,
    CTTemplateArgumentTypeNumber,
    CTTemplateArgumentTypeBool,
    CTTemplateArgumentTypeFile,
    CTTemplateArgumentTypeAction
};

@interface CTTemplateArgument : NSObject

@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, assign) CTTemplateArgumentType type;
@property (nonatomic, strong, nullable) id defaultValue;

- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name
                                 type:(CTTemplateArgumentType)type
                         defaultValue:(id _Nullable)defaultValue;

+ (NSString * _Nonnull)templateArgumentTypeToString:(CTTemplateArgumentType)type;

@end
