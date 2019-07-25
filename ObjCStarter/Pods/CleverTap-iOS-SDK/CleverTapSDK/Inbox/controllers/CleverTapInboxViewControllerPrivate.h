#import <Foundation/Foundation.h>

@protocol CleverTapInboxViewControllerDelegate;
@class CleverTapInboxStyleConfig;

@protocol CleverTapInboxViewControllerAnalyticsDelegate <NSObject>
@required
- (void)messageDidShow:(CleverTapInboxMessage * _Nonnull)message;
- (void)messageDidSelect:(CleverTapInboxMessage * _Nonnull)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
@end

@interface CleverTapInboxViewController ()

- (instancetype _Nonnull)init __unavailable;

- (instancetype _Nonnull)initWithMessages:(NSArray * _Nonnull)messages
                          config:(CleverTapInboxStyleConfig * _Nonnull)config
                        delegate:(id<CleverTapInboxViewControllerDelegate> _Nullable)delegate
               analyticsDelegate:(id<CleverTapInboxViewControllerAnalyticsDelegate> _Nullable)analyticsDelegate;

@end
