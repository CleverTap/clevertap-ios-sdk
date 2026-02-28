//
//  CTWebImageOperation.m
//  CleverTapSDK
//
//  Ported from SDWebImage's SDWebImageCombinedOperation.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTWebImageOperation.h"

@implementation CTWebImageOperation {
    BOOL _cancelled;
}

@synthesize cancelled = _cancelled;

// ---------------------------------------------------------------------------
// cancel — mirrors SDWebImageCombinedOperation.cancel (SDWebImageManager.m:797–814)
// ---------------------------------------------------------------------------

- (void)cancel {
    @synchronized (self) {
        if (_cancelled) {
            return;
        }
        _cancelled = YES;

        // Cancel the network download task — mirrors SDWebImageCombinedOperation cancelling
        // its loaderOperation (SDWebImageManager.m:806–810)
        if (_dataTask) {
            [_dataTask cancel];
            _dataTask = nil;
        }
    }
}

@end
