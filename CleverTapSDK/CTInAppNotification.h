#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"
#import "CTNotificationButton.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTCustomTemplateInAppData.h"
#endif

@interface CTInAppNotification : NSObject

@property (nonatomic, readonly) NSString *Id;
@property (nonatomic, readonly) NSString *campaignId;
@property (nonatomic, readonly) CTInAppType inAppType;

@property (nonatomic, copy, readonly) NSString *html;
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, readonly) BOOL excludeFromCaps;
@property (nonatomic, readonly) BOOL showClose;
@property (nonatomic, readonly) BOOL darkenScreen;
@property (nonatomic, readonly) int maxPerSession;
@property (nonatomic, readonly) int totalLifetimeCount;
@property (nonatomic, readonly) int totalDailyCount;
@property (nonatomic, readonly) NSInteger timeToLive;
@property (nonatomic, assign, readonly) char position;
@property (nonatomic, assign, readonly) float height;
@property (nonatomic, assign, readonly) float heightPercent;
@property (nonatomic, assign, readonly) float width;
@property (nonatomic, assign, readonly) float widthPercent;

@property (nonatomic, copy, readonly) NSString *landscapeContentType;
@property (nonatomic, readonly) UIImage *inAppImage;
@property (nonatomic, readonly) UIImage *inAppImageLandscape;
@property (nonatomic, readonly) NSData *imageData;
@property (nonatomic, strong, readonly) NSURL *imageURL;
@property (nonatomic, readonly) NSData *imageLandscapeData;
@property (nonatomic, strong, readonly) NSURL *imageUrlLandscape;
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
@property (nonatomic) NSString *error;

@property (nonatomic, copy, readonly) NSDictionary *customExtras;
@property (nonatomic, copy, readwrite) NSDictionary *actionExtras;

@property (nonatomic, readonly) BOOL isLocalInApp;
@property (nonatomic, readonly) BOOL isPushSettingsSoftAlert;
@property (nonatomic, readonly) BOOL fallBackToNotificationSettings;
@property (nonatomic, readonly) BOOL skipSettingsAlert;

@property (nonatomic, readonly) CTCustomTemplateInAppData *customTemplateInAppData;

- (instancetype)init __unavailable;
#if !CLEVERTAP_NO_INAPP_SUPPORT
- (instancetype)initWithJSON:(NSDictionary*)json;
#endif

+ (NSString * _Nullable)inAppId:(NSDictionary * _Nullable)inApp;

- (void)setPreparedInAppImage:(UIImage * _Nullable)inAppImage
               inAppImageData:(NSData * _Nullable)inAppImageData error:(NSString * _Nullable)error;

- (void)setPreparedInAppImageLandscape:(UIImage * _Nullable)inAppImageLandscape
               inAppImageLandscapeData:(NSData * _Nullable)inAppImageLandscapeData error:(NSString * _Nullable)error;

@end
