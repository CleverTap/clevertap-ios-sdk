#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CTFlattenedEventDataType) {
    CTFlattenedEventDataTypeProfileChanges,
    CTFlattenedEventDataTypeEventProperties,
    CTFlattenedEventDataTypeNoData
};

@interface CTFlattenedEventData : NSObject

@property (nonatomic, assign, readonly) CTFlattenedEventDataType type;

+ (instancetype)profileChanges:(NSDictionary<NSString *, id> *)changes;
+ (instancetype)eventProperties:(NSDictionary<NSString *, id> *)properties;
+ (instancetype)noData;
- (nullable NSDictionary<NSString *, id> *)profileChanges;
- (nullable NSDictionary<NSString *, id> *)eventProperties;
- (BOOL)isNoData;

@end

NS_ASSUME_NONNULL_END
