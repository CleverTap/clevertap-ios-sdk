//
//  CTPrivateStorageProvider.h
//  CleverTapSDK
//
//  Created by Reshab Singh  on 11/02/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface  CTPrivateStorageProvider : NSObject

+ (NSString *)applicationSupportDirectoryPath;
+ (NSURL *)applicationSupportDirectoryURL;
+ (NSString *)pathForDatabaseFile:(NSString *)filename;
+ (NSURL *)urlForDatabaseFile:(NSString *)filename;
+ (void)ensureDirectoryInApplicationSupport:(NSString *)directoryName;
@end

NS_ASSUME_NONNULL_END
