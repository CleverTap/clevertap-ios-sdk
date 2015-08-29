//
//  WizRocket.h
//  WizRocketSDK
//
//  Copyright (c) 2014 WizRocket. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WizRocketEventDetail.h"
#import "WizRocketUTMDetail.h"

@interface WizRocket : NSObject

+ (WizRocket *)push;
+ (WizRocket *)event;
+ (WizRocket *)profile;
+ (WizRocket *)session;

+ (void)changeCredentialsWithAccountID:(NSString *) accountID andToken:(NSString *) token;

- (void)eventName:(NSString *)event;
- (void)eventName:(NSString *)event eventProps:(NSDictionary *)properties;
- (void)chargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items;

- (void)profile:(NSDictionary *)profileDictionary;
- (void)graphUser:(id)fbGraphUser;
- (void)googlePlusUser:(id)googleUser;

- (void)enumWithKey:(NSString *)key andValue:(NSString *)value __deprecated;
- (void)enums:(NSDictionary *)enumsDictionary __deprecated;
- (void)profile:(NSDictionary *)profileDictionary enums:(NSDictionary *)enumsDictionary __deprecated;


+ (void) enablePersonalization;


+ (void)setDebugLevel:(int)level;

+ (void)setPushToken:(NSData *)pushToken;

+ (void)notifyApplicationLaunchedWithOptions:(NSDictionary *)launchOptions;
+ (void)showInAppNotificationIfAny;
+ (void)handleNotificationWithData:(id)data;

+ (void)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

+ (void)notifyViewLoaded:(UIViewController *) viewController __deprecated;

+ (void)pushInstallReferrerSource:(NSString*) source
                           medium:(NSString*) medium
                         campaign:(NSString*) campaign;

#pragma mark Event API messages
- (NSTimeInterval) getFirstTime:(NSString*) event;
- (NSTimeInterval) getLastTime:(NSString*) event;
- (int) getOccurrences:(NSString*) event;
- (NSDictionary *) getHistory;
- (WizRocketEventDetail*) getEventDetail:(NSString *) event;

#pragma mark Profile API messages
- (id) getProperty:(NSString*) propertyName;

#pragma mark Session API messages
- (NSTimeInterval) getTimeElapsed;
- (int) getTotalVisits;
- (int) getScreenCount;
- (NSTimeInterval) getPreviousVisitTime;
- (WizRocketUTMDetail *) getUTMDetails;
@end
