//
//  CTRequest.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 09/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

typedef void (^CTNetworkResponseBlock)(NSData * _Nullable data, NSURLResponse *_Nullable response);
typedef void (^CTNetworkResponseErrorBlock)(NSError * _Nullable error);

@interface CTRequest : NSObject

- (CTRequest *_Nonnull)initWithHttpMethod:(NSString *_Nonnull)httpMethod config:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url;

- (void)onResponse:(CTNetworkResponseBlock _Nonnull)responseBlock;
- (void)onError:(CTNetworkResponseErrorBlock _Nonnull)errorBlock;

@property (nonatomic, strong, nonnull) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong, nonnull) CTNetworkResponseBlock responseBlock;
@property (nonatomic, strong, nullable) CTNetworkResponseErrorBlock errorBlock;

@end

