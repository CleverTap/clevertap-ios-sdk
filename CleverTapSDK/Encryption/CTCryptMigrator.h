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

/**
 * CTCryptMigrator handles the migration of encryption keys and data between
 * legacy AES encryption and the new AES-GCM implementation.
 */

@interface CTCryptMigrator : NSObject

/**
 * Initializes the migrator with configuration and device information.
 * @param config The CleverTap instance configuration
 * @param deviceInfo The device information used during migration
 * @return An initialized CTCryptMigrator instance
 */

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 andDeviceInfo:(CTDeviceInfo*)deviceInfo;

- (void)migrateCachedUserIfNeeded:(NSString *)newDeviceID;

@end
