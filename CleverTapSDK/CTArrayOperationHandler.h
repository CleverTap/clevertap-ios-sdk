//
//  CTArrayOperationHandler.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import <Foundation/Foundation.h>
#import "CTProfileChangeTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTArrayOperationHandler : NSObject
- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker;

- (void)handleArrayOperation:(NSMutableDictionary *)parentJson
                         key:(NSString *)key
                    oldArray:(NSMutableArray *)oldArray
                    newArray:(NSArray *)newArray
                 currentPath:(NSString *)currentPath
                     changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes
                   operation:(CTProfileOperation)operation
          recursiveTraversal:(CTProfileRecursiveBlock)recursiveTraversal;

@end

NS_ASSUME_NONNULL_END
