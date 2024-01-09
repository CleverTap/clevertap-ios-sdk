//
//  CTInAppImagePrefetchManager+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 9.01.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

@interface CTInAppImagePrefetchManager (Tests)

@property (nonatomic, strong) NSMutableSet<NSString *> *activeImageSet;
@property (nonatomic, strong) NSMutableSet<NSString *> *inactiveImageSet;

- (void)prefetchURLs:(NSArray<NSString *> *)mediaURLs;
- (NSString *)storageKeyWithSuffix:(NSString *)suffix;
- (NSArray<NSString *> *)getImageURLs:(NSArray *)csInAppNotifs;
- (void)removeInactiveExpiredAssets:(long)lastDeletedTime;
- (long)getLastDeletedTimestamp;

@end
