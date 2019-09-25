#import "CTABTestEditorVarsMessageRequest.h"
#import "CTABTestEditorVarsMessageResponse.h"

NSString *const CTABTestEditorVarsMessageRequestType = @"vars_request";

@interface CTABTestEditorVarsMessageRequest ()

@property (nonatomic, strong)NSArray<NSDictionary*> *serializedVars;

@end

@implementation CTABTestEditorVarsMessageRequest

+ (instancetype)message {
     return [(CTABTestEditorVarsMessageRequest *)[self alloc] initWithType:CTABTestEditorVarsMessageRequestType];
}

+ (instancetype)messageWithOptions:(NSDictionary *)options {
    CTABTestEditorVarsMessageRequest *message = [CTABTestEditorVarsMessageRequest message];
    message.serializedVars = options[@"vars"];
    return message;
}

- (CTABTestEditorMessage *)response {
    CTABTestEditorVarsMessageResponse *message = [CTABTestEditorVarsMessageResponse messageWithOptions:nil];
    message.vars = self.serializedVars;
    return message;
}

@end
