//
//  CTInAppTimer.m
//  CleverTap-iOS-SDK-iOS
//
//  Created by Sonal Kachare on 17/09/25.
//

#import "CTInAppTimer.h"

@interface CTInAppTimer ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) NSTimeInterval remainingTime;
@end

@implementation CTInAppTimer

- (instancetype)initWithDelay:(NSTimeInterval)delay completion:(void (^)(void))completion {
    if (self = [super init]) {
        _delay = delay;
        _completionHandler = completion;
        _remainingTime = delay;
    }
    return self;
}

- (void)start {
    // Ensure we're on the main thread for timer operations
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self start];
        });
        return;
    }
    
    if (self.timer) return;
    
    self.startTime = [NSDate date];
    
    // Create timer on main thread where run loop is guaranteed to be active
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.remainingTime
                                                  target:self
                                                selector:@selector(timerFired)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)cancel {
    // Ensure we're on the main thread for timer operations
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cancel];
        });
        return;
    }
    
    [self.timer invalidate];
    self.timer = nil;
    _completionHandler = nil; // Access ivar directly to bypass nonnull check
    _isPaused = NO;
    _remainingTime = 0;
}

- (void)timerFired {
    NSAssert([NSThread isMainThread], @"Timer should fire on main thread");
    
    void (^completion)(void) = self.completionHandler;
    [self cancel]; // Clean up first
    
    // Execute completion handler
    if (completion) {
        completion();
    }
}

- (void)dealloc {
    // Must invalidate timer synchronously in dealloc
    // Cannot use dispatch_async as self will be gone
    if (self.timer) {
        [self.timer invalidate];
    }
}

@end
