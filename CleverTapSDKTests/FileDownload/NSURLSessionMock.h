//
//  NSURLSessionMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 30.07.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionMock : NSURLSession

@property (nonatomic, assign) NSTimeInterval delayInterval;

@end

@interface NSURLSessionDownloadTaskMock : NSURLSessionDownloadTask

@property (nonatomic, copy) void (^completionHandler)(NSURL * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);
@property (nonatomic, assign) NSTimeInterval delayInterval;

- (instancetype)initWithCompletionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler
                            delayInterval:(NSTimeInterval)delayInterval;

@end

NS_ASSUME_NONNULL_END
