#import <SDWebImage/UIImageView+WebCache.h>
#import "CTCarouselImageView.h"

static const float kCaptionHeight = 20.f;
static const float kSubCaptionHeight = 54.f;
static const float kSubCaptionTopPadding = 7.f;
static const float kBottomPadding = 10.f;
static const float kCaptionLeftPadding = 30.f;
static const float kCaptionTopPadding = 30.f;
static const float kImageBorderWidth = 1.f;
static const float kImageLayerBorderWidth = 0.4f;
static float captionHeight = 0.f;

@interface CTCarouselImageView ()

@property (nonatomic, strong, nullable, readwrite) NSString *actionUrl;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSString *subcaption;
@property (nonatomic, strong) NSString *imageUrl;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UILabel *subcaptionLabel;

@end

@implementation CTCarouselImageView

+ (CGFloat)captionHeight {
    if (captionHeight <= 0) {
        captionHeight = kCaptionHeight+kSubCaptionHeight+kBottomPadding+kCaptionTopPadding;
    }
    return captionHeight;
}

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                               caption:(NSString * _Nullable)caption
                            subcaption:(NSString * _Nullable)subcaption
                              imageUrl:(NSString * _Nonnull)imageUrl
                             actionUrl:(NSString * _Nullable)actionUrl {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.imageUrl = imageUrl;
        self.caption = caption;
        self.subcaption = subcaption;
        self.actionUrl = actionUrl;
        [self setup];
    }
    return self;
}

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                              imageUrl:(NSString * _Nonnull)imageUrl
                             actionUrl:(NSString * _Nullable)actionUrl {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.imageUrl = imageUrl;
        self.actionUrl = actionUrl;
        [self setupImageOnly];
    }
    return self;
}

- (void)setupImageOnly {
    
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = self.frame.size.height;
    CGSize imageViewSize = CGSizeMake(viewWidth, viewHeight);
    
    // gyrations to draw a corresponding gray border below the image
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f-kImageBorderWidth, 0.f-kImageBorderWidth, imageViewSize.width + (kImageBorderWidth*2), imageViewSize.height)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    self.imageView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.imageView.layer.borderWidth = kImageLayerBorderWidth;
    self.imageView.backgroundColor = [UIColor redColor];
    self.imageView.layer.masksToBounds = YES;
    self.imageView.clipsToBounds = YES;
    [self addSubview:self.imageView];
    [self loadImage];
}

- (void)setup {
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = self.frame.size.height;
    CGSize imageViewSize = CGSizeMake(viewWidth, viewHeight-([[self class] captionHeight]));
    
    // gyrations to draw a corresponding gray border below the image
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f-kImageBorderWidth, 0.f-kImageBorderWidth, imageViewSize.width + (kImageBorderWidth*2), imageViewSize.height)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    self.imageView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.imageView.layer.borderWidth = kImageLayerBorderWidth;
    self.imageView.layer.masksToBounds = YES;
    [self addSubview:self.imageView];
    [self loadImage];
    
    self.captionLabel = [[UILabel alloc]initWithFrame:CGRectMake(kCaptionLeftPadding, kCaptionTopPadding + imageViewSize.height, viewWidth - kCaptionLeftPadding * 2, kCaptionHeight)];
    self.captionLabel.textAlignment = NSTextAlignmentLeft;
    self.captionLabel.adjustsFontSizeToFitWidth = NO;
    self.captionLabel.font = [UIFont boldSystemFontOfSize:15.f];
    self.captionLabel.textColor = [UIColor blackColor];
    self.captionLabel.text = self.caption;
    [self addSubview:self.captionLabel];
    
    self.subcaptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(kCaptionLeftPadding, imageViewSize.height + kCaptionHeight + kCaptionTopPadding + kSubCaptionTopPadding, viewWidth - kCaptionLeftPadding * 2, kSubCaptionHeight)];
    self.subcaptionLabel.numberOfLines = 3;
    self.subcaptionLabel.textAlignment = NSTextAlignmentLeft;
    self.subcaptionLabel.adjustsFontSizeToFitWidth = NO;
    self.subcaptionLabel.font = [UIFont systemFontOfSize:13.f];
    self.subcaptionLabel.textColor = [UIColor lightGrayColor];
    self.subcaptionLabel.text = self.subcaption;
    [self addSubview:self.subcaptionLabel];
}

- (UIImage *)getPlaceHolderImage {
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"placeholder" ofType:@"png"];
    return [UIImage imageWithContentsOfFile:imagePath];
}

- (void)loadImage {
    if (!self.imageUrl) return;
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.imageUrl]
                          placeholderImage:[self getPlaceHolderImage]
                                   options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    
}

@end
