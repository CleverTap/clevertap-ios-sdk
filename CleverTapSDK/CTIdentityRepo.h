//
//  CTIdentityRepo.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CTIdentityRepo <NSObject>

- (NSArray*)getIdentities;
- (BOOL)isIdentity: (NSString*)key;
@end
