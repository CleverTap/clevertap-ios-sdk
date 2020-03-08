#import <Foundation/Foundation.h>

@protocol CTFeatureFlagsDelegate <NSObject>
@required
- (void)featureFlagsDidUpdate;
@end

@interface CTFeatureFlagsController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;

@property (nonatomic, weak) id<CTFeatureFlagsDelegate> _Nullable delegate;

- (instancetype _Nullable ) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithAccountId:(NSString *_Nonnull)accountId
                                       guid:(NSString *_Nonnull)guid;

- (void)updateFeatureFlags:(NSArray<NSDictionary*> *_Nullable)featureFlags;

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end
