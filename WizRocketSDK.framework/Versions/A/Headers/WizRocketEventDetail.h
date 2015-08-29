//
//  WizRocketEventDetail.h
//  WizRocketSDK
//
//  Created by Jude Pereira on 06/07/2015.
//  Copyright (c) 2015 WizRocket. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WizRocketEventDetail : NSObject

@property (nonatomic, strong) NSString *eventName;
@property (nonatomic) NSTimeInterval firstTime;
@property (nonatomic) NSTimeInterval lastTime;
@property (nonatomic) int count;

@end
