//
//  ACThumbnailGenerator.m
//
//  Created by Alejandro Cotilla on 11/24/16.
//  Copyright © 2016 Alejandro Cotilla. All rights reserved.
//

#import "CThumbnailGenerator.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CThumbnailGenerator ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItemVideoOutput *videoOutput;

@property (nonatomic, strong) NSURL *streamURL;

@property (nonatomic, assign) double preferredBitRate;

@property (nonatomic, copy) void (^onImageReadyListener)(UIImage *);

@end

@implementation CThumbnailGenerator

#pragma mark - Destruction -

- (void)dealloc
{
    [self clear];
}

#pragma mark - Initialization -

- (id)initWithPreferredBitRate:(double)preferredBitRate
{
    self = [super init];
    
    self.preferredBitRate = preferredBitRate;
    
    return self;
}

#pragma mark - Processing -

- (void)loadImageFrom:(NSURL *)streamURL position:(int)position withCompletionBlock:(void (^)(UIImage *image))completion
{
    [self clear];
    
    self.streamURL = streamURL;
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:streamURL options:nil];
    NSArray *keys = @[@"playable", @"tracks", @"duration"];

    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{

        // check if the loaded asset is still the one in queue
        if ([[self.streamURL absoluteString] isEqualToString:[[asset URL] absoluteString]])
        {
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            
            if (self.preferredBitRate > 0)
            {
                playerItem.preferredPeakBitRate = self.preferredBitRate;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                
                NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
                self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
                [playerItem addOutput:self.videoOutput];
                
                self.player = [AVPlayer playerWithPlayerItem:playerItem];
                
                [self.player.currentItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
                
                self.onImageReadyListener = completion;
                
                // seek to target position
                if (position > 0)
                {
                    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
                    
                    CMTime targetTime = CMTimeMakeWithSeconds(position, timeScale);
                    if (CMTIME_IS_VALID(targetTime))
                    {
                        [self.player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
                    }
                }
                
            });
        }
        
    }];
}

- (void)clear
{
    if (self.player != nil)
    {
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player pause];
        [self.player.currentItem removeOutput:self.videoOutput];
        self.videoOutput = nil;
        [self.player.currentItem.asset cancelLoading];
        [self.player cancelPendingPrerolls];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;
        
        self.onImageReadyListener = NULL;
    }
}

#pragma mark - Observers -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.player.currentItem.status == AVPlayerStatusReadyToPlay)
    {
        CMTime currentTime = self.player.currentItem.currentTime;
        CVPixelBufferRef buffer = [self.videoOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:buffer];
        
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer))];
        
        UIImage *image = [UIImage imageWithCGImage:videoImage];
        
        self.onImageReadyListener(image);
    }
    else
    {
        // @TODO: handle error
    }
    
    [self clear];
}

@end
