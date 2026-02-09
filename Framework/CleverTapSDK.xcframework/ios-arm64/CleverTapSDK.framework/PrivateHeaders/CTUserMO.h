#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CTEncryptionManager.h"

@interface CTUserMO : NSManagedObject
@property (nonatomic, strong) CTEncryptionManager *encryptionManager;
@end

#import "CTUserMO+CoreDataProperties.h"
