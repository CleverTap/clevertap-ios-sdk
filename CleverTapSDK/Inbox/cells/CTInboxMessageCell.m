#import "CTInboxMessageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat kBorderWidth = 0.0;
static CGFloat kCornerRadius = 0.0;

@implementation CTInboxMessageCell

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // no-op for now
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.containerView.layer.cornerRadius = kCornerRadius;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:1.0].CGColor;
    self.containerView.layer.borderWidth = kBorderWidth;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.cellImageView sd_cancelCurrentAnimationImagesLoad];
}

@end
