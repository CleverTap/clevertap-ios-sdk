//
//  CTProfileChangeTracker.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 16/12/25.
//

#import <Foundation/Foundation.h>
#import "CTLocalDataStore.h"
#import "CTProfileOperationType.h"

NS_ASSUME_NONNULL_BEGIN

// Block type for recursive traversal
typedef void (^CTProfileRecursiveBlock)(NSMutableDictionary *target,
                                        NSDictionary * _Nullable source,
                                        NSString *path,
                                        NSMutableDictionary<NSString *, NSDictionary *> *changes);

#pragma mark - Change Tracker

@interface CTProfileChangeTracker : NSObject

- (void)recordAllLeafValues:(NSDictionary *)jsonObject
                        path:(NSString *)path
                     changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes;

- (void)recordChange:(NSString *)path oldValue:(id)oldValue newValue:(id)newValue changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes;

- (void)recordAddition:(id)newValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes;
@end

NS_ASSUME_NONNULL_END
