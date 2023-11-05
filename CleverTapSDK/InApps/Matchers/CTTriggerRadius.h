//
//  CTTriggerRadius.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 5.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggerRadius : NSObject

@property (strong, nonatomic) NSNumber *latitude;
@property (strong, nonatomic) NSNumber *longitude;
@property (strong, nonatomic) NSNumber *radius;

@end

NS_ASSUME_NONNULL_END
