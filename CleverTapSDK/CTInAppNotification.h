
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"

@interface CTInAppNotification : NSObject

@property (nonatomic, readonly) NSString* Id;
@property (nonatomic, readonly) NSString* campaignId;
@property (nonatomic, readonly) CTInAppType inAppType;
@property (nonatomic, copy, readonly) NSString *html;
@property (nonatomic, readonly) BOOL excludeFromCaps;
@property (nonatomic, readonly) BOOL showClose;
@property (nonatomic, readonly) BOOL darkenScreen;
@property (nonatomic, readonly) int maxPerSession;
@property (nonatomic, readonly) int totalLifetimeCount;
@property (nonatomic, readonly) int totalDailyCount;
@property (nonatomic, assign, readonly) char position;
@property (nonatomic, assign, readonly) float height;
@property (nonatomic, assign, readonly) float heightPercent;
@property (nonatomic, assign, readonly) float width;
@property (nonatomic, assign, readonly) float widthPercent;

@property (nonatomic, copy, readonly) NSDictionary *jsonDescription;
@property (nonatomic, readonly) NSString *error;

@property (nonatomic, copy, readonly) NSDictionary *customExtras;
@property (nonatomic, copy, readwrite) NSDictionary *actionExtras;

- (instancetype)init __unavailable;
- (instancetype)initWithJSON:(NSDictionary*)json;

- (void)prepareWithCompletionHandler: (void (^)(void))completionHandler;


@end
