/*
 * CTDisplayLink
 * Ported from SDWebImage's SDDisplayLink (iOS path only).
 * A CADisplayLink wrapper that avoids retaining its target via CTWeakProxy.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTDisplayLink : NSObject

@property (readonly, nonatomic, weak, nullable) id target;
@property (readonly, nonatomic, assign) SEL selector;
/// Elapsed time in seconds of the previous display frame. Zero when not running.
@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) BOOL isRunning;

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)sel;

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
