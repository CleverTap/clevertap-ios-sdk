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

+ (NSString *)applicationSupportDirectoryPath{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                             NSUserDomainMask,
                                                             YES);
    NSString *appSupportPath = [paths firstObject];
    if (!appSupportPath) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Could not get Application Support directory");
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
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Failed to create Application Support: %@", error);
                NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES);
                NSString *fallbackPath = [docPaths firstObject];
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] FALLBACK: Using Documents directory: %@", fallbackPath);
                return fallbackPath;
            }
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Created Application Support directory: %@", appSupportPath);
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
    NSString *targetPath = [appSupportPath stringByAppendingPathComponent:filename];
    
    [self migrateDatabaseFileIfNeeded:filename toPath:targetPath];
    
    return targetPath;
}

+ (NSURL *)urlForDatabaseFile:(NSString *)filename {
    if (!filename || filename.length == 0) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Invalid filename");
        return nil;
    }
    
    NSString *path = [self pathForDatabaseFile:filename];
    return path ? [NSURL fileURLWithPath:path] : nil;
}

#pragma mark - Migration Logic

+ (void)migrateDatabaseFileIfNeeded:(NSString *)filename toPath:(NSString *)targetPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [self documentsDirectoryPath];
    NSString *oldPath = [documentsPath stringByAppendingPathComponent:filename];
    
    if ([fileManager fileExistsAtPath:targetPath]) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] File already exists in Application Support: %@", filename);
        
        if ([fileManager fileExistsAtPath:oldPath]){
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] File also exists in the Document Directory: %@", filename);
            
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
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] No migration needed for: %@", filename);
        return;
    }
    
    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Starting migration for: %@", filename);
    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] From: %@", oldPath);
    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] To: %@", targetPath);
    
    NSError *error = nil;
    BOOL success = [fileManager moveItemAtPath:oldPath toPath:targetPath error:&error];
    
    if (success) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Successfully migrated: %@", filename);
        
        [self migrateAssociatedFiles:filename fromDirectory:documentsPath toDirectory:[self applicationSupportDirectoryPath]];
    } else {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] ERROR: Migration failed for %@: %@", filename, error);
        
        error = nil;
        success = [fileManager copyItemAtPath:oldPath toPath:targetPath error:&error];
        
        if (success) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Successfully copied (fallback) : %@", filename);
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
    
    NSArray *extensions = @[@"-shm", @"-wal", @"-journal"];
    
    for (NSString *extension in extensions) {
        NSString *associatedFilename = [baseFilename stringByAppendingString:extension];
        NSString *sourcePath = [sourceDir stringByAppendingPathComponent:associatedFilename];
        NSString *targetPath = [targetDir stringByAppendingPathComponent:associatedFilename];
        
        if ([fileManager fileExistsAtPath:sourcePath]) {
            NSError *error = nil;
            BOOL success = [fileManager moveItemAtPath:sourcePath toPath:targetPath error:&error];
            
            if (success) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Migrated associated file: %@", associatedFilename);
            } else {
                error = nil;
                success = [fileManager copyItemAtPath:sourcePath toPath:targetPath error:&error];
                if (success) {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Copied associated file: %@", associatedFilename);
                    [fileManager removeItemAtPath:sourcePath error:nil];
                } else {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] WARNING: Could not migrate associated file %@: %@",
                                             associatedFilename, error);
                }
            }
        }
    }
}

+ (void)cleanupOldDatabaseFiles:(NSString *)baseFilename inDirectory:(NSString *)directory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *extensions = @[@"-shm", @"-wal", @"-journal"];
    
    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Cleaning up associated files for: %@", baseFilename);
    
    for (NSString *extension in extensions) {
        NSString *filename = [baseFilename stringByAppendingString:extension];
        NSString *filePath = [directory stringByAppendingPathComponent:filename];
        
        if ([fileManager fileExistsAtPath:filePath]) {
            NSError *error = nil;
            [fileManager removeItemAtPath:filePath error:&error];
            if (error) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not cleanup %@: %@", filename, error);
            } else {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Cleaned up: %@", filename);
            }
        }
    }
}

#pragma mark - Directory Migration

+ (void)ensureDirectoryInApplicationSupport:(NSString *)directoryName {
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
    
    if (!oldDirectoryExists && !newDirectoryExists) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Fresh install detected - creating %@ in Application Support", directoryName);
        
        NSError *error = nil;
        BOOL created = [fileManager createDirectoryAtPath:newDirectory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
        if (!created) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Failed to create directory %@: %@", directoryName, error);
        } else {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Created %@ in Application Support", directoryName);
        }
        return;
    }
    
    if (oldDirectoryExists && !newDirectoryExists) {
        NSArray *filesToMigrate = [fileManager contentsOfDirectoryAtPath:oldDirectory error:nil];
        NSUInteger fileCount = filesToMigrate ? filesToMigrate.count : 0;
        
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] SDK upgrade detected - found %lu items in Documents/%@", (unsigned long)fileCount, directoryName);
        
        if (fileCount == 0) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Old directory is empty, recreating in Application Support");
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
        
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Starting migration of %lu items from %@", (unsigned long)fileCount, directoryName);
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider]    From: %@", oldDirectory);
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider]    To: %@", newDirectory);
        
        NSError *error = nil;
        BOOL success = [fileManager moveItemAtPath:oldDirectory toPath:newDirectory error:&error];
        
        if (success) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Successfully migrated %lu items to Application Support", (unsigned long)fileCount);
        } else {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Move failed: %@", error);
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Attempting copy fallback...");
      
            error = nil;
            success = [fileManager copyItemAtPath:oldDirectory toPath:newDirectory error:&error];
            
            if (success) {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Successfully copied %lu items", (unsigned long)fileCount);

                NSError *removeError = nil;
                BOOL removed = [fileManager removeItemAtPath:oldDirectory error:&removeError];
                if (!removed) {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not remove old directory: %@", removeError);
                } else {
                    CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Cleaned up old Documents directory");
                }
            } else {
                CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Copy fallback failed: %@", error);
            }
        }
        return;
    }
    if (newDirectoryExists && !oldDirectoryExists) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] %@ already in Application Support", directoryName);
        return;
    }
    if (oldDirectoryExists && newDirectoryExists) {
        CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Found %@ in both locations - cleaning up Documents", directoryName);
        
        NSError *error = nil;
        BOOL removed = [fileManager removeItemAtPath:oldDirectory error:&error];
        if (!removed) {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Could not remove Documents directory: %@", error);
        } else {
            CleverTapLogStaticInternal(@"[CTPrivateStorageProvider] Cleaned up orphaned Documents directory");
        }
        return;
    }
}

@end
