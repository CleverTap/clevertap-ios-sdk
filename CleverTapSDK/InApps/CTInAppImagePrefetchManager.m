#import "CTConstants.h"
#import "CTInAppImagePrefetchManager.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImagePrefetcher.h>

@interface CTInAppImagePrefetchManager()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) SDWebImagePrefetcher *sdWebImagePrefetcher;
@property (nonatomic, strong) SDImageCache *sdImageCache;

@end

@implementation CTInAppImagePrefetchManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        [self setup];
    }
    
    return self;
}

#pragma mark - Public

- (void)preloadClientSideInAppImages:(NSArray *)csInAppNotifs {
    if (csInAppNotifs.count == 0) return;

    NSArray<NSURL *> *mediaURLs = [self getImageURLs:csInAppNotifs];
    [self prefetchURLs:mediaURLs];
}

- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL {
    UIImage *image = [self.sdImageCache imageFromDiskCacheForKey:imageURL];
    if (image) return image;
    
    CleverTapLogInternal(self.config.logLevel, @"%@: Image not found in Disk Cache for URL: %@", self, imageURL);
    return nil;
}

- (void)clearDiskImages {
    [self.sdImageCache clearWithCacheType:SDImageCacheTypeDisk completion:^(){
        CleverTapLogInternal(self.config.logLevel, @"%@: Images in Disk cache are removed", self);
    }];
}

#pragma mark - Private

- (void)setup {
    self.sdWebImagePrefetcher = [SDWebImagePrefetcher sharedImagePrefetcher];
    self.sdImageCache = [SDImageCache sharedImageCache];
}

- (void)prefetchURLs:(NSArray<NSURL *> *)mediaURLs {
    if (mediaURLs.count == 0) return;

    [self.sdWebImagePrefetcher prefetchURLs:mediaURLs];
}

- (NSArray<NSURL *> *)getImageURLs:(NSArray *)csInAppNotifs {
    NSMutableArray<NSURL *> *mediaURLs = [NSMutableArray new];
    for (NSDictionary *jsonInApp in csInAppNotifs) {
        NSDictionary *media = (NSDictionary*) jsonInApp[@"media"];
        if (media) {
            NSString *contentType = media[@"content_type"];
            NSString *mediaUrl = media[@"url"];
            if (mediaUrl && mediaUrl.length > 0) {
                // Preload contentType with image/jpeg or image/gif
                if ([contentType hasPrefix:@"image"]) {
                    NSURL *imageURL = [NSURL URLWithString:mediaUrl];
                    [mediaURLs addObject:imageURL];
                }
            }
        }
    }
    return mediaURLs;
}

@end
