//
//  CTTimerResult.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 23/01/26.
//

// CTTimerResult.h
typedef NS_ENUM(NSInteger, CTTimerResultType) {
    CTTimerResultTypeCompleted,
    CTTimerResultTypeError,
    CTTimerResultTypeDiscarded
};

@interface CTTimerResult : NSObject

@property (nonatomic, readonly) CTTimerResultType type;
@property (nonatomic, readonly, copy) NSString *resultId;

// Properties for completed case
@property (nonatomic, readonly) NSTimeInterval scheduledAt;

// Property for error case
@property (nonatomic, readonly, nullable) NSError *exception;

+ (instancetype)completedWithId:(NSString *)resultId scheduledAt:(NSTimeInterval)scheduledAt;
+ (instancetype)errorWithId:(NSString *)resultId exception:(NSError *)exception;
+ (instancetype)discardedWithId:(NSString *)resultId;

@end
