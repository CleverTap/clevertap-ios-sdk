//
//  CTDeleteOperationHandler.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import <Foundation/Foundation.h>
#import "CTProfileChangeTracker.h"
#import "CTProfileOperationUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTDeleteOperationHandler : NSObject

- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker;
- (BOOL)handleDelete:(NSMutableDictionary *)target
                 key:(NSString *)key
            newValue:(id)newValue
         currentPath:(NSString *)currentPath
             changes:(nullable NSMutableDictionary<NSString *, NSDictionary *> *)changes
     recursiveMerge:(CTProfileRecursiveBlock)recursiveMerge;

@end

NS_ASSUME_NONNULL_END
