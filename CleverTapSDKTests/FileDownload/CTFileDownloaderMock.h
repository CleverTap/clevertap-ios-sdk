//
//  CTFileDownloaderMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 23.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTFileDownloader.h"
#import "CTFileDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTFileDownloaderMock : CTFileDownloader

@property (nonatomic) long mockCurrentTimeInterval;
@property (nonatomic) void(^removeInactiveExpiredAssetsBlock)(long);

@property (nonatomic) CTFilesDeleteCompletedBlock deleteCompletion;
@property (nonatomic, nullable) void(^deleteFilesInvokedBlock)(NSArray<NSString *> *);

@property (nonatomic, nullable) CTFilesDeleteCompletedBlock removeAllAssetsCompletion;

@property (nonatomic) CTFilesDownloadCompletedBlock downloadCompletion;

@end

NS_ASSUME_NONNULL_END
