//
//  CTInAppTimer.h
//  CleverTap-iOS-SDK-iOS
//
//  Created by Sonal Kachare on 17/09/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppTimer : NSObject

@property (nonatomic, copy) void (^completionHandler)(void);
@property (nonatomic, assign, readonly) NSTimeInterval delay;
@property (nonatomic, assign, readonly) NSTimeInterval remainingTime;
@property (nonatomic, assign, readonly) BOOL isPaused;

- (instancetype)initWithDelay:(NSTimeInterval)delay completion:(void (^)(void))completion;
- (void)start;
- (void)pause;
- (void)resume;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
