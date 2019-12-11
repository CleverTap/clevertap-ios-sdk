#import <Foundation/Foundation.h>
#import "CleverTap.h"
@class CleverTapDisplayUnitContent;

/*!

@abstract
The `CleverTapDisplayUnit` represents the display unit object.
*/
@interface CleverTapDisplayUnit : NSObject

- (instancetype _Nullable )initWithJSON:(NSDictionary *_Nullable)json;
/*!
* json defines the display unit data in the form of NSDictionary.
*/
@property (nullable, nonatomic, copy, readonly) NSDictionary *json;
/*!
* unitID defines the display unit identifier.
*/
@property (nullable, nonatomic, copy, readonly) NSString *unitID;
/*!
* type defines the display unit type.
*/
@property (nullable, nonatomic, copy, readonly) NSString *type;
/*!
* bgColor defines the backgroundColor of the display unit.
*/
@property (nullable, nonatomic, copy, readonly) NSString *bgColor;
/*!
* customExtras defines the extra data in the form of an NSDictionary. The extra key/value pairs set in the CleverTap dashboard.
*/
@property (nullable, nonatomic, copy, readonly) NSDictionary *customExtras;
/*!
* content defines the content of the display unit.
*/
@property (nullable, nonatomic, copy, readonly) NSArray<CleverTapDisplayUnitContent *> *contents;

@end

/*!

@abstract
 The `CleverTapDisplayUnitContent` represents the display unit content.
*/
@interface CleverTapDisplayUnitContent : NSObject
/*!
* title  defines the title section of the display unit content.
*/
@property (nullable, nonatomic, copy, readonly) NSString *title;
/*!
* titleColor defines hex-code value of the title color as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *titleColor;
/*!
* message  defines the message section of the display unit content.
*/
@property (nullable, nonatomic, copy, readonly) NSString *message;
/*!
* messageColor defines hex-code value of the message color as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *messageColor;
/*!
* videoPosterUrl defines video URL of the display unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *videoPosterUrl;
/*!
* actionUrl defines action URL of the display unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *actionUrl;
/*!
* mediaUrl defines media URL of the display unit as String.
*/
@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
/*!
* iconUrl defines icon URL of the display unit as String.
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

@protocol CleverTapDisplayUnitDelegate <NSObject>
@optional
- (void)displayUnitsUpdated:(NSArray<CleverTapDisplayUnit *>*_Nonnull)displayUnits;
@end

typedef void (^CleverTapDisplayUnitSuccessBlock)(BOOL success);

@interface CleverTap (DisplayUnit)

/*!
@method

@abstract
This method returns all the display units.
*/
- (NSArray<CleverTapDisplayUnit *>*_Nonnull)getAllDisplayUnits;
 
 /*!
 @method

 @abstract
 This method return display unit for the provided unitID
 */
- (CleverTapDisplayUnit *_Nullable)getDisplayUnitForID:(NSString *_Nonnull)unitID;

 /*!
@method

@abstract
The `CleverTapDisplayUnitDelegate` protocol provides methods for notifying
your application (the adopting delegate) about display units.

@discussion
This sets the CleverTapDisplayUnitDelegate.

@param delegate     an object conforming to the CleverTapDisplayUnitDelegate Protocol
*/
- (void)setDisplayUnitDelegate:(id <CleverTapDisplayUnitDelegate>_Nonnull)delegate;

/*!
@method

@abstract
Record Notification Viewed for display unit.

@param unitID      unique id of the display unit
*/
- (void)recordDisplayUnitViewedEventForID:(NSString *_Nonnull)unitID;

/*!
@method

@abstract
Record Notification Clicked for display unit.

@param unitID       unique id of the display unit
*/
- (void)recordDisplayUnitClickedEventForID:(NSString *_Nonnull)unitID;

@end
