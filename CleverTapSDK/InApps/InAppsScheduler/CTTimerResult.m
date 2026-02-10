//
//  CTTimerResult.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 23/01/26.
//

#import "CTTimerResult.h"

@implementation CTTimerResult

+ (instancetype)completedWithId:(NSString *)resultId scheduledAt:(NSTimeInterval)scheduledAt {
    CTTimerResult *result = [[CTTimerResult alloc] init];
    result->_type = CTTimerResultTypeCompleted;
    result->_resultId = [resultId copy];
    result->_scheduledAt = scheduledAt;
    return result;
}

+ (instancetype)errorWithId:(NSString *)resultId exception:(NSError *)exception {
    CTTimerResult *result = [[CTTimerResult alloc] init];
    result->_type = CTTimerResultTypeError;
    result->_resultId = [resultId copy];
    result->_exception = exception;
    return result;
}

+ (instancetype)discardedWithId:(NSString *)resultId {
    CTTimerResult *result = [[CTTimerResult alloc] init];
    result->_type = CTTimerResultTypeDiscarded;
    result->_resultId = [resultId copy];
    return result;
}

@end
