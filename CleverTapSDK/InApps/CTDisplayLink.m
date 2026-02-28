/*
 * CTDisplayLink
 * Ported from SDWebImage's SDDisplayLink (iOS path only).
 *
 * Key SDWebImage source references:
 *   - initWithTarget:selector:     → SDDisplayLink.m:65–89
 *   - duration property            → SDDisplayLink.m:98–161
 *   - isRunning                    → SDDisplayLink.m:164–172
 *   - addToRunLoop:forMode:        → SDDisplayLink.m:174–195
 *   - removeFromRunLoop:forMode:   → SDDisplayLink.m:197–218
 *   - start / stop                 → SDDisplayLink.m:220–246
 *   - displayLinkDidRefresh:       → SDDisplayLink.m:250–265
 *
 * macOS (CVDisplayLink) and watchOS (NSTimer) paths omitted — iOS only.
 */

#import "CTDisplayLink.h"
#import "CTWeakProxy.h"
#import <QuartzCore/QuartzCore.h>

// Use targetTimestamp on iOS 10+ for accurate duration (WWDC Session 10147).
static BOOL kCTDisplayLinkUseTargetTimestamp = NO;

@interface CTDisplayLink ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval previousFireTime;
@property (nonatomic, assign) NSTimeInterval nextFireTime;

@end

@implementation CTDisplayLink

- (void)dealloc {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)sel {
    self = [super init];
    if (self) {
        _target = target;
        _selector = sel;
        if (@available(iOS 10.0, *)) {
            kCTDisplayLinkUseTargetTimestamp = YES;
        }
        // Use weak proxy so CADisplayLink doesn't retain self (and thus target).
        // Mirrors SDDisplayLink.m:70–83.
        CTWeakProxy *weakProxy = [CTWeakProxy proxyWithTarget:self];
        _displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayLinkDidRefresh:)];
    }
    return self;
}

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)sel {
    return [[CTDisplayLink alloc] initWithTarget:target selector:sel];
}

// Mirrors SDDisplayLink.duration (line 98).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (NSTimeInterval)duration {
    NSTimeInterval duration = 0;
    if (kCTDisplayLinkUseTargetTimestamp) {
        NSTimeInterval nextFireTime = self.nextFireTime;
        if (nextFireTime != 0) {
            duration = self.displayLink.targetTimestamp - nextFireTime;
        } else {
            duration = self.displayLink.duration;
        }
    } else {
        NSTimeInterval previousFireTime = self.previousFireTime;
        if (previousFireTime != 0) {
            duration = self.displayLink.timestamp - previousFireTime;
        } else {
            duration = self.displayLink.duration;
        }
    }
    // Fallback when system sleeps (duration goes negative).
    if (duration < 0) {
        duration = self.displayLink.duration;
    }
    return duration;
}
#pragma clang diagnostic pop

- (BOOL)isRunning {
    return !self.displayLink.isPaused;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    if (!runloop || !mode) return;
    [self.displayLink addToRunLoop:runloop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    if (!runloop || !mode) return;
    [self.displayLink removeFromRunLoop:runloop forMode:mode];
}

- (void)start {
    self.displayLink.paused = NO;
}

- (void)stop {
    self.displayLink.paused = YES;
    self.previousFireTime = 0;
    self.nextFireTime = 0;
}

// CADisplayLink callback — forward to actual target via weak proxy.
// Mirrors SDDisplayLink.displayLinkDidRefresh: (line 250).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (void)displayLinkDidRefresh:(CADisplayLink *)displayLink {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
    if (kCTDisplayLinkUseTargetTimestamp) {
        self.nextFireTime = displayLink.targetTimestamp;
    } else {
        self.previousFireTime = displayLink.timestamp;
    }
}
#pragma clang diagnostic pop

@end
