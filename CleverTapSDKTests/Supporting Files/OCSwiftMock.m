
#import "OCSwiftMock.h"
#import <OCMock/OCMock.h>

@implementation OCSwiftMock

- (instancetype)initWithInstanceOfClass:(Class)mockClass {
    self = [super init];
    if (self) {
        _object = OCMStrictClassMock(mockClass);
    }
    return self;
}

- (instancetype)initWithPartialObject:(NSObject *)anObject {
    self = [super init];
    if (self) {
        _object = OCMPartialMock(anObject);
    }
    return self;
}

- (instancetype)initWithClass:(Class)mockClass {
    self = [super init];
       if (self) {
           _object = OCMClassMock(mockClass);
       }
       return self;
}

- (id)andReturn:(id)value {
    return [[self.object stub] andReturn:value];
}

- (id)expect {
    return [self.object expect];
}

- (id)reject {
    return [self.object reject];
}

- (id)verify {
    return [self.object verify];
}

@end
