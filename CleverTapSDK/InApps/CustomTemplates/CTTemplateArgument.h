//
//  CTTemplateArgument.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTTemplateArgument : NSObject

@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, strong, nonnull) NSString *type;
@property (nonatomic, strong, nullable) id defaultValue;

- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name
                                 type:(NSString * _Nonnull)type
                         defaultValue:(id _Nullable)defaultValue;

@end
