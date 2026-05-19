#import <Foundation/Foundation.h>
#import "CleverTap+DisplayUnit.h"
#import "CleverTapDisplayUnitCache.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 Default `CleverTapDisplayUnitCache` implementation, populated by the SDK's
 server-response pipeline.
 */
@interface CTDisplayUnitController : NSObject <CleverTapDisplayUnitCache>

@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, copy, readonly, nullable) NSArray<CleverTapDisplayUnit *> *displayUnits;

- (instancetype)init __unavailable;

// blocking, call off main thread
- (nullable instancetype)initWithAccountId:(NSString *)accountId
                                      guid:(NSString *)guid;

// CleverTapDisplayUnitCache
- (nullable NSArray<CleverTapDisplayUnit *> *)getAllDisplayUnits;
- (nullable CleverTapDisplayUnit *)getDisplayUnitForID:(NSString *)unitID;
- (void)updateDisplayUnits:(nullable NSArray<CleverTapDisplayUnit *> *)displayUnits;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
