
#import "CTVideoThumbnailGenerator.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <SDWebImage/SDImageCache.h>

@interface CTVideoThumbnailGenerator ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItemVideoOutput *videoOutput;
@property (nonatomic, strong) NSString *sourceUrl;
@property (nonatomic, copy) void (^onImageReadyBlock)(UIImage *, NSString *);

@end

@implementation CTVideoThumbnailGenerator

- (void)dealloc {
    [self cleanup];
}

- (void)cleanup {
    if (self.player != nil) {
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player pause];
        [self.player.currentItem removeOutput:self.videoOutput];
        self.videoOutput = nil;
        [self.player.currentItem.asset cancelLoading];
        [self.player cancelPendingPrerolls];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;
        self.onImageReadyBlock = nil;
    }
}

- (void)generateImageFromUrl:(NSString *)videoURL withCompletionBlock:(void (^)(UIImage *image, NSString *sourceUrl))completion {
    self.sourceUrl = videoURL;
    NSURL *url = [NSURL URLWithString:videoURL];
    SDImageCache *cache = [SDImageCache sharedImageCache];
    // ok to load sync as it just in mem
    UIImage *image = [cache imageFromCacheForKey:videoURL];
    if (image) {
        if (completion) {
           completion(image, videoURL);
        }
    } else {
        void (^onImageReadyBlock)(UIImage *, NSString *sourceUrl) = ^(UIImage *thumbnail, NSString *sourceUrl) {
            if (thumbnail) {
                [cache storeImage:thumbnail forKey:videoURL toDisk:NO completion:nil];
            }
            if (completion) {
              completion(thumbnail, sourceUrl);
            }
        };
        if ([videoURL containsString:@"m3u8"]) {
            [self _generateImageFromStream:url withCompletionBlock: onImageReadyBlock];
        } else {
            [self _generateImage:url withCompletionBlock: onImageReadyBlock];
        }
    }
    return;
}

- (void)_generateImage:(NSURL *)url withCompletionBlock:(void (^)(UIImage *image, NSString *sourceUrl))completion {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *keys = @[@"playable", @"tracks", @"duration"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        if ([[url absoluteString] isEqualToString: [[asset URL] absoluteString]]) {
            CMTime duration = [asset duration];
            CMTime snapshot = CMTimeMake(0, duration.timescale);
            AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            generator.appliesPreferredTrackTransform = YES;
            CGImageRef imageRef = [generator copyCGImageAtTime:snapshot
                                                    actualTime:nil
                                                         error:nil];
            UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            completion(thumbnail, self.sourceUrl);
        }
    }];
}

- (void)_generateImageFromStream:(NSURL *)streamURL withCompletionBlock:(void (^)(UIImage *image, NSString *sourceUrl))completion {
    [self cleanup];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:streamURL options:nil];
    NSArray *keys = @[@"playable", @"tracks", @"duration"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        if ([[streamURL absoluteString] isEqualToString:[[asset URL] absoluteString]]) {
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            playerItem.preferredPeakBitRate = 1000000;
            NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
            self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
            [playerItem addOutput:self.videoOutput];
            self.player = [AVPlayer playerWithPlayerItem:playerItem];
            [self.player.currentItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
            self.onImageReadyBlock = completion;
            int32_t timeScale = self.player.currentItem.asset.duration.timescale;
            CMTime targetTime = CMTimeMakeWithSeconds(0, timeScale);
            if (CMTIME_IS_VALID(targetTime)) {
                [self.player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            }
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.player.currentItem.status == AVPlayerStatusReadyToPlay) {
        CMTime currentTime = self.player.currentItem.currentTime;
        CVPixelBufferRef buffer = [self.videoOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:buffer];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer))];
        CVPixelBufferRelease(buffer);
        UIImage *image = [UIImage imageWithCGImage:videoImage];
        CGImageRelease(videoImage);
        if (self.onImageReadyBlock) {
            self.onImageReadyBlock(image, self.sourceUrl);
        }
    }
    [self cleanup];
}

@end
