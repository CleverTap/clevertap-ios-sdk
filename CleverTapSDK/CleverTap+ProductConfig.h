#import <Foundation/Foundation.h>
#import "CleverTap.h"

typedef NS_ENUM(NSInteger, CleverTapProductConfigStatus) {
    /// Config not yet fetch.
    CleverTapProductConfigFetchStatusNoFetchYet,
    /// Config fetch succeeded.
    CleverTapProductConfigFetchStatusSuccess,
    /// Config fetch failed.
    CleverTapProductConfigFetchStatusFailure,
    /// Config Activate succeeded.
    CleverTapProductConfigActivateStatusSuccess,
    /// Config Activate failed.
    CleverTapProductConfigActivateStatusFailure,
};

@protocol CleverTapProductConfigDelegate <NSObject>
@optional
- (void)ctProductConfigUpdated:(CleverTapProductConfigStatus)status;
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

- (void)fetch;

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval;

- (void)setMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval;

- (void)activate;

- (void)fetchAndActivate;

- (void)setDefaults:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults;

- (void)setDefaultsFromPlistFileName:(NSString *_Nullable)fileName;

- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key;

@end
