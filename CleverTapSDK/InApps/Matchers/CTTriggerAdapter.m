//
//  TriggerAdapter.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggerAdapter.h"

@interface CTTriggerAdapter()

@property (nonatomic, strong) NSString *eventName;

@property (nonatomic, strong) NSArray *properties;
@property (nonatomic, strong) NSArray *items;

@end

@implementation CTTriggerAdapter

- (instancetype)initWithJSON:(NSDictionary *)triggerJSON {
    if (self = [super init]) {
        self.eventName = triggerJSON[@"eventName"];
        self.properties = triggerJSON[@"eventProperties"];
        self.items = triggerJSON[@"itemProperties"];
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

- (CTTriggerCondition * _Nonnull)triggerConditionFromJSON:(NSDictionary *)property {
    CTTriggerValue *value = [[CTTriggerValue alloc] initWithValue:property[@"value"]];
    
    return [[CTTriggerCondition alloc] initWithProperyName:property[@"propertyName"]
                                             andOperator:property[@"operator"]
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

@end
