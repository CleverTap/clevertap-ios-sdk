//
//  CTTemplatePresenterMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 10.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTTemplatePresenterMock.h"

@implementation CTTemplatePresenterMock

- (void)onCloseClicked:(CTTemplateContext *)context {
    self.onCloseInvocationsCount++;
    self.onCloseContext = context;
}

- (void)onPresent:(CTTemplateContext *)context {
    self.onPresentInvocationsCount++;
    self.onPresentContext = context;
}

@end
