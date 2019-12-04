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
* bgColor defines the backgroundColor of the ad unit.
*/
@property (nullable, nonatomic, copy, readonly) NSString *bgColor;
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
/*!
* title  defines the title section of the ad unit content.
*/
@property (nullable, nonatomic, copy, readonly) NSString *title;
/*!
* titleColor defines hex-code value of the title color as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *titleColor;
/*!
* message  defines the message section of the ad unit content.
*/
@property (nullable, nonatomic, copy, readonly) NSString *message;
/*!
* messageColor defines hex-code value of the message color as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *messageColor;
/*!
* videoPosterUrl defines video URL of the ad unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *videoPosterUrl;
/*!
* actionUrl defines action URL of the ad unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *actionUrl;
/*!
* mediaUrl defines media URL of the ad unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
/*!
* iconUrl defines icon URL of the ad unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *iconUrl;
/*!
* mediaIsAudio check whether mediaUrl is an audio.
*/
@property (nonatomic, readonly, assign) BOOL mediaIsAudio;
/*!
* mediaIsVideo check whether mediaUrl is a video.
*/
@property (nonatomic, readonly, assign) BOOL mediaIsVideo;
/*!
* mediaIsImage check whether mediaUrl is an image.
*/
@property (nonatomic, readonly, assign) BOOL mediaIsImage;
/*!
* mediaIsGif check whether mediaUrl is a gif.
*/
@property (nonatomic, readonly, assign) BOOL mediaIsGif;

- (instancetype _Nullable )initWithJSON:(NSDictionary *_Nullable)jsonObject;

@end

@protocol CleverTapAdUnitDelegate <NSObject>
@optional
- (void)adUnitsUpdated:(NSArray<CleverTapAdUnit *>*_Nonnull)adUnits;
@end

typedef void (^CleverTapAdUnitSuccessBlock)(BOOL success);

@interface CleverTap (AdUnit)

/*!
@method

@abstract
This method returns all the ad units.
*/
- (NSArray<CleverTapAdUnit *>*_Nonnull)getAllAdUnits;
 
 /*!
 @method

 @abstract
 This method return ad unit for the provided adID
 */
- (CleverTapAdUnit *_Nullable)getAdUnitForID:(NSString *_Nonnull)adID;

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

@param adID      unique id of the ad unit
*/
- (void)recordAdUnitViewedEventForID:(NSString *_Nonnull)adID;

/*!
@method

@abstract
Record Notification Clicked for Ad Unit.

@param adID       unique id of the ad unit
*/
- (void)recordAdUnitClickedEventForID:(NSString *_Nonnull)adID;

@end
