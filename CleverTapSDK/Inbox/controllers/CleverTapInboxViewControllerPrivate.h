#import <Foundation/Foundation.h>

@protocol CleverTapInboxViewControllerDelegate;
@class CleverTapInboxStyleConfig;

@protocol CleverTapInboxViewControllerAnalyticsDelegate <NSObject>
@required
- (void)messageDidShow:(CleverTapInboxMessage *)message;
- (void)messageDidSelect:(CleverTapInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
@end

@interface CleverTapInboxViewController ()

- (instancetype)init __unavailable;

- (instancetype)initWithMessages:(NSArray *)messages
                          config:(CleverTapInboxStyleConfig * _Nonnull )config
                        delegate:(id<CleverTapInboxViewControllerDelegate>)delegate
               analyticsDelegate:(id<CleverTapInboxViewControllerAnalyticsDelegate>)analyticsDelegate;

@end
