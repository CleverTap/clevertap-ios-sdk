#import <Foundation/Foundation.h>
#import "CleverTap.h"
@class CleverTapDisplayUnitContent;
@protocol CleverTapDisplayUnitCache;

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

 @return all units currently held, or @c nil if no cache has been installed
 yet or the cache holds no units. Matches the Android contract.
 */
- (NSArray<CleverTapDisplayUnit *>*_Nullable)getAllDisplayUnits;

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

/*!
 @method recordDisplayUnitElementClickedEventForID:elementID:additionalProperties:

 @abstract Element-level click attribution for Native Display units.

 Element-level analog of @c -recordDisplayUnitClickedEventForID: — for Native
 Display units that host multiple interactive child elements (buttons,
 images, etc.), this method records which child element was clicked
 alongside the existing @c wzrk_* campaign attribution.

 @c evtData is assembled in three layers (later layers win on key collision):
 1. Caller's @c additionalProperties, merged verbatim.
 2. @c wzrk_element_id = elementID from the dedicated argument.
 3. Cached unit's @c wzrk_* fields layered on top — so server-controlled
    attribution always wins over same-named caller-supplied keys (e.g. a
    client cannot spoof @c wzrk_id). Caller-supplied @c wzrk_* keys that
    are NOT in the cached unit pass through unchanged.

 @param unitID                  the unitID of the Display Unit.
 @param elementID               identifier of the clicked child element
                                (from the Native Display config; typically
                                a button node id).
 @param additionalProperties    optional per-click context (action url,
                                custom KVs, …).
 */
- (void)recordDisplayUnitElementClickedEventForID:(NSString *_Nonnull)unitID
                                        elementID:(NSString *_Nonnull)elementID
                             additionalProperties:(nullable NSDictionary<NSString *, id> *)additionalProperties;

/*!
 @method

 @abstract
 Replaces the SDK's display-unit cache with the supplied implementation.
 Pass `nil` to clear the reference (subsequent server responses will lazily
 install a fresh default cache).

 The new instance receives subsequent `updateDisplayUnits:` calls (e.g. from
 server responses) and serves all lookup sites: `getAllDisplayUnits`,
 `getDisplayUnitForID:`, `recordDisplayUnitViewedEventForID:`, and
 `recordDisplayUnitClickedEventForID:`.

 Implementations must be thread-safe. The display-unit delegate registered
 via `-setDisplayUnitDelegate:` fires only for server-pipeline activity —
 replacing the cache or mutating its contents from outside the SDK does not
 synthesise a delegate fire.

 @since 7.x.0
 */
- (void)setDisplayUnitCache:(nullable id<CleverTapDisplayUnitCache>)cache;

@end
