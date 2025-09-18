//
//  CTInAppTimer.m
//  CleverTap-iOS-SDK-iOS
//
//  Created by Sonal Kachare on 17/09/25.
//

#import "CTInAppTimer.h"

@interface CTInAppTimer ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval elapsedTime;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *pauseTime;
@property (nonatomic, assign) NSTimeInterval remainingTime;
@property (nonatomic, assign) BOOL isPaused;
@end

@implementation CTInAppTimer

- (instancetype)initWithDelay:(NSTimeInterval)delay completion:(void (^)(void))completion {
    if (self = [super init]) {
        _delay = delay;
        _completionHandler = completion;
        _remainingTime = delay;
        _isPaused = NO;
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
    self.isPaused = NO;
    
    // Create timer on main thread where run loop is guaranteed to be active
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.remainingTime
                                                  target:self
                                                selector:@selector(timerFired)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)pause {
    // Ensure we're on the main thread for timer operations
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self pause];
        });
        return;
    }
    
    if (!self.timer || self.isPaused) return;
    
    _isPaused = YES;
    self.pauseTime = [NSDate date];
    NSTimeInterval elapsed = [self.pauseTime timeIntervalSinceDate:self.startTime];
    _remainingTime = MAX(0, self.delay - elapsed);
    
    [self.timer invalidate];
    self.timer = nil;
}

- (void)resume {
    // Ensure we're on the main thread for timer operations
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resume];
        });
        return;
    }
    
    if (!self.isPaused || self.remainingTime <= 0) return;
    
    _isPaused = NO;
    self.startTime = [NSDate date];
    
    // Create new timer with remaining time
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
    self.completionHandler = nil;
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
    [self cancel];
}

@end
