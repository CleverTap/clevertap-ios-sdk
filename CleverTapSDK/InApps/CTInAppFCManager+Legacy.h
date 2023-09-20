//
//  CTInAppFCManager+Legacy.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 19.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTInAppFCManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface CTInAppFCManager(Legacy)

- (void)migratePreferenceKeys;

@end

NS_ASSUME_NONNULL_END
