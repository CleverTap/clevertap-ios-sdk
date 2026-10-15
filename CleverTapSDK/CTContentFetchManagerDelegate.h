//
//  CTContentFetchManagerDelegate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 22.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTContentFetchManagerDelegate_h
#define CTContentFetchManagerDelegate_h

#import "CleverTapInternal.h"
@class CTContentFetchManager;

@protocol CTContentFetchManagerDelegate <NSObject>

@required

- (NSDictionary *)contentFetchManagerGetBatchHeader:(CTContentFetchManager *)manager;

- (void)contentFetchManager:(CTContentFetchManager *)manager didReceiveResponse:(NSData *)data;

- (void)contentFetchManager:(CTContentFetchManager *)manager
        addMetadataToEvent:(NSMutableDictionary *)event
                     ofType:(CleverTapEventType)eventType;

@optional

- (void)contentFetchManager:(CTContentFetchManager *)manager didFailWithError:(NSError *)error;

@end

#endif /* CTContentFetchManagerDelegate_h */
