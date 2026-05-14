#import <Foundation/Foundation.h>

@protocol CleverTapSyncDelegate <NSObject>

/*!
 
 @abstract
 The `CleverTapSyncDelegate` protocol provides additional/alternative methods for
 notifying your application (the adopting delegate) when the User Profile is initialized.
 
 @discussion
 This method will be called when the User Profile is initialized with the CleverTap ID of the User Profile.
 The CleverTap ID is the unique identifier assigned to the User Profile by CleverTap.
 */
@optional
- (void)profileDidInitialize:(NSString*)CleverTapID;

/*!
 
 @abstract
 The `CleverTapSyncDelegate` protocol provides additional/alternative methods for
 notifying your application (the adopting delegate) when the User Profile is initialized.
 
 @discussion
 This method will be called when the User Profile is initialized with the CleverTap ID of the User Profile.
 The CleverTap ID is the unique identifier assigned to the User Profile by CleverTap.
 */
@optional
- (void)profileDidInitialize:(NSString*)CleverTapID forAccountId:(NSString*)accountId;


/*!
 
 @abstract 
 The `CleverTapSyncDelegate` protocol provides additional/alternative methods for
 notifying your application (the adopting delegate) about synchronization-related changes to the User Profile/Event History.
 
 @discussion
 the updates argument represents the changed data and is of the form:
 {
 "profile":{"<property1>":{"oldValue":<value>, "newValue":<value>}, ...},
 "events:{"<eventName>":
 {"count":
 {"oldValue":(int)<old count>, "newValue":<new count>},
 "firstTime":
 {"oldValue":(double)<old first time event occurred>, "newValue":<new first time event occurred>},
 "lastTime":
 {"oldValue":(double)<old last time event occurred>, "newValue":<new last time event occurred>},
 }, ...
 }
 }
 
 */

@optional
- (void)profileDataUpdated:(NSDictionary*)updates;

@end
