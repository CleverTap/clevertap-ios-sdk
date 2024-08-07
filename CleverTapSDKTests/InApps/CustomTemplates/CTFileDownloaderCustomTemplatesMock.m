//
//  CTFileDownloaderCustomTemplatesMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 4.07.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTFileDownloaderCustomTemplatesMock.h"

@implementation CTFileDownloaderCustomTemplatesMock

- (void)downloadFiles:(NSArray<NSString *> *)fileURLs withCompletionBlock:(void (^ _Nullable)(NSDictionary<NSString *, NSNumber *> *status))completion {
    completion(@{});
}

- (BOOL)isFileAlreadyPresent:(NSString *)url {
    return NO;
}

- (void)clearFileAssets:(BOOL)expiredOnly {
}

- (nullable NSString *)fileDownloadPath:(NSString *)url {
    return url;
}

- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL {
    return nil;
}

@end
