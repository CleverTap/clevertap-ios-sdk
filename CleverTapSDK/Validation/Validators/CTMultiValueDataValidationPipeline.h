#import <Foundation/Foundation.h>
#import "CTEventDataValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTMultiValueDataValidationPipeline : CTEventDataValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config;
@end

NS_ASSUME_NONNULL_END
