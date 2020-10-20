#include <stdatomic.h>
#import <libkern/OSAtomic.h>
#import "CTObjectSequenceGenerator.h"

@implementation CTObjectSequenceGenerator {
    atomic_int_fast32_t _value;
}

- (instancetype)init {
    return [self initWithInitialValue:0];
}

- (instancetype)initWithInitialValue:(int32_t)initialValue {
    self = [super init];
    if (self) {
        _value = initialValue;
    }
    return self;
}

- (int32_t)nextValue {
    return atomic_fetch_add_explicit(&_value, 1, memory_order_relaxed);
}

@end
