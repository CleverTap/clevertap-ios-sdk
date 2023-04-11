//
//  CTVariables+Tests.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 29.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTVariables.h"
#import "CTVarCacheMock.h"

@interface CTVariables (Tests)

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo: (CTDeviceInfo *)deviceInfo varCache: (CTVarCacheMock *)varCache;
- (void)triggerVariablesChanged;
@end
