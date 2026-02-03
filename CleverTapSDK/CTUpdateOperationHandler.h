//
//  CTUpdateOperationHandler.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import <Foundation/Foundation.h>
#import "CTProfileChangeTracker.h"
#import "CTArrayOperationHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTUpdateOperationHandler : NSObject

- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker
                        arrayHandler:(CTArrayOperationHandler *)arrayHandler;

- (void)handleOperation:(NSMutableDictionary *)target
                    key:(NSString *)key
               newValue:(id)newValue
            currentPath:(NSString *)currentPath
                changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes
              operation:(CTProfileOperation)operation
        recursiveApply:(CTProfileRecursiveBlock)recursiveApply;

@end

NS_ASSUME_NONNULL_END
