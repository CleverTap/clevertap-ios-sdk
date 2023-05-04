
#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface CleverTapWatchOS : NSObject

- (instancetype _Nonnull)initWithSession:(WCSession* _Nonnull)session;

- (void)recordEvent:(NSString *_Nonnull)event withProps:(NSDictionary *_Nonnull)props;

@end
