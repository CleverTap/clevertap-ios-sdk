
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCSwiftMock<MockType> : NSObject

@property (nonatomic, readonly) MockType object;

- (instancetype)initWithInstanceOfClass:(Class)mockClass;

- (instancetype)initWithPartialObject:(NSObject *)anObject;

- (instancetype)initWithClass:(Class)mockClass;

- (MockType)andReturn:(id)value;

- (MockType)expect;
- (MockType)reject;

- (MockType)verify;

@end

NS_ASSUME_NONNULL_END
