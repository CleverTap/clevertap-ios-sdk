//
//  CTRequestFactory.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 09/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTRequest.h"
#import "CleverTapInstanceConfig.h"

@interface CTRequestFactory : NSObject

+ (CTRequest *_Nonnull)helloRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config;
+ (CTRequest *_Nonnull)eventRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url;
+ (CTRequest *_Nonnull)syncVarsRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url;
@end


