//
//  EventAdapter.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTEventAdapter.h"
#import "CTConstants.h"
#import "CTCampaignType.h"

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
    id propertyValue = [self getActualPropertyValue:name];
    if (propertyValue) {
        return [[CTTriggerValue alloc] initWithValue:propertyValue];
    }
    return nil;
}

- (id)getActualPropertyValue:(NSString *)propertyName {
    id value = self.eventProperties[propertyName];
    if (value == nil) {
        if ([propertyName isEqualToString:CLTAP_PROP_CAMPAIGN_ID]) {
            value = self.eventProperties[CLTAP_PROP_WZRK_ID];
        } else if ([propertyName isEqualToString:CLTAP_PROP_WZRK_ID]) {
            value = self.eventProperties[CLTAP_PROP_CAMPAIGN_ID];
        } else if ([propertyName isEqualToString:CLTAP_PROP_VARIANT]) {
            value = self.eventProperties[CLTAP_PROP_WZRK_PIVOT];
        } else if ([propertyName isEqualToString:CLTAP_PROP_WZRK_PIVOT]) {
            value = self.eventProperties[CLTAP_PROP_VARIANT];
        }
    } else if ([propertyName isEqualToString:CLTAP_PROP_CAMPAIGN_TYPE] && self.eventProperties[CLTAP_PROP_WZRK_ID]) {
        // TODO: Check if this is needed. Currently the SDK does not set Campaign type property, so operators on it will never match
        // This is an actual system event (Notification Viewed/Clicked) which contains Campaign
        // Type set from LP being extra safe here as Campaign type can be part of other events
        // as well.
        NSInteger ordinal = [CTCampaignTypeHelper campaignTypeOrdinal:[value lowercaseString]];
        if (ordinal != -1) {
            value = @(ordinal);
        }
    }
    return value;
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
