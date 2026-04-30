#import <Foundation/Foundation.h>

@class CleverTapDisplayUnit;

NS_ASSUME_NONNULL_BEGIN

/*!
 @protocol CleverTapDisplayUnitCache

 In-memory storage contract for `CleverTapDisplayUnit` objects. The default
 implementation (`CTDisplayUnitController`) is server-pipeline-driven. Hosts
 may install their own implementation via `-[CleverTap setDisplayUnitCache:]`
 to expose units produced outside the standard server-response pipeline (for
 example, server-driven UI SDKs that fetch units through their own pipeline).

 Implementations must be thread-safe — methods may be invoked from any thread.

 The display-unit delegate registered via `-setDisplayUnitDelegate:` only
 fires for server-pipeline activity. Replacing the cache or mutating its
 contents from outside the SDK does not synthesise a delegate fire.

 @since 7.x.0
 */
@protocol CleverTapDisplayUnitCache <NSObject>
@required

/*! @return all units currently held; empty array if none. */
- (NSArray<CleverTapDisplayUnit *> *)getAllDisplayUnits;

/*! @return the unit with the given unitID, or nil if absent. */
- (nullable CleverTapDisplayUnit *)getDisplayUnitForID:(NSString *)unitID;

/*!
 Called by the SDK when a server response delivers an updated set of display
 units. The default implementation replaces the cache contents; hosts may
 choose merge semantics for their own implementations.
 */
- (void)updateDisplayUnits:(nullable NSArray<NSDictionary *> *)displayUnits;

/*! Clears all units. Called by the SDK on logout / reset flows. */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
