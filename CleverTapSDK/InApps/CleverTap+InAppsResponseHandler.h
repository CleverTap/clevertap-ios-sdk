//
//  CleverTap+InAppsResponseHandler.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 9.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CleverTap_InAppsResponseHandler_h
#define CleverTap_InAppsResponseHandler_h

@interface CleverTap(InAppsResponseHandler)

- (void)handleInAppResponse:(NSDictionary *)jsonResp;
- (void)triggerFetchInApps:(BOOL)success;

@end

#endif /* CleverTap_InAppsResponseHandler_h */
