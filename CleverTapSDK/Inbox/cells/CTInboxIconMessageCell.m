#import "CTInboxIconMessageCell.h"

@implementation CTInboxIconMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOnMessageTapGesture:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapGesture];
}

#if TARGET_OS_TV
- (void)setupTVLayout {
    [super setupTVLayout];

    // cellIcon — placed to the left of the titleLabel and bodyLabel.
    // We pin it to the leading edge of containerView and align with the text area.
    self.cellIcon = [[UIImageView alloc] init];
    self.cellIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.cellIcon.contentMode = UIViewContentModeScaleAspectFill;
    self.cellIcon.clipsToBounds = YES;
    self.cellIcon.layer.cornerRadius = 4;
    [self.containerView addSubview:self.cellIcon];

    // Default height = 28 (no icon), ratio 1:1
    self.cellIconHeightContraint = [self.cellIcon.heightAnchor constraintEqualToConstant:28];
    self.cellIconRatioContraint = [self.cellIcon.widthAnchor constraintEqualToAnchor:self.cellIcon.heightAnchor multiplier:1.0];
    self.cellIconRatioContraint.priority = 750;
    self.cellIconWidthContraint = [self.cellIcon.widthAnchor constraintEqualToConstant:0];
    self.cellIconWidthContraint.priority = 999;

    [NSLayoutConstraint activateConstraints:@[
        [self.cellIcon.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:10],
        [self.cellIcon.topAnchor constraintGreaterThanOrEqualToAnchor:self.mediaContainerView.bottomAnchor constant:10],
        [self.cellIcon.bottomAnchor constraintLessThanOrEqualToAnchor:self.actionView.topAnchor constant:-10],
        [self.cellIcon.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        self.cellIconHeightContraint,
        self.cellIconRatioContraint,
        self.cellIconWidthContraint,
    ]];

    // Shift titleLabel and bodyLabel to the right of cellIcon
    // (Remove and re-add the leading constraints on titleLabel and bodyLabel)
    for (NSLayoutConstraint *c in self.containerView.constraints) {
        if ((c.firstItem == self.titleLabel || c.firstItem == self.bodyLabel) &&
            c.firstAttribute == NSLayoutAttributeLeading) {
            c.active = NO;
        }
    }
    // Also check bodyTextContainer (superview of titleLabel/bodyLabel) constraints
    for (NSLayoutConstraint *c in self.titleLabel.superview.constraints) {
        if ((c.firstItem == self.titleLabel || c.firstItem == self.bodyLabel) &&
            c.firstAttribute == NSLayoutAttributeLeading) {
            c.active = NO;
        }
    }
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.cellIcon.trailingAnchor constant:10],
        [self.bodyLabel.leadingAnchor constraintEqualToAnchor:self.cellIcon.trailingAnchor constant:10],
    ]];

    // Add tap gesture (replaces awakeFromNib on tvOS)
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOnMessageTapGesture:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapGesture];
}
#endif

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.cellIcon sd_cancelCurrentImageLoad];
    [self.imageView sd_cancelCurrentImageLoad];
    self.cellImageView.image = nil;
    self.cellIcon.image = nil;
}

- (void)doLayoutForMessage:(CleverTapInboxMessage *)message {
    self.cellImageView.hidden = YES;
    self.avPlayerControlsView.alpha = 0.0;
    self.avPlayerContainerView.hidden = YES;
    self.activityIndicator.hidden = YES;
    CleverTapInboxMessageContent *content = message.content[0];
    if ([self mediaIsEmpty]) {
        self.imageViewHeightConstraint.priority = 999;
        self.imageViewLRatioConstraint.priority = 750;
        self.imageViewPRatioConstraint.priority = 750;
    } else if ([self orientationIsPortrait]) {
        self.imageViewPRatioConstraint.priority = 999;
        self.imageViewLRatioConstraint.priority = 750;
        self.imageViewHeightConstraint.priority = 750;
    } else {
        self.imageViewHeightConstraint.priority = 750;
        self.imageViewPRatioConstraint.priority = 750;
        self.imageViewLRatioConstraint.priority = 999;
    }
    
    // handle landscape
    if ([self deviceOrientationIsLandscape]) {
        if ([self mediaIsEmpty]) {
            self.imageViewWidthConstraint.priority = 999;
            self.dividerCenterXConstraint.priority = 750;
        } else {
            self.imageViewWidthConstraint.priority = 750;
            self.dividerCenterXConstraint.priority = 999;
        }
    }
    self.cellImageView.clipsToBounds = YES;
    self.cellIcon.clipsToBounds = YES;
    self.cellIcon.contentMode = UIViewContentModeScaleAspectFill;
    self.playButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.playButton.layer.borderWidth = 2.0;
    self.titleLabel.textColor = [CTUIUtils ct_colorWithHexString:content.titleColor];
    self.bodyLabel.textColor = [CTUIUtils ct_colorWithHexString:content.messageColor];
    self.dateLabel.textColor = [CTUIUtils ct_colorWithHexString:content.titleColor];
    [self configureActionView:!content.actionHasLinks];
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (void)setupMessage:(CleverTapInboxMessage *)message {
    if (!message.content || message.content.count < 0) {
        self.titleLabel.text = nil;
        self.bodyLabel.text = nil;
        self.dateLabel.text = nil;
        self.cellImageView.image = nil;
        self.cellIcon = nil;
        return;
    }
    CleverTapInboxMessageContent *content = message.content[0];
    self.cellImageView.image = nil;
    self.titleLabel.text = content.title;
    self.bodyLabel.text = content.message;
    self.dateLabel.text = message.relativeDate;
    self.readView.hidden = message.isRead;
    self.readViewWidthConstraint.constant = message.isRead ? 0 : 16;
    [self setupInboxMessageActions:content];
    self.cellImageView.contentMode = content.mediaIsGif ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    if (content.mediaUrl && !content.mediaIsVideo && !content.mediaIsAudio) {
        self.cellImageView.hidden = NO;
        self.cellImageView.alpha = 1.0;
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                              placeholderImage:[self orientationIsPortrait] ? [self getPortraitPlaceHolderImage] : [self getLandscapePlaceHolderImage]
                                       options:self.sdWebImageOptions context:self.sdWebImageContext];
        
        self.cellImageView.accessibilityLabel = content.mediaDescription ? content.mediaDescription : @"Message Image";
    } else if (content.mediaIsVideo || content.mediaIsAudio) {
        [self setupMediaPlayer];
        self.cellImageView.accessibilityLabel = content.mediaDescription ? content.mediaDescription : @"Message Media";
        self.avPlayerContainerView.accessibilityLabel = content.mediaDescription ? content.mediaDescription : @"Message Media";
    }
    
    if (content.iconUrl) {
        self.cellIconHeightContraint.constant = 75;
        [self.cellIcon sd_setImageWithURL:[NSURL URLWithString:content.iconUrl]
                         placeholderImage: [self getPortraitPlaceHolderImage] options:self.sdWebImageOptions context:self.sdWebImageContext];
        self.cellIconRatioContraint.priority = 999;
        self.cellIconWidthContraint.priority = 750;
        self.cellIcon.accessibilityLabel = content.iconDescription ? content.iconDescription : @"Icon Image";
    } else {
        self.cellIconHeightContraint.constant = 28;
        self.cellIconRatioContraint.priority = 750;
        self.cellIconWidthContraint.priority = 999;
    }
}

@end
