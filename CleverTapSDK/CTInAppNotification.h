
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"
#import "CTNotificationButton.h"

@interface CTInAppNotification : NSObject

@property (nonatomic, readonly) NSString *Id;
@property (nonatomic, readonly) NSString *campaignId;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, readonly) CTInAppType inAppType;

@property (nonatomic, copy, readonly) NSString *html;
@property (nonatomic, copy, readonly) NSString *url;
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

@property (nonatomic, readonly) NSData *image;
@property (nonatomic, readonly) NSData *imageLandscape;
@property (nonatomic, copy, readonly) NSString *contentType;
@property (nonatomic, copy, readonly) NSString *mediaUrl;
@property (nonatomic, readonly, assign) BOOL mediaIsVideo;
@property (nonatomic, readonly, assign) BOOL mediaIsAudio;
@property (nonatomic, readonly, assign) BOOL mediaIsImage;
@property (nonatomic, readonly, assign) BOOL mediaIsGif;

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *titleColor;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSString *messageColor;
@property (nonatomic, copy, readonly) NSString *backgroundColor;

@property (nonatomic, readonly, assign) BOOL showCloseButton;
@property (nonatomic, readonly, assign) BOOL tablet;
@property (nonatomic, readonly, assign) BOOL hasLandscape;
@property (nonatomic, readonly, assign) BOOL hasPortrait;

@property (nonatomic, readonly) NSArray<CTNotificationButton *> *buttons;

@property (nonatomic, copy, readonly) NSDictionary *jsonDescription;
@property (nonatomic, readonly) NSString *error;

@property (nonatomic, copy, readonly) NSDictionary *customExtras;
@property (nonatomic, copy, readwrite) NSDictionary *actionExtras;

- (instancetype)init __unavailable;
- (instancetype)initWithJSON:(NSDictionary*)json;

- (void)prepareWithCompletionHandler: (void (^)(void))completionHandler;


@end
