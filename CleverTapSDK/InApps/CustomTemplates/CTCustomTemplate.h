//
//  CTCustomTemplate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 A definition of a custom template. Can be a function or a code template.
 Instances are uniquely identified by their name.
 */
@interface CTCustomTemplate : NSObject

/*!
 The name of the template.
 */
@property (nonatomic, strong, readonly) NSString *name;

/*!
 Whether the template has UI or not.
 */
@property (nonatomic, readonly) BOOL isVisual;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
