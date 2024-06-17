//
//  CTNotificationAction.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 9.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTNotificationAction.h"

@interface CTNotificationAction()

@property (nonatomic, readwrite) CTInAppActionType type;
@property (nonatomic, copy, readwrite) NSURL *actionURL;
@property (nonatomic, strong, readwrite) NSDictionary *keyValues;
@property (nonatomic, readwrite) BOOL fallbackToSettings;
@property (nonatomic, strong, readwrite) CTCustomTemplateInAppData *customTemplateInAppData;
@property (nonatomic, readwrite) NSString *error;

@end

@implementation CTNotificationAction

- (nonnull instancetype)initWithJSON:(nonnull NSDictionary *)json {
    if (self = [super init]) {
        @try {
            id kv = json[@"kv"];
            if ([kv isKindOfClass:[NSDictionary class]]) {
                self.keyValues = kv;
            }
            NSString *action = json[@"ios"];
            if (action && action.length > 0) {
                @try {
                    self.actionURL = [NSURL URLWithString:action];
                } @catch (NSException *e) {
                    self.error = [e debugDescription];
                }
            }
            NSString *type = json[@"type"];
            self.type = [CTInAppUtils inAppActionTypeFromString:type];
            self.fallbackToSettings = json[@"fbSettings"] ? [json[@"fbSettings"] boolValue] : NO;
            self.customTemplateInAppData = [CTCustomTemplateInAppData createWithJSON:json];
        } @catch (NSException *e) {
            self.error = [e debugDescription];
        }
    }
    return self;
}

- (nonnull instancetype)initWithOpenURL:(nonnull NSURL *)url {
    if (self = [super init]) {
        self.type = CTInAppActionTypeOpenURL;
        self.actionURL = url;
    }
    return self;
}

@end
