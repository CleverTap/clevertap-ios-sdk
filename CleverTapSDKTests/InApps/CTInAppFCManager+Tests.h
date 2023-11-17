//
//  CTInAppFCManager+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 17.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CTInAppFCManager_Tests_h
#define CTInAppFCManager_Tests_h

@interface CTInAppFCManager(Tests)
@property (atomic, strong) CTImpressionManager *impressionManager;
- (int)globalSessionMax;
- (int)shownThisSession;
- (BOOL)hasSessionCapacityMaxedOut:(CTInAppNotification *)inapp;
@end

#endif /* CTInAppFCManager_Tests_h */
