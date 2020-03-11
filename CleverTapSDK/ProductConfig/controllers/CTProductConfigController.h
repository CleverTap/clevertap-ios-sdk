#import <Foundation/Foundation.h>
#import "CleverTap+ProductConfig.h"

@protocol CTProductConfigDelegate <NSObject>
@required
- (void)productConfigDidUpdate;
@end

@class CleverTapInstanceConfig;

@interface CTProductConfigController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;

- (instancetype _Nullable ) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CTProductConfigDelegate>_Nonnull)delegate;

- (void)updateProductConfig:(NSArray<NSDictionary*> *_Nullable)productConfig;

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval;

- (void)activate;

- (void)fetchAndActivate;

- (void)setMinimumFetchInterval:(NSTimeInterval)fetchInterval;

- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key withDefaultValue:(CleverTapConfigValue *_Nullable)defaultValue;

@end
