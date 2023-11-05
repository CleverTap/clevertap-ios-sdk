//
//  EventAdapter.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTEventAdapter.h"

@interface CTEventAdapter()

@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDictionary *eventProperties;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, assign) CLLocationCoordinate2D location;

@end

@implementation CTEventAdapter

- (instancetype)initWithEventName:(NSString *)eventName
                  eventProperties:(NSDictionary *)eventProperties
                      andLocation:(CLLocationCoordinate2D)location{
    if (self = [super init]) {
        self = [self initWithEventName:eventName eventProperties:eventProperties location:location andItems:@[]];
    }
    return self;
}

- (instancetype)initWithEventName:(NSString *)eventName
                  eventProperties:(NSDictionary *)eventProperties
                         location:(CLLocationCoordinate2D)location
                         andItems:(NSArray<NSDictionary *> *)items {
    if (self = [super init]) {
        self.eventName = eventName;
        self.eventProperties = eventProperties;
        self.location = location;
        self.items = items;
    }
    return self;
}

- (CTTriggerValue *)propertyValueNamed:(NSString *)name {
    if (self.eventProperties[name] == nil) {
        return nil;
    }
    return [[CTTriggerValue alloc] initWithValue:self.eventProperties[name]];
}

- (CTTriggerValue *)itemValueNamed:(NSString *)name {
    if (self.items == nil) {
        return nil;
    }
    NSMutableArray *itemValues = [NSMutableArray new];
    for (NSDictionary *item in self.items) {
        id value = item[name];
        if (value) {
            [itemValues addObject:value];
        }
    }
    
    return itemValues.count > 0 ? [[CTTriggerValue alloc] initWithValue:itemValues] : nil;
}

@end
