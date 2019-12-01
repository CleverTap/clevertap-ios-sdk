#import <Foundation/Foundation.h>
#import "CleverTap.h"
@class CTAdUnitUtils;
@class CleverTapAdUnitContent;

/*!

@abstract
The `CleverTapAdUnit` represents the Ad Unit object.
*/

@interface CleverTapAdUnit : NSObject

- (instancetype _Nullable )initWithJSON:(NSDictionary *_Nullable)json;

/*!
* json defines the ad unit data in the form of NSDictionary.
*/
@property (nullable, nonatomic, copy, readonly) NSDictionary *json;
/*!
* adID defines the ad unit identifier.
*/
@property (nullable, nonatomic, copy, readonly) NSString *adID;
/*!
* type defines the ad unit type.
*/
@property (nullable, nonatomic, copy, readonly) NSString *type;
/*!
* orientation defines the orientation of the ad unit.
*/
@property (nullable, nonatomic, copy, readonly) NSString *orientation;
/*!
* customExtras defines the extra data in the form of an NSDictionary. The extra key/value pairs set in the CleverTap dashboard.
*/
@property (nullable, nonatomic, copy, readonly) NSDictionary *customExtras;
/*!
* content defines the content of the ad unit.
*/
@property (nullable, nonatomic, copy, readonly) NSArray<CleverTapAdUnitContent *> *content;

@end

/*!

@abstract
 The `CleverTapAdUnitContent` represents the Ad Unit content.
*/
@interface CleverTapAdUnitContent : NSObject

@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nullable, nonatomic, copy, readonly) NSString *titleColor;
@property (nullable, nonatomic, copy, readonly) NSString *message;
@property (nullable, nonatomic, copy, readonly) NSString *messageColor;
@property (nullable, nonatomic, copy, readonly) NSString *backgroundColor;
@property (nullable, nonatomic, copy, readonly) NSString *videoPosterUrl;
@property (nullable, nonatomic, copy, readonly) NSString *actionUrl;
@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
@property (nullable, nonatomic, copy, readonly) NSString *iconUrl;
@property (nonatomic, readonly, assign) BOOL mediaIsAudio;
@property (nonatomic, readonly, assign) BOOL mediaIsVideo;
@property (nonatomic, readonly, assign) BOOL mediaIsImage;
@property (nonatomic, readonly, assign) BOOL mediaIsGif;

- (instancetype _Nullable )initWithJSON:(NSDictionary *_Nullable)jsonObject;

@end

@protocol CleverTapAdUnitDelegate <NSObject>
@optional
- (void)adUnitsDidReceive:(NSArray<CleverTapAdUnit *>*_Nonnull)adUnits;
@end

typedef void (^CleverTapAdUnitSuccessBlock)(BOOL success);

@interface CleverTap (AdUnit)

/*!

@method

@abstract
The `CleverTapAdUnitDelegate` protocol provides methods for notifying
your application (the adopting delegate) about ad units.

@discussion
This sets the CleverTapAdUnitDelegate.

@param delegate     an object conforming to the CleverTapAdUnitDelegate Protocol
*/
- (void)setAdUnitDelegate:(id <CleverTapAdUnitDelegate>_Nonnull)delegate;
/*!
@method

@abstract
Record Notification Viewed for Ad Unit.

@param adID       ad unit identifier
*/
- (void)recordAdUnitViewedEventForID:(NSString *_Nonnull)adID;
/*!
@method

@abstract
Record Notification Clicked for Ad Unit.

@param adID       ad unit identifier
*/
- (void)recordAdUnitClickedEventForID:(NSString *_Nonnull)adID;

@end
