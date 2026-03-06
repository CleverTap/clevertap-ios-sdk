/*
 * CTWeakProxy
 * Ported from SDWebImage's SDWeakProxy.
 * A weak proxy which forwards all messages to the target.
 * Used to break retain cycles with CADisplayLink.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
