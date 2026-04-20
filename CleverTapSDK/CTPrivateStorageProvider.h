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

+ (NSString *)pathForDatabaseFile:(NSString *)filename;
+ (NSURL *)urlForDatabaseFile:(NSString *)filename;
+ (void)migrateDirectoryToApplicationSupportIfNeeded:(NSString *)directoryName;
+ (void)performMigrationIfNeededForDatabase:(NSString *)filename;
@end

NS_ASSUME_NONNULL_END
