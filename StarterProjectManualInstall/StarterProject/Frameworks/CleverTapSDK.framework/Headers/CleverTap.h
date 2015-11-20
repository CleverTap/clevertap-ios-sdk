#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CleverTapEventDetail.h"
#import "CleverTapUTMDetail.h"

@interface CleverTap : NSObject

+ (CleverTap *)push;
+ (CleverTap *)event;
+ (CleverTap *)profile;
+ (CleverTap *)session;

+ (void)changeCredentialsWithAccountID:(NSString *) accountID andToken:(NSString *) token;

- (void)eventName:(NSString *)event;
- (void)eventName:(NSString *)event eventProps:(NSDictionary *)properties;
- (void)chargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items;

- (void)profile:(NSDictionary *)profileDictionary;
- (void)graphUser:(id)fbGraphUser;
- (void)googlePlusUser:(id)googleUser;

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
- (CleverTapEventDetail *) getEventDetail:(NSString *) event;

#pragma mark Profile API messages
- (id) getProperty:(NSString*) propertyName;

#pragma mark Session API messages
- (NSTimeInterval) getTimeElapsed;
- (int) getTotalVisits;
- (int) getScreenCount;
- (NSTimeInterval) getPreviousVisitTime;
- (CleverTapUTMDetail *) getUTMDetails;
@end
