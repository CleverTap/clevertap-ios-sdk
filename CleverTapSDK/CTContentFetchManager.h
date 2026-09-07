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

/*!
 A single entry of the `content_fetch` array.

 Items are self-describing: each names the event that triggered the fetch, the response key its
 result will arrive under, and the campaign it targets. Parsing them lets callers know what to
 expect from the `/content` response before it arrives.
 */
@interface CTContentFetchItem : NSObject

/// Event that triggered the fetch, e.g. `App Launched`.
@property (nonatomic, copy, readonly, nullable) NSString *eventName;

/// Response key the fetched content will arrive under, e.g. `inapp_notifs_applaunched`.
@property (nonatomic, copy, readonly, nullable) NSString *responseKey;

/*!
 Campaign id being targeted.

 Same identity as an in-app payload's `ti`, but `tgtId` arrives as a number while `ti` may be a
 number or a string. Normalized to a string here so the two can be compared directly.
 */
@property (nonatomic, copy, readonly, nullable) NSString *targetId;

/*!
 The unparsed item.

 Preserved verbatim because this is what gets sent back as the event data of the outbound content
 fetch request — the wire format must not change.
 */
@property (nonatomic, copy, readonly) NSDictionary *rawItem;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithJSON:(NSDictionary *)json;

@end

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

/**
 * Parse the `content_fetch` array of a response into typed items.
 *
 * Read-only — nothing is enqueued or sent. Use `handleContentFetch:` to actually fetch.
 * Lets a caller inspect what the `/content` response will contain while still parsing `/a1`.
 *
 * @param jsonResp The JSON response dictionary
 * @return Parsed items, or an empty array if the key is absent, malformed, or empty.
 */
+ (NSArray<CTContentFetchItem *> *)contentFetchItemsFromResponse:(NSDictionary *)jsonResp;

@end

NS_ASSUME_NONNULL_END
