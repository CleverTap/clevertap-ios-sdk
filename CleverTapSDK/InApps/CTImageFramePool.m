/*
 * CTImageFramePool
 * Ported from SDWebImage's SDImageFramePool.
 * Simplified: per-player instance, no static provider→pool map.
 *
 * Key SDWebImage source references:
 *   - init                    → SDImageFramePool.m:41–53
 *   - prefetchFrameAtIndex:   → SDImageFramePool.m:99–128
 *   - setFrame:atIndex:       → SDImageFramePool.m:142–146
 *   - frameAtIndex:           → SDImageFramePool.m:148–154
 *   - removeAllFrames         → SDImageFramePool.m:162–166
 *   - didReceiveMemoryWarning → SDImageFramePool.m:61–63
 */

#import "CTImageFramePool.h"

@interface CTImageFramePool ()

@property (nonatomic, weak) id<CTAnimatedImageProviding> provider;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *frameBuffer;
@property (nonatomic, strong) NSOperationQueue *fetchQueue;

@end

@implementation CTImageFramePool

- (instancetype)initWithProvider:(id<CTAnimatedImageProviding>)provider {
    self = [super init];
    if (self) {
        _provider = provider;
        _frameBuffer = [NSMutableDictionary dictionary];
        _fetchQueue = [[NSOperationQueue alloc] init];
        _fetchQueue.maxConcurrentOperationCount = 1;
        _fetchQueue.name = @"com.clevertap.CTImageFramePool.fetchQueue";
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self removeAllFrames];
}

// Mirrors SDImageFramePool.prefetchFrameAtIndex: (line 99).
- (void)prefetchFrameAtIndex:(NSUInteger)index {
    @synchronized (self) {
        NSUInteger count = self.frameBuffer.count;
        if (self.maxBufferCount > 0 && count > self.maxBufferCount) {
            // Evict adjacent frames (same naive strategy as SDImageFramePool.m:105–107)
            if (index > 0) self.frameBuffer[@(index - 1)] = nil;
            self.frameBuffer[@(index + 1)] = nil;
        }
    }

    if (self.fetchQueue.operationCount == 0) {
        __weak typeof(self) weakSelf = self;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            id<CTAnimatedImageProviding> provider = strongSelf.provider;
            if (!provider) return;
            UIImage *frame = [provider animatedImageFrameAtIndex:index];
            [strongSelf setFrame:frame atIndex:index];
        }];
        [self.fetchQueue addOperation:operation];
    }
}

- (NSUInteger)currentFrameCount {
    @synchronized (self) {
        return self.frameBuffer.count;
    }
}

- (void)setFrame:(nullable UIImage *)frame atIndex:(NSUInteger)index {
    @synchronized (self) {
        self.frameBuffer[@(index)] = frame;
    }
}

- (nullable UIImage *)frameAtIndex:(NSUInteger)index {
    @synchronized (self) {
        return self.frameBuffer[@(index)];
    }
}

- (void)removeAllFrames {
    @synchronized (self) {
        [self.frameBuffer removeAllObjects];
    }
}

@end
