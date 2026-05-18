#import <Foundation/Foundation.h>
#import "CleverTap+Inbox.h"

@protocol CleverTapInboxViewControllerDelegate;
@class CleverTapInboxStyleConfig;

@protocol CleverTapInboxViewControllerAnalyticsDelegate <NSObject>
@required
- (void)messageDidShow:(CleverTapInboxMessage * _Nonnull)message;
- (void)messageDidSelect:(CleverTapInboxMessage * _Nonnull)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
/**
 Called when app inbox link is tapped for requesting push permission.
 */
- (void)messageDidSelectForPushPermission:(BOOL)fallbackToSettings;
@optional
/**
 Called when the user pulls to refresh. The callback must always be invoked
 (throttled or success) so the refresh spinner can be ended.
 */
- (void)inboxViewControllerDidRequestRefreshWithCallback:(CleverTapInboxSuccessBlock _Nonnull)callback;
/**
 Returns the current set of inbox messages to display after a refresh.
 */
- (NSArray<CleverTapInboxMessage *> * _Nonnull)inboxViewControllerGetMessages;
/**
 Returns YES if inbox V2 is enabled for this session, NO if disabled (e.g. 403 from server).
 When NO, pull-to-refresh UI is hidden.
 */
- (BOOL)inboxViewControllerIsInboxV2Enabled;
@end

@interface CleverTapInboxViewController ()

- (instancetype _Nonnull)init __unavailable;

- (instancetype _Nonnull)initWithMessages:(NSArray * _Nonnull)messages
                                   config:(CleverTapInboxStyleConfig * _Nonnull)config
                                 delegate:(id<CleverTapInboxViewControllerDelegate> _Nullable)delegate
                        analyticsDelegate:(id<CleverTapInboxViewControllerAnalyticsDelegate> _Nullable)analyticsDelegate;

@end
