//
//  CTInActionResult.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 24/01/26.
//

#import "CTInActionResult.h"

@implementation CTInActionResult

+ (instancetype)readyToFetchWithId:(NSString *)inActionId data:(NSDictionary<NSString *, id> *)data {
    CTInActionResult *result = [[CTInActionResult alloc] init];
    result->_type = CTInActionResultTypeReadyToFetch;
    result->_inActionId = inActionId;
    result->_data = data;
    return result;
}

+ (instancetype)errorWithId:(NSString *)inActionId message:(NSString *)message {
    CTInActionResult *result = [[CTInActionResult alloc] init];
    result->_type = CTInActionResultTypeError;
    result->_inActionId = inActionId;
    result->_message = [message copy];
    return result;
}

+ (instancetype)discardedWithId:(NSString *)inActionId message:(NSString *)message {
    CTInActionResult *result = [[CTInActionResult alloc] init];
    result->_type = CTInActionResultTypeDiscarded;
    result->_inActionId = inActionId;
    result->_message = [message copy];
    return result;
}

+ (instancetype)cancelledWithId:(NSString *)inActionId message:(NSString *)message {
    CTInActionResult *result = [[CTInActionResult alloc] init];
    result->_type = CTInActionResultTypeCancelled;
    result->_inActionId = inActionId;
    result->_message = [message copy];
    return result;
}

@end
