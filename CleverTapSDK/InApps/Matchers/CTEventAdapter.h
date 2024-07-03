//
//  EventAdapter.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CTTriggerValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTEventAdapter : NSObject

@property (nonatomic, strong, readonly) NSString *eventName;
@property (nonatomic, assign, readonly) CLLocationCoordinate2D location;
@property (nonatomic, strong, readonly) NSString *profileAttrName;
@property (nonatomic, strong, nonnull) NSDictionary *eventProperties;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEventName:(NSString *)eventName
                  eventProperties:(NSDictionary *)eventProperties
                      andLocation:(CLLocationCoordinate2D)location;

- (instancetype)initWithEventName:(NSString *)eventName
                  eventProperties:(NSDictionary *)eventProperties
                         location:(CLLocationCoordinate2D)location
                         andItems:(NSArray<NSDictionary *> *)items;

- (instancetype)initWithEventName:(NSString *)eventName
                  profileAttrName:(NSString *)profileAttrName
                  eventProperties:(NSDictionary *)eventProperties
                      andLocation:(CLLocationCoordinate2D)location;

- (CTTriggerValue * _Nullable)propertyValueNamed:(NSString *)name;
- (CTTriggerValue * _Nullable)itemValueNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
