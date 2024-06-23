//
//  CTFileDownloadTestHelper.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 22.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTFileDownloadTestHelper : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *filesDownloaded;

- (void)addHTTPStub;
- (int)fileDownloadedCount:(NSURL *)url;
- (void)removeStub;

- (NSString *)fileURL;
- (NSArray<NSURL *> *)generateFileURLs:(int)count;
- (NSArray<NSString *> *)generateFileURLStrings:(int)count;

@end

NS_ASSUME_NONNULL_END
