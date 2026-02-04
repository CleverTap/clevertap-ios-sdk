//
//  CTDelayedInAppResult.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 24/01/26.
//
#import "CTDelayedInAppResult.h"

@implementation CTDelayedInAppResult

+ (instancetype)successWithId:(NSString *)resultId data:(NSDictionary<NSString *, id> *)data {
    CTDelayedInAppResult *result = [[CTDelayedInAppResult alloc] init];
    result->_type = CTDelayedInAppResultTypeSuccess;
    result->_resultId = [resultId copy];
    result->_data = data;
    return result;
}

+ (instancetype)errorWithId:(NSString *)resultId reason:(CTErrorReason)reason exception:(nullable NSError *)exception {
    CTDelayedInAppResult *result = [[CTDelayedInAppResult alloc] init];
    result->_type = CTDelayedInAppResultTypeError;
    result->_resultId = [resultId copy];
    result->_reason = reason;
    result->_exception = exception;
    return result;
}

+ (instancetype)discardedWithId:(NSString *)resultId message:(NSString *)message {
    CTDelayedInAppResult *result = [[CTDelayedInAppResult alloc] init];
    result->_type = CTDelayedInAppResultTypeDiscarded;
    result->_resultId = [resultId copy];
    result->_message = [message copy];
    return result;
}

@end
