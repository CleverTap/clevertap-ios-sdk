//
//  CTTemplatePresenterMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 10.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplatePresenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTTemplatePresenterMock : NSObject<CTTemplatePresenter>

@property (nonatomic) int onCloseInvocationsCount;
@property (nonatomic) CTTemplateContext *onCloseContext;

@property (nonatomic) int onPresentInvocationsCount;
@property (nonatomic) CTTemplateContext *onPresentContext;

@end

NS_ASSUME_NONNULL_END
