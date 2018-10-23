//
//  CTSlider.m
//  CleverTapSDK
//
//  Created by Aditi Agrawal on 17/08/18.
//  Copyright © 2018 Peter Wilkniss. All rights reserved.
//

#import "CTSlider.h"

static const float kSliderHeight = 6.0;

@implementation CTSlider

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect rect = CGRectMake(bounds.origin.x, bounds.size.height/2 - 3, bounds.size.width, kSliderHeight);
    return rect;
}

@end
