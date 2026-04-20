//
//  CTPrivateStorageProvider.m
//  CleverTapSDK
//
//  Created by Reshab Singh  on 11/02/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import "CTPrivateStorageProvider.h"
#import "CTConstants.h"

@implementation CTPrivateStorageProvider

+ (NSString *)applicationSupportDirectoryPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                             NSUserDomainMask,
                                                             YES);
    NSString *appSupportPath = [paths firstObject];
    if (!appSupportPath) {
            NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                    NSUserDomainMask,
                                                                    YES);
            NSString *fallbackPath = [docPaths firstObject];
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] FALLBACK: Using Documents directory: %@", fallbackPath);
            return fallbackPath;
    }
    if (![fileManager fileExistsAtPath:appSupportPath]) {
            NSError *error = nil;
            BOOL created = [fileManager createDirectoryAtPath:appSupportPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
            
            if (!created) {
                NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES);
                NSString *fallbackPath = [docPaths firstObject];
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] FALLBACK: Using Documents directory: %@", fallbackPath);
                return fallbackPath;
            }
        }
        return appSupportPath;
}

+ (NSURL *)applicationSupportDirectoryURL {
    NSString *path = [self applicationSupportDirectoryPath];
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

+ (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    return [paths firstObject];
}

+ (NSString *)pathForDatabaseFile:(NSString *)filename {
    if (!filename || [filename stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Invalid filename");
        return nil;
    }
    
    NSString *appSupportPath = [self applicationSupportDirectoryPath];
    return [appSupportPath stringByAppendingPathComponent:filename];
}

+ (NSURL *)urlForDatabaseFile:(NSString *)filename {
    if (!filename || [filename stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Invalid filename");
        return nil;
    }
    
    NSString *path = [self pathForDatabaseFile:filename];
    return path ? [NSURL fileURLWithPath:path] : nil;
}

#pragma mark - Migration Logic

+ (void)performMigrationIfNeededForDatabase:(NSString *)filename {
//    if (!filename) return;

    static NSMutableSet *migratedFiles = nil;
    static NSMutableDictionary *fileLocks = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        migratedFiles = [NSMutableSet set];
        fileLocks = [NSMutableDictionary dictionary];
    });

    NSLock *lock = nil;
    @synchronized(fileLocks) {
        lock = fileLocks[filename];
        if (!lock) {
            lock = [[NSLock alloc] init];
            fileLocks[filename] = lock;
        }
    }

    [lock lock];
    @try {
        if (![migratedFiles containsObject:filename]) {
            NSString *targetPath = [self pathForDatabaseFile:filename];
            [self migrateDatabaseFileIfNeeded:filename toPath:targetPath];
            [migratedFiles addObject:filename];
        }
    } @finally {
        [lock unlock];
    }
}


+ (void)migrateDatabaseFileIfNeeded:(NSString *)filename toPath:(NSString *)targetPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [self documentsDirectoryPath];
    NSString *oldPath = [documentsPath stringByAppendingPathComponent:filename];
    
    if ([self isSameLocation:oldPath andPath:targetPath]) {
            return;
    }
    
    if ([fileManager fileExistsAtPath:targetPath]) {
        if ([fileManager fileExistsAtPath:oldPath]){
            NSError *error = nil;
            [fileManager removeItemAtPath:oldPath error:&error];
            if(!error){
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] File to be removed from the Document Directory: %@", filename);
                [self cleanupOldDatabaseFiles:filename inDirectory:documentsPath];
            }else{
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] File could not be removed from the Document Directory: %@", filename);
            }
        }
        return;
    }
        
    if (![fileManager fileExistsAtPath:oldPath]) {
        [self cleanupOldDatabaseFiles:filename inDirectory:documentsPath];
        return;
    }
    NSError *error = nil;
    BOOL success = [fileManager moveItemAtPath:oldPath toPath:targetPath error:&error];
    
    if (success) {
        [self migrateAssociatedFiles:filename fromDirectory:documentsPath toDirectory:[self applicationSupportDirectoryPath]];
    } else {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Migration failed for %@: %@", filename, error);
        
        error = nil;
        success = [fileManager copyItemAtPath:oldPath toPath:targetPath error:&error];
        
        if (success) {
            [self migrateAssociatedFiles:filename fromDirectory:documentsPath toDirectory:[self applicationSupportDirectoryPath]];
            
            [fileManager removeItemAtPath:oldPath error:nil];
        } else {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Copy fallback also failed: %@", error);
        }
    }
}

+ (void)migrateAssociatedFiles:(NSString *)baseFilename
                 fromDirectory:(NSString *)sourceDir
                   toDirectory:(NSString *)targetDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([self isSameLocation:sourceDir andPath:targetDir]) {
            return;
    }
    
    NSArray *extensions = @[@"-shm", @"-wal", @"-journal"];
    
    for (NSString *extension in extensions) {
        NSString *associatedFilename = [baseFilename stringByAppendingString:extension];
        NSString *sourcePath = [sourceDir stringByAppendingPathComponent:associatedFilename];
        NSString *targetPath = [targetDir stringByAppendingPathComponent:associatedFilename];
        
        if ([fileManager fileExistsAtPath:sourcePath]) {
            NSError *error = nil;
            BOOL success = NO;
            
            if ([fileManager fileExistsAtPath:targetPath]) {
                NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
                NSURL *targetURL = [NSURL fileURLWithPath:targetPath];
                NSURL *resultingURL = nil;
                
                success = [fileManager replaceItemAtURL:targetURL
                                          withItemAtURL:sourceURL
                                         backupItemName:nil
                                                options:NSFileManagerItemReplacementUsingNewMetadataOnly
                                       resultingItemURL:&resultingURL
                                                  error:&error];
                
                if (success) {
                    NSError *removeError = nil;
                    [fileManager removeItemAtPath:sourcePath error:&removeError];
                    if (removeError) {
                        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not remove source after replace: %@", removeError);
                    }
                    continue;
                } else {
                    error = nil;
                    [fileManager removeItemAtPath:targetPath error:&error];
                }
            }
            
            error = nil;
            success = [fileManager moveItemAtPath:sourcePath toPath:targetPath error:&error];
            
            if (success) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Migrated associated file: %@", associatedFilename);
            } else {
                error = nil;
                success = [fileManager copyItemAtPath:sourcePath toPath:targetPath error:&error];
                if (success) {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Copied associated file: %@", associatedFilename);
                    [fileManager removeItemAtPath:sourcePath error:nil];
                } else {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Could not migrate associated file %@: %@",
                                             associatedFilename, error);
                }
            }
        }
    }
}

+ (void)cleanupOldDatabaseFiles:(NSString *)baseFilename inDirectory:(NSString *)directory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *extensions = @[@"-shm", @"-wal", @"-journal"];
    
    for (NSString *extension in extensions) {
        NSString *filename = [baseFilename stringByAppendingString:extension];
        NSString *filePath = [directory stringByAppendingPathComponent:filename];
        
        if ([fileManager fileExistsAtPath:filePath]) {
            NSError *error = nil;
            [fileManager removeItemAtPath:filePath error:&error];
            if (error) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not cleanup %@: %@", filename, error);
            }
        }
    }
}

#pragma mark - Directory Migration

+ (void)migrateDirectoryToApplicationSupportIfNeeded:(NSString *)directoryName {
    if (!directoryName || directoryName.length == 0) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Invalid directory name");
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *oldDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *oldDirectory = [oldDocuments stringByAppendingPathComponent:directoryName];
    
    NSString *appSupport = [self applicationSupportDirectoryPath];
    NSString *newDirectory = [appSupport stringByAppendingPathComponent:directoryName];
    
    BOOL oldDirectoryExists = [fileManager fileExistsAtPath:oldDirectory];
    BOOL newDirectoryExists = [fileManager fileExistsAtPath:newDirectory];
    
    if ([self isSameLocation:oldDirectory andPath:newDirectory]) {
            return;
    }
    
    if (!oldDirectoryExists && !newDirectoryExists) {
        
        NSError *error = nil;
        BOOL created = [fileManager createDirectoryAtPath:newDirectory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
        if (!created) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Failed to create directory %@: %@", directoryName, error);
        }
        return;
    }
    
    if (oldDirectoryExists && !newDirectoryExists) {
        NSArray *filesToMigrate = [fileManager contentsOfDirectoryAtPath:oldDirectory error:nil];
        NSUInteger fileCount = filesToMigrate ? filesToMigrate.count : 0;
        
        if (fileCount == 0) {
            [fileManager removeItemAtPath:oldDirectory error:nil];
            
            NSError *error = nil;
            [fileManager createDirectoryAtPath:newDirectory
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error];
            if (error) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Failed to create directory: %@", error);
            }
            return;
        }
        
        
        NSError *error = nil;
        BOOL success = [fileManager moveItemAtPath:oldDirectory toPath:newDirectory error:&error];
        
        if (success) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Successfully migrated %lu items to Application Support", (unsigned long)fileCount);
        } else {
            error = nil;
            success = [fileManager copyItemAtPath:oldDirectory toPath:newDirectory error:&error];
            
            if (success) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Successfully copied %lu items", (unsigned long)fileCount);

                NSError *removeError = nil;
                BOOL removed = [fileManager removeItemAtPath:oldDirectory error:&removeError];
                if (!removed) {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not remove old directory: %@", removeError);
                }
            } else {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Copy fallback failed: %@", error);
            }
        }
        return;
    }
    if (newDirectoryExists && !oldDirectoryExists) {
        return;
    }
    if (oldDirectoryExists && newDirectoryExists) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Found %@ in both locations - cleaning up Documents", directoryName);
        
        NSError *error = nil;
        BOOL removed = [fileManager removeItemAtPath:oldDirectory error:&error];
        if (!removed) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not remove Documents directory: %@", error);
        }
        return;
    }
}

+ (BOOL)isSameLocation:(NSString *)path1 andPath:(NSString *)path2 {
    NSString *standardized1 = [path1 stringByStandardizingPath];
    NSString *standardized2 = [path2 stringByStandardizingPath];
    
    if ([standardized1 isEqualToString:standardized2]) {
        return YES;
    }
    
    NSURL *url1 = [NSURL fileURLWithPath:standardized1];
    NSURL *url2 = [NSURL fileURLWithPath:standardized2];
    NSString *resolved1 = [[url1 URLByResolvingSymlinksInPath] path];
    NSString *resolved2 = [[url2 URLByResolvingSymlinksInPath] path];
    
    return [resolved1 isEqualToString:resolved2];
}

@end
