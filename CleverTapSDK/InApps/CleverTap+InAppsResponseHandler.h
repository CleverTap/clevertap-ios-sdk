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

/// Equivalent to `handleInAppResponse:source:` with `CTResponseSourceApp`.
- (void)handleInAppResponse:(NSDictionary *)jsonResp;

/*!
 Handle the in-app keys of a response.

 @param jsonResp The JSON response dictionary
 @param source Which endpoint the response came from. The `/content` response passes through
 this same handler, and some keys must be treated differently depending on the origin.
 */
- (void)handleInAppResponse:(NSDictionary *)jsonResp source:(CTResponseSource)source;

- (void)triggerFetchInApps:(BOOL)success;

@end

#endif /* CleverTap_InAppsResponseHandler_h */
