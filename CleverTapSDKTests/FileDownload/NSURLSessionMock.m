//
//  NSURLSessionMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 30.07.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "NSURLSessionMock.h"

@implementation NSURLSessionMock

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSURL * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler {
    return [[NSURLSessionDownloadTaskMock alloc] initWithCompletionHandler:completionHandler delayInterval:self.delayInterval];
}

@end

@implementation NSURLSessionDownloadTaskMock

- (instancetype)initWithCompletionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler
                            delayInterval:(NSTimeInterval)delayInterval {
    self = [super init];
    if (self) {
        _completionHandler = [completionHandler copy];
        _delayInterval = delayInterval;
    }
    return self;
}

- (void)resume {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.completionHandler) {
            self.completionHandler(nil, nil, [NSError errorWithDomain:@"MockErrorDomain" code:-1001 userInfo:@{NSLocalizedDescriptionKey: @"Timeout"}]);
        }
    });
}

@end


