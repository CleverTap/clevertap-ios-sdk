#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

@class CTMultiDelegateManager;

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppImagePrefetchManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;
- (void)preloadClientSideInAppImages:(NSArray *)csInAppNotifs;
- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL;
- (void)setImageAssetsInactiveAndClearExpired;
- (void)_clearImageAssets:(BOOL)expiredOnly;

@end

NS_ASSUME_NONNULL_END
