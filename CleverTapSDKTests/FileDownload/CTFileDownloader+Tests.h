//
//  CTFileDownloader+Tests.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 23.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTFileDownloader_Tests_h
#define CTFileDownloader_Tests_h

#import "CTFileDownloader.h"

@interface CTFileDownloader(Tests)

@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *urlsExpiry;
@property (nonatomic) NSTimeInterval fileExpiryTime;
- (long)currentTimeInterval;
- (void)removeInactiveExpiredAssets:(long)lastDeletedTime;
- (void)removeDeletedFilesFromExpiry:(NSDictionary<NSString *, id> *)status;
- (void)updateFilesExpiryInPreference;
- (void)updateLastDeletedTimestamp;
- (long)lastDeletedTimestamp;
- (void)deleteFiles:(NSArray<NSString *> *)urls withCompletionBlock:(CTFilesDeleteCompletedBlock)completion;
- (void)migrateActiveAndInactiveUrls;
- (NSString *)storageKeyWithSuffix:(NSString *)suffix;
- (void)updateFilesExpiry:(NSDictionary<NSString *, NSNumber *> *)status;

@end

#endif /* CTFileDownloader_Tests_h */
