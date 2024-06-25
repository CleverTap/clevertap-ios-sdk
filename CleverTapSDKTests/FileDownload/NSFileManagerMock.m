//
//  NSFileManagerMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 24.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "NSFileManagerMock.h"

@implementation NSFileManagerMock

- (BOOL)fileExistsAtPath:(NSString *)path {
    return self.fileExists;
}

- (BOOL)createDirectoryAtURL:(NSURL *)url withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSString *,id> *)attributes error:(NSError **)error {
    if (self.createDirectoryError) {
        *error = self.createDirectoryError;
        return NO;
    }
    return YES;
}

- (BOOL)removeItemAtURL:(NSURL *)URL error:(NSError **)error {
    if (self.removeItemError) {
        *error = self.removeItemError;
        return NO;
    }
    return YES;
}

- (BOOL)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError **)error {
    if (self.moveItemError) {
        *error = self.moveItemError;
        return NO;
    }
    return YES;
}

- (NSArray<NSURL *> *)contentsOfDirectoryAtURL:(NSURL *)url includingPropertiesForKeys:(NSArray<NSURLResourceKey> *)keys options:(NSDirectoryEnumerationOptions)mask error:(NSError *__autoreleasing  _Nullable *)error {
    if (self.contentsOfDirectoryError) {
        *error = self.contentsOfDirectoryError;
        return nil;
    }

    return [super contentsOfDirectoryAtURL:url includingPropertiesForKeys:keys options:mask error:error];
}

@end
