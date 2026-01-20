//
//  CTValidatorBase.h
//  CleverTap-iOS-SDK-iOS
//
//  Created by Sonal Kachare on 19/01/26.
//

#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTValidatorBase : NSObject

@property (nonatomic, strong, readonly) CTValidationConfig *config;

- (instancetype)initWithConfig:(CTValidationConfig *)config;

@end

NS_ASSUME_NONNULL_END
