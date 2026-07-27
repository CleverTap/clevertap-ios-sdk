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

/// Records a Live Activity lifecycle event (Started/Updated/Ended/Dismissed) through the same
/// pipeline as a push "Notification Viewed" event. `eventName` becomes the event's `evtName`
/// and `data` its `evtData`. The ObjC implementation forwards to `pushLiveActivityEventNamed:data:`.
- (void)recordLiveActivityEventNamed:(NSString *)eventName data:(NSDictionary *)data;

/// Records a Live Activity **impression** — identical to a push "Notification Viewed" event
/// (`evtName` = "Notification Viewed", queued as NotificationViewed). `wzrk` is the campaign
/// dictionary from the activity payload and becomes the event's `evtData`.
- (void)recordLiveActivityViewedEventWithData:(NSDictionary *)wzrk;

/// Records a Live Activity **click** — identical to a push "Notification Clicked" event
/// (`evtName` = "Notification Clicked", queued as Raised). `wzrk` is the campaign dictionary
/// from the activity payload and becomes the event's `evtData`.
- (void)recordLiveActivityClickedEventWithData:(NSDictionary *)wzrk;

/// Registers a switch-user delegate so the manager can re-send cached tokens when the
/// device ID changes after `onUserLogin`. The ObjC implementation forwards this call to
/// `addLiveActivitySwitchUserDelegate:`.
- (void)registerLiveActivitySwitchUserDelegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
