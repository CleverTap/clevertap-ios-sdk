//
//  CTProfileOperationUtils.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
