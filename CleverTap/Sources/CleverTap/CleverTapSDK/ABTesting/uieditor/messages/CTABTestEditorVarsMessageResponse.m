#import "CTABTestEditorVarsMessageResponse.h"

NSString *const CTABTestEditorVarsMessageResponseType = @"vars_response";

@implementation CTABTestEditorVarsMessageResponse

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CTABTestEditorVarsMessageResponseType];
}

- (void)setVars:(NSArray *)vars {
    [self setDataObject:vars forKey:@"vars"];
}

- (NSArray *)vars {
    return [self dataObjectForKey:@"vars"];
}
@end
