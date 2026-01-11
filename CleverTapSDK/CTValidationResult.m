#import "CTValidationResult.h"

@interface CTValidationResult () {
    NSObject *object;
    int errorCode;
    NSString *errorDesc;
}
@end

@implementation CTValidationResult

@synthesize outcome = _outcome;
@synthesize dropReason = _dropReason;
@synthesize cleanedData = _cleanedData;
@synthesize subResults = _subResults;

+ (CTValidationResult *)resultWithErrorCode:(int)code andMessage:(NSString *)message {
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    [vr setErrorCode:code];
    [vr setErrorDesc:message];
    vr.outcome = (code >= 513 && code <= 514) ? CTValidationOutcomeDrop : CTValidationOutcomeWarning;
    return vr;
}

- (id)init {
    if (self = [super init]) {
        errorCode = 0;
        _outcome = CTValidationOutcomeSuccess;
        _subResults = nil;
    }
    return self;
}

- (NSString *)errorDesc { return errorDesc; }
- (NSObject *)object { return object; }
- (int)errorCode { return errorCode; }
- (void)setErrorDesc:(NSString *)errorDsc { errorDesc = errorDsc; }
- (void)setObject:(NSObject *)obj { object = obj; }
- (void)setErrorCode:(int)errorCod { errorCode = errorCod; }

#pragma mark - Basic Creation Methods

+ (CTValidationResult *)success {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.outcome = CTValidationOutcomeSuccess;
    result.errorCode = 0;
    return result;
}

+ (CTValidationResult *)successWithData:(id)data {
    CTValidationResult *result = [self success];
    result.cleanedData = data;
    [result setObject:data];
    return result;
}

+ (CTValidationResult *)warningWithCode:(int)code message:(NSString *)message data:(nullable id)data {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.outcome = CTValidationOutcomeWarning;
    result.errorCode = code;
    result.errorDesc = message;
    result.cleanedData = data;
    [result setObject:data];
    return result;
}

+ (CTValidationResult *)dropWithCode:(int)code message:(NSString *)message reason:(CTDropReason)reason {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.outcome = CTValidationOutcomeDrop;
    result.errorCode = code;
    result.errorDesc = message;
    result.dropReason = reason;
    result.cleanedData = nil;
    return result;
}

#pragma mark - Sub-Results Methods

+ (CTValidationResult *)successWithData:(id)data subResults:(nullable NSArray<CTValidationResult *> *)subResults {
    CTValidationResult *result = [self successWithData:data];
    result.subResults = subResults;
    return result;
}

+ (CTValidationResult *)warningWithSubResults:(NSArray<CTValidationResult *> *)subResults data:(nullable id)data {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.outcome = CTValidationOutcomeWarning;
    result.subResults = subResults;
    result.cleanedData = data;
    [result setObject:data]; // For backward compatibility
    // Aggregate error information from sub-results
    if (subResults.count > 0) {
        result.errorCode = subResults.firstObject.errorCode;
        result.errorDesc = [NSString stringWithFormat:@"%lu validation warnings",
                           (unsigned long)subResults.count];
    }
    return result;
}

+ (CTValidationResult *)dropWithSubResults:(NSArray<CTValidationResult *> *)subResults reason:(CTDropReason)reason {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.outcome = CTValidationOutcomeDrop;
    result.subResults = subResults;
    result.dropReason = reason;
    // Aggregate error information from sub-results
    if (subResults.count > 0) {
        result.errorCode = subResults.firstObject.errorCode;
        result.errorDesc = [NSString stringWithFormat:@"%lu validation errors",
                           (unsigned long)subResults.count];
    }
    return result;
}

#pragma mark - Helper Methods

- (BOOL)shouldDrop {
    return self.outcome == CTValidationOutcomeDrop;
}
@end
