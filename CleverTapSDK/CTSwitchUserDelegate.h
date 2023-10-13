//
//  CTSwitchUserDelegate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 6.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CTSwitchUserDelegate_h
#define CTSwitchUserDelegate_h

@protocol CTSwitchUserDelegate <NSObject>

- (void)deviceIdDidChange:(NSString *)newDeviceId;

@end

#endif /* CTSwitchUserDelegate_h */
