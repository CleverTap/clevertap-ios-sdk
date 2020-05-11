#import "CleverTap+ProductConfig.h"

@implementation CleverTapConfigValue {
    NSData *_data;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _data = [data copy];
    }
    return self;
}

- (instancetype)init {
    return [self initWithData:nil];
}

- (NSString *)stringValue {
    return [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
}

- (NSNumber *)numberValue {
    return [NSNumber numberWithDouble:self.stringValue.doubleValue];
}

- (NSData *)dataValue {
    return _data;
}

- (BOOL)boolValue {
    return self.stringValue.boolValue;
}

- (id)jsonValue {
    NSError *error;
    if (!_data) {
        return nil;
    }
    id JSONObject = [NSJSONSerialization JSONObjectWithData:_data options:kNilOptions error:&error];
    if (error) {
        return nil;
    }
    return JSONObject;
}

- (NSString *)debugDescription {
    NSString *content = [NSString
                         stringWithFormat:@"Boolean: %d, String: %@, Number: %@, JSON:%@, Data: %@",
                         self.boolValue, self.stringValue, self.numberValue, self.jsonValue, _data];
    return [NSString stringWithFormat:@"<%@: %p, %@>", [self class], self, content];
}

- (id)copyWithZone:(NSZone *)zone {
    CleverTapConfigValue *value = [[[self class] allocWithZone:zone] initWithData:_data];
    return value;
}

@end
