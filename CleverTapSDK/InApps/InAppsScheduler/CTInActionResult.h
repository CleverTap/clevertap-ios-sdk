//
//  CTInActionResult.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 24/01/26.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CTInActionResultType) {
    CTInActionResultTypeReadyToFetch,
    CTInActionResultTypeError,
    CTInActionResultTypeCancelled,
    CTInActionResultTypeDiscarded
};

NS_ASSUME_NONNULL_BEGIN

@interface CTInActionResult : NSObject

@property (nonatomic, readonly) CTInActionResultType type;
@property (nonatomic, readonly) NSString* inActionId;

// ReadyToFetch properties
@property (nonatomic, readonly, strong, nullable) NSDictionary<NSString *, id> *data;

// Error and Discarded properties
@property (nonatomic, readonly, copy, nullable) NSString *message;

// Factory methods
+ (instancetype)readyToFetchWithId:(NSString *)inActionId data:(NSDictionary<NSString *, id> *)data;
+ (instancetype)errorWithId:(NSString *)inActionId message:(NSString *)message;
+ (instancetype)cancelledWithId:(NSString *)inActionId message:(NSString *)message;
+ (instancetype)discardedWithId:(NSString *)inActionId message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
