//
//  EventAdapter.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTriggerValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTEventAdapter : NSObject

@property (nonatomic, strong, readonly) NSString *eventName;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEventName:(NSString *)eventName
                  eventProperties:(NSDictionary *)eventProperties;

- (instancetype)initWithEventName:(NSString *)eventName
                  eventProperties:(NSDictionary *)eventProperties
                         andItems:(NSArray<NSDictionary *> *)items;

- (CTTriggerValue *)propertyValueNamed:(NSString *)name;
- (CTTriggerValue *)itemValueNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
