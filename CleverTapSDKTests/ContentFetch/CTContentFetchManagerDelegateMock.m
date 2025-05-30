//
//  CTContentFetchManagerDelegateMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTContentFetchManagerDelegateMock.h"
#import "CTContentFetchManager.h"

@implementation CTContentFetchManagerDelegateMock

- (instancetype)init {
    self = [super init];
    if (self) {
        // Set up default batch header
        self.batchHeader = @{
            @"g": @"test-device-id",
            @"tk": @"test-token",
            @"id": @"test-account",
            @"type": @"meta"
        };
        self.receivedResponses = [NSMutableArray array];
        self.receivedErrors = [NSMutableArray array];
        self.metadataEvents = [NSMutableArray array];
    }
    return self;
}

#pragma mark - CTContentFetchManagerDelegate

- (NSDictionary *)contentFetchManagerGetBatchHeader:(CTContentFetchManager *)manager {
    return self.batchHeader;
}

- (void)contentFetchManager:(CTContentFetchManager *)manager didReceiveResponse:(NSData *)data {
    [self.receivedResponses addObject:data ?: [NSData data]];
    
    if (self.onResponseReceived) {
        self.onResponseReceived(data);
    }
}

- (void)contentFetchManager:(CTContentFetchManager *)manager
            addMetadataToEvent:(NSMutableDictionary *)event
                         ofType:(CleverTapEventType)eventType {
    // Add some test metadata
    event[@"test_metadata"] = @"added_by_delegate";
    event[@"event_type"] = @(eventType);
    
    [self.metadataEvents addObject:[event copy]];
    
    if (self.onMetadataAdded) {
        self.onMetadataAdded([event copy]);
    }
}

- (void)contentFetchManager:(CTContentFetchManager *)manager didFailWithError:(NSError *)error {
    [self.receivedErrors addObject:error];
    
    if (self.onErrorReceived) {
        self.onErrorReceived(error);
    }
}

@end
