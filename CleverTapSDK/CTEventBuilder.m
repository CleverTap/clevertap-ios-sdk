#import <UIKit/UIKit.h>
#import "CTEventBuilder.h"
#import "CTValidationResult.h"
#import "CTValidator.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CleverTap+Inbox.h"
#import "CleverTap+DisplayUnit.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTInAppNotification.h"
#endif

@implementation CTEventBuilder

+ (NSMutableDictionary *)getErrorObject:(CTValidationResult *)vr {
    NSMutableDictionary *error = [[NSMutableDictionary alloc] init];
    @try {
        error[@"c"] = @([vr errorCode]);
        error[@"d"] = [vr errorDesc];
    } @catch (NSException *e) {
        // no-op
    }
    return error;
}

/**
 * Build a basic event.
 *
 * @param eventName The name of the event
 */
+ (void)build:(NSString *)eventName completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
    [self build:eventName withEventActions:nil completionHandler:completion];
}

/**
 * Build an event with a set of attribute pairs.
 *
 */
+ (void)build:(NSString *)eventName withEventActions:(NSDictionary *)eventActions completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    
    if (eventName == nil || [eventName isEqualToString:@""]) {
        completion(nil, errors);
        return;
    }
    // Check for a restricted event name
    if ([CTValidator isRestrictedEventName:eventName]) {
        [errors addObject:[CTValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Restricted event name - %@", eventName]]];
        CleverTapLogStaticDebug(@"Restricted event name: %@", eventName);
        completion(nil, errors);
        return;
    }
    
    // Check for a discarded event name
    if ([CTValidator isDiscaredEventName:eventName]) {
        [errors addObject:[CTValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Discarded event name - %@", eventName]]];
        CleverTapLogStaticDebug(@"%@%@%@", eventName, @" is a discarded event, dropping event: ", eventName);
        completion(nil, errors);
        return;
    }
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    @try {
        // Validate
        CTValidationResult *vr = [CTValidator cleanEventName:eventName];
        if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
            [errors addObject:[CTValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Invalid event name - %@", eventName]]];
            CleverTapLogStaticDebug(@"Invalid event name: %@", eventName);
            // Abort
            completion(nil, errors);
            return;
        }
        // Check for an error
        if ([vr errorCode] != 0) {
            event[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
            if ([vr errorDesc] != nil) {
                CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
            }
        }
        eventName = (NSString *) [vr object];
        
        NSMutableDictionary *actions = [[NSMutableDictionary alloc] init];
        NSMutableArray *eventActionsAllKeys;
        if (eventActions) {
            eventActionsAllKeys = [NSMutableArray arrayWithArray:[eventActions allKeys]];
        } else {
            eventActionsAllKeys = [NSMutableArray new];
        }
        for (int i = 0; i < [eventActionsAllKeys count]; i++) {
            NSString *key = eventActionsAllKeys[(NSUInteger) i];
            id value = eventActions[key];
            vr = [CTValidator cleanObjectKey:key];
            if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                [errors addObject:[CTValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Invalid event property key: %@", key]]];
                CleverTapLogStaticDebug(@"Invalid event property key: %@", key);
                // Skip
                continue;
            }
            key = (NSString *) [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                event[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            BOOL accepted = false;
            @try {
                vr = [CTValidator cleanObjectValue:value context:CTValidatorContextEvent];
                accepted = [vr object] != nil;
            } @catch (NSException *e) {
                accepted = false;
            }
            if (!accepted) {
                NSString *errStr = [NSString stringWithFormat:@"For event \"%@\": Property value for property %@ wasn't a primitive (%@)", eventName, key, value];
                CleverTapLogStaticDebug(@"%@", errStr);
                CTValidationResult *error = [[CTValidationResult alloc] init];
                [error setErrorCode:512];
                [error setErrorDesc:errStr];
                [errors addObject:error];
                // Skip this property
                continue;
            }
            value = [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                event[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            actions[key] = value;
        }
        event[CLTAP_EVENT_NAME] = eventName;
        event[CLTAP_EVENT_DATA] = actions;
        completion(event, errors);
    } @catch (NSException *e) {
        completion(nil, errors);
    }
}

/**
 * Build an event which describes a purchase made.
 *
 */
+ (void)buildChargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    
    if (chargeDetails == nil || items == nil) {
        completion(nil, errors);
        return;
    }
    
    if (((int) [items count]) > 50) {
        CTValidationResult *error = [[CTValidationResult alloc] init];
        [error setErrorCode:522];
        [error setErrorDesc:@"Charged event contained more than 50 items."];
        CleverTapLogStaticDebug(@"Charged event contained more than 50 items.");
        [errors addObject:error];
    }
    NSMutableDictionary *evtData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *chargedEvent = [[NSMutableDictionary alloc] init];
    CTValidationResult *vr;
    @try {
        NSMutableArray *chargeDetailsAllKeys = [NSMutableArray arrayWithArray:[chargeDetails allKeys]];
        for (int i = 0; i < [chargeDetailsAllKeys count]; i++) {
            NSString *key = chargeDetailsAllKeys[(NSUInteger) i];
            id value = chargeDetails[key];
            vr = [CTValidator cleanObjectKey:key];
            if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                // Skip
                continue;
            }
            key = (NSString *) [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            BOOL accepted = false;
            @try {
                vr = [CTValidator cleanObjectValue:value context:CTValidatorContextEvent];
                accepted = [vr object] != nil;
            } @catch (NSException *e) {
                accepted = false;
            }
            if (!accepted) {
                NSString *errStr = [NSString stringWithFormat:@"For event Charged: Property value for property %@ wasn't a primitive (%@)", key, value];
                CleverTapLogStaticDebug(@"%@", errStr);
                CTValidationResult *error = [[CTValidationResult alloc] init];
                [error setErrorCode:511];
                [error setErrorDesc:errStr];
                [errors addObject:error];
                // Skip
                continue;
            }
            value = [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            evtData[key] = value;
        }
        NSMutableArray *jsonItemsArray = [[NSMutableArray alloc] init];
        for (id map in items) {
            if ([map isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *itemDetails = [[NSMutableDictionary alloc] init];
                NSMutableArray *mapAllKeys = [NSMutableArray arrayWithArray:[map allKeys]];
                for (int i = 0; i < [mapAllKeys count]; i++) {
                    NSString *key = mapAllKeys[(NSUInteger) i];
                    id value = [map objectForKey:key];
                    vr = [CTValidator cleanObjectKey:key];
                    if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                        // Abort
                        completion(nil, errors);
                        return;
                    }
                    key = (NSString *) [vr object];
                    // Check for an error
                    if ([vr errorCode] != 0) {
                        chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                        if ([vr errorDesc] != nil) {
                            CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                        }
                    }
                    BOOL accepted = false;
                    @try {
                        vr = [CTValidator cleanObjectValue:value context:CTValidatorContextEvent];
                        accepted = [vr object] != nil;
                    } @catch (NSException *e) {
                        accepted = false;
                    }
                    if (!accepted) {
                        NSString *errStr = [NSString stringWithFormat:@"An item's object value for key %@ wasn't a primitive (%@)", key, value];
                        CleverTapLogStaticDebug(@"%@", errStr);
                        CTValidationResult *error = [[CTValidationResult alloc] init];
                        [error setErrorCode:511];
                        [error setErrorDesc:errStr];
                        [errors addObject:error];
                        // Skip
                        continue;
                    }
                    value = [vr object];
                    // Check for an error
                    if ([vr errorCode] != 0) {
                        chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                        if ([vr errorDesc] != nil) {
                            CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                        }
                    }
                    itemDetails[key] = value;
                }
                [jsonItemsArray addObject:itemDetails];
            }
        }
        evtData[CLTAP_CHARGED_EVENT_ITEMS] = jsonItemsArray;
        
        chargedEvent[CLTAP_EVENT_NAME] = CLTAP_CHARGED_EVENT;
        chargedEvent[CLTAP_EVENT_DATA] = evtData;
        completion(chargedEvent, errors);
    } @catch (NSException *e) {
        completion(nil, errors);
    }
}

/**
 * Raises the Notification Clicked event for Push Notifications event, if clicked is true,
 * otherwise the Notification Viewed event for Push Notifications event, if clicked is false.
 *
 */
+ (void)buildPushNotificationEvent:(BOOL)clicked
                   forNotification:(NSDictionary *)notification
                 completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
    if (!notification){
        completion(nil, nil);
        return;
    }
    @try {
        NSMutableDictionary *event = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        // only send through our push data
        for (NSString *x in [notification allKeys]) {
            if (!([CTUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG] || [CTUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG_SECONDARY]))
                continue;
            NSString *key = [x stringByReplacingOccurrencesOfString:CLTAP_NOTIFICATION_TAG withString:CLTAP_WZRK_PREFIX];
            id value = notification[x];
            notif[key] = value;
        }
        notif[CLTAP_NOTIFICATION_CLICKED_TAG] = @((long) [[NSDate date] timeIntervalSince1970]);
        event[CLTAP_EVENT_NAME] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[CLTAP_EVENT_DATA] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        CleverTapLogStaticDebug(@"Unable to build push notification clicked event: %@", e.debugDescription);
        completion(nil, nil);
    }
}

/**
 * Raises the Notification Clicked event, if clicked is true,
 * otherwise the Notification Viewed event, if clicked is false.
 *
 */
+ (void)buildInAppNotificationStateEvent:(BOOL)clicked
                         forNotification:(CTInAppNotification *)notification
                      andQueryParameters:(NSDictionary *)params
                       completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
#if !CLEVERTAP_NO_INAPP_SUPPORT
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
    @try {
        NSDictionary *data = notification.jsonDescription;
        for (NSString *x in [data allKeys]) {
            if (![CTUtils doesString:x startWith:@"wzrk_"])
                continue;
            id value = data[x];
            notif[x] = value;
        }
        if (params) {
            [notif addEntriesFromDictionary:params];
        }
        if ([notif count] == 0) {
            CleverTapLogStaticInternal(@"Notification does not have any wzrk_* field");
        }
        event[CLTAP_EVENT_NAME] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[CLTAP_EVENT_DATA] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
#else
        completion(nil, nil);
#endif
}

/**
 * Raises the Inbox Message Clicked event, if clicked is true,
 * otherwise the Inbox Message Viewed event, if clicked is false.
 *
 */
+ (void)buildInboxMessageStateEvent:(BOOL)clicked
                         forMessage:(CleverTapInboxMessage *)message
                 andQueryParameters:(NSDictionary *)params
                  completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
    @try {
        NSDictionary *data = message.json;
        for (NSString *x in [data allKeys]) {
            if (![CTUtils doesString:x startWith:@"wzrk_"])
                continue;
            id value = data[x];
            notif[x] = value;
        }
        if (params) {
            [notif addEntriesFromDictionary:params];
        }
        if ([notif count] == 0) {
            CleverTapLogStaticInternal(@"Inbox Message does not have any wzrk_* field");
        }
        event[CLTAP_EVENT_NAME] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[CLTAP_EVENT_DATA] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

/**
 * Raises the Native Display Clicked event, if clicked is true,
 * otherwise the Native Display Viewed event, if clicked is false.
 *
 */
+ (void)buildDisplayViewStateEvent:(BOOL)clicked
                    forDisplayUnit:(CleverTapDisplayUnit *)displayUnit
                andQueryParameters:(NSDictionary *)params
                 completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion {
    @try {
        NSMutableDictionary *event = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        NSDictionary *data = displayUnit.json;
        for (NSString *x in [data allKeys]) {
            if (!([CTUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG] || [CTUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG_SECONDARY]))
                continue;
            NSString *key = [x stringByReplacingOccurrencesOfString:CLTAP_NOTIFICATION_TAG withString:CLTAP_WZRK_PREFIX];
            id value = data[x];
            notif[key] = value;
        }
        notif[CLTAP_NOTIFICATION_CLICKED_TAG] = @((long) [[NSDate date] timeIntervalSince1970]);
        event[CLTAP_EVENT_NAME] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[CLTAP_EVENT_DATA] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

/**
 * Raises the Geofence Entered event, if entered is true,
 * otherwise the Geofence Exited event, if entered is false.
 *
 */
+ (void)buildGeofenceStateEvent:(BOOL)entered
             forGeofenceDetails:(NSDictionary * _Nonnull)geofenceDetails
              completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion {
    @try {
        NSMutableDictionary *event = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        if (geofenceDetails) {
            [notif addEntriesFromDictionary:geofenceDetails];
        }
        if ([notif count] == 0) {
            CleverTapLogStaticInternal(@"Geofence does not have any field");
        }
        event[CLTAP_EVENT_NAME] = entered ? CLTAP_GEOFENCE_ENTERED_EVENT_NAME : CLTAP_GEOFENCE_EXITED_EVENT_NAME;
        event[CLTAP_EVENT_DATA] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

/**
 * Raises and logs Signed Call system events
 */
+ (void)buildSignedCallEvent:(int)eventRawValue
              forCallDetails:(NSDictionary * _Nonnull)callDetails
           completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    CTValidationResult *error = [[CTValidationResult alloc] init];
    [error setErrorCode: 524];
    [error setErrorDesc: @"Signed Call does not have any field"];
    @try {
        NSMutableDictionary *eventDic = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        [notif addEntriesFromDictionary:callDetails];
        
        if ([notif count] == 0) {
            [errors addObject: error];
            CleverTapLogStaticDebug(@"Signed Call does not have any field");
        }
        NSString *signedCallEvent;
        switch (eventRawValue) {
            case 0:
                signedCallEvent = CLTAP_SIGNED_CALL_OUTGOING_EVENT_NAME;
                break;
            case 1:
                signedCallEvent = CLTAP_SIGNED_CALL_INCOMING_EVENT_NAME;
                break;
            case 2:
                signedCallEvent = CLTAP_SIGNED_CALL_END_EVENT_NAME;
                break;
            default: break;
        }
        if (signedCallEvent) {
            eventDic[CLTAP_EVENT_NAME] = signedCallEvent;
            eventDic[CLTAP_EVENT_DATA] = notif;
            completion(eventDic, errors);
        } else {
            CTValidationResult *error = [[CTValidationResult alloc] init];
            [error setErrorCode: 525];
            [error setErrorDesc: @"Signed Call did not specify event name"];
            [errors addObject: error];
            CleverTapLogStaticDebug(@"Signed Call did not specify event name");
            completion(nil, errors);
        }
    } @catch (NSException *e) {
        CleverTapLogStaticDebug(@"Unable to build signed call event: %@", e.debugDescription);
        completion(nil, errors);
    }
}

@end
