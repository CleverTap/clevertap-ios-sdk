#import <Foundation/Foundation.h>
#import "CleverTap.h"

@protocol CleverTapProductConfigDelegate <NSObject>
@optional
- (void)ctProductConfigFetched;
- (void)ctProductConfigActivated;
- (void)ctProductConfigInitialized;
@end

@interface CleverTap(ProductConfig)
@property (atomic, strong, readonly, nonnull) CleverTapProductConfig *productConfig;
@end

#pragma mark - CleverTapConfigValue

@interface CleverTapConfigValue : NSObject <NSCopying>
/// Gets the value as a string.
@property(nonatomic, readonly, nullable) NSString *stringValue;
/// Gets the value as a number value.
@property(nonatomic, readonly, nullable) NSNumber *numberValue;
/// Gets the value as a NSData object.
@property(nonatomic, readonly, nonnull) NSData *dataValue;
/// Gets the value as a boolean.
@property(nonatomic, readonly) BOOL boolValue;
/// Gets a foundation object (NSDictionary / NSArray) by parsing the value as JSON. This method uses
/// NSJSONSerialization's JSONObjectWithData method with an options value of 0.
@property(nonatomic, readonly, nullable) id jsonValue;

@end

@interface CleverTapProductConfig : NSObject

@property (nonatomic, weak) id<CleverTapProductConfigDelegate> _Nullable delegate;

/*!
@method

@abstract
Fetches product configs, adhering to the default minimum fetch interval.
*/

- (void)fetch;

/*!
@method

@abstract
Fetches product configs, adhering to the specified minimum fetch interval in seconds.
*/

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval;

/*!
@method

@abstract
Sets the minimum interval between successive fetch calls.
*/

- (void)setMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval;

/*!
@method

@abstract
Activates Fetched Config data to the Active Config, so that the fetched key value pairs take effect.
*/

- (void)activate;

/*!
@method

@abstract
Fetches and then activates the fetched product configs.
*/

- (void)fetchAndActivate;

/*!
@method

@abstract
Sets default configs using the given Dictionary
*/

- (void)setDefaults:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults;

/*!
@method

@abstract
Sets default configs using the given plist
*/

- (void)setDefaultsFromPlistFileName:(NSString *_Nullable)fileName;

/*!
@method

@abstract
Returns the config value of the given key
*/

- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key;

/*!
@method

@abstract
Returns the last fetch timestamp
*/

- (NSDate *_Nullable)getLastFetchTimeStamp;

/*!
@method

@abstract
Deletes all activated, fetched and defaults configs and resets all Product Config settings.
*/

- (void)reset;


@end
