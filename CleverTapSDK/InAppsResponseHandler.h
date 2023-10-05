//
//  InAppsResponseHandler.h
//  Pods
//
//  Created by Akash Malhotra on 03/07/23.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"
#import "CTInAppFCManager.h"
#import "CTDispatchQueueManager.h"
#import "CTInappsController.h"

@interface InAppsResponseHandler : NSObject

- (void)processResponse:(NSDictionary* _Nonnull)jsonResp;
- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config inAppFCManager:(CTInAppFCManager* _Nonnull)inAppFCManager dispatchQueueManager:(CTDispatchQueueManager* _Nonnull)dispatchQueueManager inappsController:(CTInappsController* _Nonnull)inappsController;

@end

