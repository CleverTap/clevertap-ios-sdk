//
//  ContentMerger.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 17/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContentMerger : NSObject
+ (id)mergeWithVars:(id)vars diff:(id)diff;
@end
