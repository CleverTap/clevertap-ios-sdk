#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Bridge protocol that lets `CTLiveActivityManager` queue Live Activity data events
/// through the internal ObjC event pipeline without needing direct access to the
/// non-public `pushLiveActivityData:` method in `CleverTapInternal.h`.
///
/// `CleverTap` declares conformance in `CleverTap+LiveActivities.h` and implements
/// it in `CleverTap+LiveActivities.m`, where it CAN access `pushLiveActivityData:`.
@protocol CTLiveActivityDataQueue <NSObject>

/// Enqueues a Live Activity data payload to be sent to the CT backend.
/// The ObjC implementation forwards this call to `pushLiveActivityData:`.
- (void)enqueueLiveActivityData:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
