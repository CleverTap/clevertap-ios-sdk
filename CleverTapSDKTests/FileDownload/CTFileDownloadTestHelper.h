//
//  CTFileDownloadTestHelper.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 22.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTFileDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTFileDownloadTestHelper : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *filesDownloaded;

- (void)addHTTPStub;
- (int)fileDownloadedCount:(NSURL *)url;
- (void)removeStub;

- (NSString *)fileURL;
- (NSURL *)generateFileURL;
- (NSArray<NSURL *> *)generateFileURLs:(int)count;
- (NSString *)generateFileURLString;
- (NSArray<NSString *> *)generateFileURLStrings:(int)count;

- (void)cleanUpFiles:(CTFileDownloader *)fileDownloader forTest:(XCTestCase *)testCase;

@end

NS_ASSUME_NONNULL_END
