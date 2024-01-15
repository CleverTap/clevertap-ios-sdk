//
//  CTBatchSentDelegateHelper.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 1.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTBatchSentDelegateHelper.h"
#import "CTConstants.h"

@implementation CTBatchSentDelegateHelper

+ (BOOL)isBatchWithAppLaunched:(NSArray *)batchWithHeader {
    // Find the event with evtName == "App Launched"
    for (NSDictionary *event in batchWithHeader) {
        if ([event[CLTAP_EVENT_NAME] isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
            return YES;
        }
    }
    return NO;
}

@end
