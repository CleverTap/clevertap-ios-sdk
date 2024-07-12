//
//  CTFileDownloaderMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 23.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTFileDownloaderMock.h"
#import "CTFileDownloader+Tests.h"

@implementation CTFileDownloaderMock

- (long)currentTimeInterval {
    if (self.mockCurrentTimeInterval) {
        return self.mockCurrentTimeInterval;
    }
    return [super currentTimeInterval];
}

- (void)removeInactiveExpiredAssets:(long)lastDeletedTime {
    if (self.removeInactiveExpiredAssetsBlock) {
        self.removeInactiveExpiredAssetsBlock(lastDeletedTime);
    }
    [super removeInactiveExpiredAssets:lastDeletedTime];
}

- (void)deleteFiles:(NSArray<NSString *> *)urls withCompletionBlock:(CTFilesDeleteCompletedBlock)completion {
    if (self.deleteFilesInvokedBlock) {
        self.deleteFilesInvokedBlock(urls);
    }
    CTFilesDeleteCompletedBlock completionBlock = ^(NSDictionary<NSString *,id> *status) {
        if (completion) {
            completion(status);
        }
        if (self.deleteCompletion) {
            self.deleteCompletion(status);
        }
    };
    [super deleteFiles:urls withCompletionBlock:completionBlock];
}

- (void)removeAllAssetsWithCompletion:(void(^)(NSDictionary<NSString *,NSNumber *> *status))completion {
    CTFilesDeleteCompletedBlock completionBlock = ^(NSDictionary<NSString *,id> *status) {
        if (completion) {
            completion(status);
        }
        if (self.removeAllAssetsCompletion) {
            self.removeAllAssetsCompletion(status);
        }
    };
    [super removeAllAssetsWithCompletion:completionBlock];
}

- (void)downloadFiles:(NSArray<NSString *> *)fileURLs withCompletionBlock:(void (^)(NSDictionary<NSString *,NSNumber *> * _Nonnull))completion {
    CTFilesDownloadCompletedBlock completionBlock = ^(NSDictionary<NSString *,id> *status) {
        if (completion) {
            completion(status);
        }
        if (self.downloadCompletion) {
            self.downloadCompletion(status);
        }
    };
    [super downloadFiles:fileURLs withCompletionBlock:completionBlock];
}

@end
