//
//  CTDelayedInAppResult.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 24/01/26.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CTDelayedInAppResultType) {
    CTDelayedInAppResultTypeSuccess,
    CTDelayedInAppResultTypeError,
    CTDelayedInAppResultTypeDiscarded
};

typedef NS_ENUM(NSInteger, CTErrorReason) {
    CTErrorReasonUnknown,
    CTErrorReasonPreparationFailed,
    CTErrorReasonDataNotFound
};

@interface CTDelayedInAppResult : NSObject

@property (nonatomic, readonly) CTDelayedInAppResultType type;
@property (nonatomic, readonly, copy) NSString * _Nullable resultId;

// Properties for success case
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, id> *data;

// Properties for error case
@property (nonatomic, readonly) CTErrorReason reason;
@property (nonatomic, readonly, nullable) NSError *exception;

// Property for discarded case
@property (nonatomic, readonly, nullable) NSString *message;

+ (instancetype _Nullable)successWithId:(NSString *_Nonnull)resultId data:(NSDictionary<NSString *, id> * _Nullable)data;
+ (instancetype _Nullable)errorWithId:(NSString * _Nonnull)resultId reason:(CTErrorReason)reason exception:(nullable NSError *)exception;
+ (instancetype _Nullable)discardedWithId:(NSString * _Nonnull)resultId message:(NSString * _Nullable)message;

@end
