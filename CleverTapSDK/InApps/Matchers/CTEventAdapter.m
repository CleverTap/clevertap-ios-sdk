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

static NSDictionary<NSString*, NSString*> *systemPropToKey;

@interface CTEventAdapter()

@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDictionary *eventProperties;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, assign) CLLocationCoordinate2D location;

@end

@implementation CTEventAdapter

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        systemPropToKey = @{
            @"CT App Version": @"Version",
            @"ct_app_version": @"Version",
            @"CT Latitude": @"Latitude",
            @"ct_latitude": @"Latitude",
            @"CT Longitude": @"Longitude",
            @"ct_longitude": @"Longitude",
            @"CT OS Version": @"OS Version",
            @"ct_os_version": @"OS Version",
            @"CT SDK Version": @"SDK Version",
            @"ct_sdk_version": @"SDK Version",
            @"CT Network Carrier": @"Carrier",
            @"ct_network_carrier": @"Carrier",
            @"CT Network Type": @"Radio",
            @"ct_network_type": @"Radio",
            @"CT Connected To WiFi": @"wifi",
            @"ct_connected_to_wifi": @"wifi",
            @"CT Bluetooth Version": @"BluetoothVersion",
            @"ct_bluetooth_version": @"BluetoothVersion",
            @"CT Bluetooth Enabled": @"BluetoothEnabled",
            @"ct_bluetooth_enabled": @"BluetoothEnabled",
            @"CT App Name": @"appnId"
        };
    });
}

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
        } else if (systemPropToKey[propertyName]) {
            // Map App Fields
            value = self.eventProperties[systemPropToKey[propertyName]];
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
