//
//  CTContentFetchManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 19.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTDomainFactory.h"
#import "CTContentFetchManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class CTRequestSender;
@class CleverTapInstanceConfig;
@class CTDispatchQueueManager;

@interface CTContentFetchManager : NSObject <CTSwitchUserDelegate>

@property (nonatomic, weak) id<CTContentFetchManagerDelegate> delegate;

/**
 * Initialize the Content Fetch Manager
 * @param config The CleverTap instance configuration
 * @param requestSender The request sender to use for network requests
 * @param domainOperations Domain operations for handling handshakes
 * @param delegate The delegate to receive callbacks
 */
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 requestSender:(CTRequestSender *)requestSender
                 dispatchQueueManager:(CTDispatchQueueManager *)dispatchQueueManager
               domainOperations:(id<CTDomainOperations>)domainOperations
                      delegate:(id<CTContentFetchManagerDelegate>)delegate;

/**
 * Process content fetch information from response
 * @param jsonResp The JSON response dictionary
 */
- (void)handleContentFetch:(NSDictionary *)jsonResp;

@end

NS_ASSUME_NONNULL_END
