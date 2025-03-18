#import <Foundation/Foundation.h>
#import "CleverTap+ProductConfig.h"

@protocol CleverTapPrivateProductConfigDelegate <NSObject>
@required

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (atomic, weak) id<CleverTapProductConfigDelegate> _Nullable productConfigDelegate;
#pragma clang diagnostic pop

- (void)fetchProductConfig;

- (void)activateProductConfig;

- (void)fetchAndActivateProductConfig;

- (void)resetProductConfig;

- (void)setDefaultsProductConfig:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults;

- (void)setDefaultsFromPlistFileNameProductConfig:(NSString *_Nullable)fileName;

- (CleverTapConfigValue *_Nullable)getProductConfig:(NSString* _Nonnull)key;

@end

@interface CleverTapConfigValue() {}

- (instancetype _Nullable )initWithData:(NSData *_Nullable)data;

@end


@interface CleverTapProductConfig () {}

@property(nonatomic, assign) NSInteger fetchConfigCalls;
@property(nonatomic, assign) NSInteger fetchConfigWindowLength;
@property(nonatomic, assign) NSTimeInterval minimumFetchConfigInterval;
@property(nonatomic, assign) NSTimeInterval lastFetchTs;

@property (nonatomic, weak) id<CleverTapPrivateProductConfigDelegate> _Nullable privateDelegate;

- (instancetype _Nullable)init __unavailable;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config
                         privateDelegate:(id<CleverTapPrivateProductConfigDelegate>_Nonnull)delegate;

- (void)updateProductConfigWithOptions:(NSDictionary *_Nullable)options;

- (void)updateProductConfigWithLastFetchTs:(NSTimeInterval)lastFetchTs;

- (void)resetProductConfigSettings;
@end
