#import <Foundation/Foundation.h>
#import "CleverTap.h"

@protocol CleverTapProductConfigDelegate <NSObject>
@optional
- (void)ctProductConfigUpdated; // TODO: working on naming 
@end

@interface CleverTap(ProductConfig)
@property (atomic, strong, readonly, nonnull) CleverTapProductConfig *productConfig;
@end

#pragma mark - CleverTapConfigValue

@interface CleverTapConfigValue : NSObject <NSCopying>
// TODO: private
- (instancetype _Nullable )initWithData:(NSDictionary *_Nullable)data;
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
@property(nonatomic, readonly, nullable) id JSONValue NS_SWIFT_NAME(jsonValue);

@end


@interface CleverTapProductConfig : NSObject

@property (nonatomic, weak) id<CleverTapProductConfigDelegate> _Nullable delegate;

// TODO: set default values

- (void)fetch;

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval;

- (void)activate;

- (void)fetchAndActivate;

- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key;

- (void)setMinimumFetchInterval:(NSTimeInterval)fetchInterval;


@end
