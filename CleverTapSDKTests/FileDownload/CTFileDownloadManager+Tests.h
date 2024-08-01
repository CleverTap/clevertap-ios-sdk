//
//  CTFileDownloadManager+Tests.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 23.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTFileDownloadManager_Tests_h
#define CTFileDownloadManager_Tests_h

#import "CTFileDownloadManager.h"

@interface CTFileDownloadManager(Tests)

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSFileManager* fileManager;
@property NSTimeInterval semaphoreTimeout;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

- (void)downloadSingleFile:(NSURL *)url
completed:(void(^)(BOOL success))completedBlock;

- (void)deleteSingleFile:(NSURL *)url
               completed:(void(^)(BOOL success))completedBlock;

@end

#endif /* CTFileDownloadManager_Tests_h */
