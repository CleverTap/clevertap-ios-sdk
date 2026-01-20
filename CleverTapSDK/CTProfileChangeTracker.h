//
//  CTProfileChangeTracker.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 16/12/25.
//

#import <Foundation/Foundation.h>
#import "CTLocalDataStore.h"

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

@end

#pragma mark - Delete Operation Handler

@interface CTDeleteOperationHandler : NSObject

- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker;
- (BOOL)handleDelete:(NSMutableDictionary *)target
                 key:(NSString *)key
            newValue:(id)newValue
         currentPath:(NSString *)currentPath
             changes:(nullable NSMutableDictionary<NSString *, NSDictionary *> *)changes
     recursiveMerge:(CTProfileRecursiveBlock)recursiveMerge;

@end

#pragma mark - Array Operation Handler

@interface CTArrayOperationHandler : NSObject

- (void)handleArrayOperation:(NSMutableDictionary *)parentJson
                         key:(NSString *)key
                    oldArray:(NSMutableArray *)oldArray
                    newArray:(NSArray *)newArray
                 currentPath:(NSString *)currentPath
                     changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes
                   operation:(CTProfileOperation)operation
          recursiveTraversal:(CTProfileRecursiveBlock)recursiveTraversal;

@end

#pragma mark - Update Operation Handler

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

#pragma mark - Utility Classes

@interface CTProfileOperationUtils : NSObject
+ (BOOL)isDeleteMarker:(id)value;
+ (id)processDatePrefixes:(id)value;
@end

@interface CTArrayMergeUtils : NSObject
+ (NSArray *)copyArray:(NSArray *)array;
+ (BOOL)hasDeleteMarkerElements:(NSArray *)array;
+ (BOOL)hasJsonObjectElements:(NSArray *)array;
+ (BOOL)shouldMergeArrayElements:(NSArray *)array;
+ (BOOL)arrayContainsString:(NSArray *)array string:(NSString *)string;
@end

@interface CTNumberOperationUtils : NSObject
+ (NSNumber *)addNumbers:(NSNumber *)a number:(NSNumber *)b;
+ (NSNumber *)subtractNumbers:(NSNumber *)a number:(NSNumber *)b;
+ (NSNumber *)negateNumber:(NSNumber *)n;
@end

@interface CTJsonComparisonUtils : NSObject
+ (BOOL)areEqual:(id)value1 value:(id)value2;
@end

NS_ASSUME_NONNULL_END
