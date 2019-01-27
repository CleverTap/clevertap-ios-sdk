//
//  ACThumbnailGenerator.h
//
//  Created by Alejandro Cotilla on 11/24/16.
//  Copyright © 2016 Alejandro Cotilla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CThumbnailGenerator : NSObject

// @param preferredBitRate force video bit rate (can be use to cap video quality and improve performance). Pass 0 to use default bit rate.
- (id)initWithPreferredBitRate:(double)preferredBitRate;

- (void)loadImageFrom:(NSURL *)streamURL position:(int)position withCompletionBlock:(void (^)(UIImage *image))completion;

@end
