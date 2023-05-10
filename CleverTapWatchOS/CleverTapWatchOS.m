
#import "CleverTapWatchOS.h"

@interface CleverTapWatchOS ()

@property (strong, nonatomic) WCSession *session;

@end

@implementation CleverTapWatchOS

- (instancetype _Nonnull)initWithSession:(WCSession* _Nonnull)session {
    if (self = [super init]) {
        self.session = session;
    }
    return self;
}

- (void)sendMessage:(NSString *)type withcontent:(NSDictionary *)content{
    if (![self.session isReachable]) {
        return;
    }
    NSMutableDictionary *message = [content mutableCopy];
    message[@"clevertap_type"] = type;
    [self.session sendMessage:message replyHandler:nil errorHandler:nil];
}

- (void)recordEvent:(NSString *_Nonnull)event withProps:(NSDictionary *_Nonnull)props {
    NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
    content[@"event"] = event;
    content[@"props"] = props;
    [self sendMessage:@"recordEventWithProps" withcontent:content];
}

@end
