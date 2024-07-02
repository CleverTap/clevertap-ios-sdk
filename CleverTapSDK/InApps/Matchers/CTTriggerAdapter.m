//
//  TriggerAdapter.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggerAdapter.h"
#import "CTConstants.h"

@interface CTTriggerAdapter()

@property (nonatomic, strong) NSString *eventName;

@property (nonatomic, strong) NSArray *properties;
@property (nonatomic, strong) NSArray *items;

@property (nonatomic, strong) NSArray *geoRadius;
@property (nonatomic, strong) NSString *profileAttrName;

@end

@implementation CTTriggerAdapter

- (instancetype)initWithJSON:(NSDictionary *)triggerJSON {
    if (self = [super init]) {
        self.eventName = triggerJSON[@"eventName"];
        self.properties = triggerJSON[@"eventProperties"];
        self.items = triggerJSON[@"itemProperties"];
        self.geoRadius = triggerJSON[@"geoRadius"];
        self.profileAttrName = triggerJSON[@"profileAttrName"];
    }
    return self;
}

- (NSInteger)propertyCount {
    if (self.properties == nil) {
        return 0;
    }
    
    return self.properties.count;
}

- (NSInteger)itemsCount {
    if (self.items == nil) {
        return 0;
    }
    
    return self.items.count;
}

- (NSInteger)geoRadiusCount {
    if (self.geoRadius == nil) {
        return 0;
    }
    
    return self.geoRadius.count;
}

- (CTTriggerCondition * _Nonnull)triggerConditionFromJSON:(NSDictionary *)property {
    CTTriggerValue *value = [[CTTriggerValue alloc] initWithValue:property[@"propertyValue"]];
    
    NSUInteger operator = CTTriggerOperatorEquals;
    NSNumber *op = property[@"operator"];
    if([op respondsToSelector:@selector(unsignedIntegerValue)]) {
        operator = [op unsignedIntegerValue];
    } else {
        CleverTapLogStaticDebug(@"Cannot parse operator: %@.", property[@"operator"]);
    }
    
    return [[CTTriggerCondition alloc] initWithProperyName:property[@"propertyName"]
                                             andOperator:operator
                                                andValue:value];
}

- (CTTriggerCondition *)propertyAtIndex: (NSInteger)index {
    if (self.properties == nil) {
        return nil;
    }
    NSDictionary *property = self.properties[index];
    
    return [self triggerConditionFromJSON:property];
}

- (CTTriggerCondition *)itemAtIndex: (NSInteger)index {
    if (self.items == nil) {
        return nil;
    }
    NSDictionary *item = self.items[index];
    
    return [self triggerConditionFromJSON:item];
}

- (CTTriggerRadius *)geoRadiusAtIndex: (NSInteger)index {
    if (self.geoRadius == nil) {
        return nil;
    }
    NSDictionary *item = self.geoRadius[index];
    
    CTTriggerRadius *triggerRadius = [[CTTriggerRadius alloc] init];
    triggerRadius.latitude = item[@"lat"];
    triggerRadius.longitude = item[@"lng"];
    triggerRadius.radius = item[@"rad"];
    
    return triggerRadius;
}

@end
