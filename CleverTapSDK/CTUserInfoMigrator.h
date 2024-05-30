//
//  CTUserInfoMigrator.h
//  Pods
//
//  Created by Kushagra Mishra on 29/05/24.
//

#import <Foundation/Foundation.h>

@interface CTUserInfoMigrator : NSObject

+ (void)migrateUserInfoFileForAccountID:(NSString *)acc_id deviceID:(NSString *)device_id;

@end
