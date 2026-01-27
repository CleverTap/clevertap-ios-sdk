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

- (NSString *)description {
    switch (self.type) {
        case CTInActionResultTypeReadyToFetch:
            return [NSString stringWithFormat:@"ReadyToFetch(id: %@, data: %@)",
                    self.inActionId, self.data];
        case CTInActionResultTypeError:
            return [NSString stringWithFormat:@"Error(id: %@, message: %@)",
                    self.inActionId, self.message];
        case CTInActionResultTypeCancelled:
            return [NSString stringWithFormat:@"Cancelled(id: %@, message: %@)",
                    self.inActionId, self.message];
        case CTInActionResultTypeDiscarded:
            return [NSString stringWithFormat:@"Discarded(id: %@, message: %@)",
                    self.inActionId, self.message];
    }
}

@end
