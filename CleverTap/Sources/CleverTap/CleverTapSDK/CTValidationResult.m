#import "CTValidationResult.h"

@interface CTValidationResult () {
    NSObject *object;
    int errorCode;
    NSString *errorDesc;
}

@end

@implementation CTValidationResult

+ (CTValidationResult *) resultWithErrorCode:(int) code andMessage:(NSString*) message {
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    [vr setErrorCode:code];
    [vr setErrorDesc:message];
    return vr;
}

- (id)init {
    if (self = [super init]) {
        errorCode = 0;
    }
    return self;
}

- (NSString *)errorDesc {
    return errorDesc;
}

- (NSObject *)object {
    return object;
}

- (int)errorCode {
    return errorCode;
}

- (void)setErrorDesc:(NSString *)errorDsc {
    errorDesc = errorDsc;
}

- (void)setObject:(NSObject *)obj {
    object = obj;
}

- (void)setErrorCode:(int)errorCod {
    errorCode = errorCod;
}

@end
