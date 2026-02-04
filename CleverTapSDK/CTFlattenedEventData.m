#import "CTFlattenedEventData.h"

@interface CTFlattenedEventData ()
@property (nonatomic, strong, nullable) id data;
@end

@implementation CTFlattenedEventData

+ (instancetype)profileChanges:(NSDictionary<NSString *, id> *)changes {
    CTFlattenedEventData *event = [[self alloc] init];
    event->_type = CTFlattenedEventDataTypeProfileChanges;
    event.data = [changes copy];
    return event;
}

+ (instancetype)eventProperties:(NSDictionary<NSString *, id> *)properties {
    CTFlattenedEventData *event = [[self alloc] init];
    event->_type = CTFlattenedEventDataTypeEventProperties;
    event.data = [properties copy];
    return event;
}

+ (instancetype)noData {
    static CTFlattenedEventData *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance->_type = CTFlattenedEventDataTypeNoData;
    });
    return instance;
}

- (nullable NSDictionary<NSString *, id> *)profileChanges {
    return self.type == CTFlattenedEventDataTypeProfileChanges ? self.data : nil;
}

- (nullable NSDictionary<NSString *, id> *)eventProperties {
    return self.type == CTFlattenedEventDataTypeEventProperties ? self.data : nil;
}

- (BOOL)isNoData {
    return self.type == CTFlattenedEventDataTypeNoData;
}

@end
