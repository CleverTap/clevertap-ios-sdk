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

/*!
 Hand a content fetch response to the delegate for parsing.

 @param completion Run by the delegate once parsing has finished, never before. Parsing may happen
 on another queue, so returning from this method does not mean the batch is done. Whatever waits
 on the batch, such as the app-launch arbitration window, is released when this runs.
 */
- (void)contentFetchManager:(CTContentFetchManager *)manager
         didReceiveResponse:(NSData *)data
                 completion:(dispatch_block_t)completion;

- (void)contentFetchManager:(CTContentFetchManager *)manager
        addMetadataToEvent:(NSMutableDictionary *)event
                     ofType:(CleverTapEventType)eventType;

@optional

- (void)contentFetchManager:(CTContentFetchManager *)manager didFailWithError:(NSError *)error;

@end

#endif /* CTContentFetchManagerDelegate_h */
