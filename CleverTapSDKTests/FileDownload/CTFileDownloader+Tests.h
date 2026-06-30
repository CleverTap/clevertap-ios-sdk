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
- (void)removeLegacyAssets:(void (^)(void))completion;
- (NSString *)storageKeyWithSuffix:(NSString *)suffix;
- (void)updateFilesExpiry:(NSDictionary<NSString *, NSNumber *> *)status;
- (void)removeAllAssetsWithCompletion:(void(^)(NSDictionary<NSString *,NSNumber *> *status))completion;

/// Returns the disk-cache path that SDWebImage (5.x) would have used for the given URL string.
/// Mirrors SDDiskCacheFileNameForKey + SDImageCache.defaultDiskCacheDirectory.
/// Used by testRemoveLegacyAssets to set up and verify legacy-cache cleanup.
+ (NSString *)legacyCachePathForURL:(NSString *)urlString;

@end

#endif /* CTFileDownloader_Tests_h */
