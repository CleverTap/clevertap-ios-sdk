//
//  CTCryptMigrator.h
//  Pods
//
//  Created by Kushagra Mishra on 16/02/25.
//

#import <Foundation/Foundation.h>
#import "CTDeviceInfo.h"

@class CleverTapInstanceConfig;
@class CleverTapEventDetail;

@interface CTCryptMigrator : NSObject

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 andDeviceInfo:(CTDeviceInfo*)deviceInfo
                 profileValues:(NSDictionary*)profileValues;

@end
