//
//  CTInAppStore.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppStore : NSObject

@property (nonatomic, strong, nullable) NSString *mode;

- (NSArray *)clientSideInApps;
- (NSArray *)serverSideInApps;

@end

NS_ASSUME_NONNULL_END