//
//  TriggerValue.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggerValue : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValue:(id)value;

@property (nonatomic, strong, readonly) id value;
@property (nonatomic, strong, readonly) NSString *stringValue;
@property (nonatomic, strong, readonly) NSNumber *numberValue;
@property (nonatomic, strong, readonly) NSArray *arrayValue;

- (BOOL)isArray;

@end

NS_ASSUME_NONNULL_END
