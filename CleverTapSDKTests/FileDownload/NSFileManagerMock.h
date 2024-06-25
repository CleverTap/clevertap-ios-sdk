//
//  NSFileManagerMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 24.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManagerMock : NSFileManager

@property (nonatomic, strong) NSError *createDirectoryError;
@property (nonatomic, strong) NSError *removeItemError;
@property (nonatomic, strong) NSError *moveItemError;
@property (nonatomic, assign) BOOL fileExists;
@property (nonatomic, strong) NSError *contentsOfDirectoryError;

@end

NS_ASSUME_NONNULL_END
