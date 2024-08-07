//
//  CTCustomTemplate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTCustomTemplate : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, readonly) BOOL isVisual;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
