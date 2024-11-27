//
//  EventAdapter.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTEventAdapter.h"
#import "CTConstants.h"
#import "CTUtils.h"

static NSDictionary<NSString*, NSString*> *systemPropToKey;

@interface CTEventAdapter()

@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, strong, nullable) NSString *profileAttrName;

@end

@implementation CTEventAdapter

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // System property new and legacy keys to App Fields key
        systemPropToKey = @{
            @"CT App Version": CLTAP_APP_VERSION,
            @"ct_app_version": CLTAP_APP_VERSION,
            @"CT Latitude": CLTAP_LATITUDE,
            @"ct_latitude": CLTAP_LATITUDE,
            @"CT Longitude": CLTAP_LONGITUDE,
            @"ct_longitude": CLTAP_LONGITUDE,
            @"CT OS Version": CLTAP_OS_VERSION,
            @"ct_os_version": CLTAP_OS_VERSION,
            @"CT SDK Version": CLTAP_SDK_VERSION,
            @"ct_sdk_version": CLTAP_SDK_VERSION,
            @"CT Network Carrier": CLTAP_CARRIER,
            @"ct_network_carrier": CLTAP_CARRIER,
            @"CT Network Type": CLTAP_NETWORK_TYPE,
            @"ct_network_type": CLTAP_NETWORK_TYPE,
            @"CT Connected To WiFi": CLTAP_CONNECTED_TO_WIFI,
            @"ct_connected_to_wifi": CLTAP_CONNECTED_TO_WIFI,
            @"CT Bluetooth Version": CLTAP_BLUETOOTH_VERSION,
            @"ct_bluetooth_version": CLTAP_BLUETOOTH_VERSION,
            @"CT Bluetooth Enabled": CLTAP_BLUETOOTH_ENABLED,
            @"ct_bluetooth_enabled": CLTAP_BLUETOOTH_ENABLED,
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

- (instancetype)initWithEventName:(NSString *)eventName
                  profileAttrName:(NSString *)profileAttrName
                  eventProperties:(NSDictionary *)eventProperties
                      andLocation:(CLLocationCoordinate2D)location{
    
    if (self = [super init]) {
        self = [self initWithEventName:eventName eventProperties:eventProperties location:location andItems:@[]];
        self.profileAttrName = profileAttrName;
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
    id value = [self getPropertyValue:propertyName];
    
    if (value == nil) {
        if ([propertyName isEqualToString:CLTAP_PROP_CAMPAIGN_ID]) {
            value = [self getPropertyValue:CLTAP_PROP_WZRK_ID];
        } else if ([propertyName isEqualToString:CLTAP_PROP_WZRK_ID]) {
            value = [self getPropertyValue:CLTAP_PROP_CAMPAIGN_ID];
        } else if ([propertyName isEqualToString:CLTAP_PROP_VARIANT]) {
            value = [self getPropertyValue:CLTAP_PROP_WZRK_PIVOT];
        } else if ([propertyName isEqualToString:CLTAP_PROP_WZRK_PIVOT]) {
            value = [self getPropertyValue:CLTAP_PROP_VARIANT];
        } else if (systemPropToKey[propertyName]) {
            // Map App Fields
            value = [self getPropertyValue:systemPropToKey[propertyName]];
        }
    }
    return value;
}

- (id)getPropertyValue:(NSString *)propertyName {
    id value = self.eventProperties[propertyName];
    
    if (value == nil) {
        // Normalize the property name
        propertyName = [CTUtils getNormalizedName:propertyName];
        value = self.eventProperties[propertyName];
    }
    
    if (value == nil) {
        // Check if event properties name are normalized equal
        for (NSString *key in self.eventProperties) {
            if ([CTUtils areEqualNormalizedName:key andName:propertyName]) {
                value = self.eventProperties[key];
                break;
            }
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
        if (value == nil) {
            NSString *normalizedName = [CTUtils getNormalizedName:name];
            value = item[normalizedName];
        }
        if (value == nil) {
            // Normalize the keys in the dictionary
            NSMutableDictionary *normalizedItem = [NSMutableDictionary dictionary];
            for (NSString *key in item) {
                NSString *normalizedKey = [CTUtils getNormalizedName:key];
                normalizedItem[normalizedKey] = item[key];
            }
            value = normalizedItem[[CTUtils getNormalizedName:name]];
        }
        
        if (value) {
            [itemValues addObject:value];
        }
    }
    
    return itemValues.count > 0 ? [[CTTriggerValue alloc] initWithValue:itemValues] : nil;
}

@end
