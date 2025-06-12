//
//  CTProfileBuilder+Tests.h
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/06/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTProfileBuilder.h"

@interface CTProfileBuilder (Tests)
+ (id)getJSONKey:(id)jsonObject
          forKey:(NSString *)key
     withDefault:(id)defValue;
@end
