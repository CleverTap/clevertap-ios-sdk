
#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface CleverTapWatchOS : NSObject

- (instancetype)initWithSession:(WCSession* _Nonnull)session;

- (void)recordEvent:(NSString *)event withProps:(NSDictionary *)props;

@end
