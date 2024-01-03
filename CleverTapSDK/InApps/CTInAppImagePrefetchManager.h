#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"
#import "CTSwitchUserDelegate.h"

@class CTMultiDelegateManager;

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppImagePrefetchManager : NSObject <CTSwitchUserDelegate>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId;
- (void)preloadClientSideInAppImages:(NSArray *)csInAppNotifs;
- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL;
- (void)clearDiskImages;
- (void)_clearInAppResources:(BOOL)expiredOnly;

@end

NS_ASSUME_NONNULL_END
