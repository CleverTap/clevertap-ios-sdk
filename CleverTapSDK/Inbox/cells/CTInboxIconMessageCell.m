#import "CTInboxIconMessageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CTConstants.h"
#import "CTInAppUtils.h"

@implementation CTInboxIconMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOnMessageTapGesture:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapGesture];
    self.readView.layer.cornerRadius = 5;
    self.readView.layer.masksToBounds = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.cellImageView sd_cancelCurrentAnimationImagesLoad];
    [self.cellIcon sd_cancelCurrentAnimationImagesLoad];
    self.cellImageView.image = nil;
    self.cellIcon.image = nil;
}

- (void)doLayoutForMessage:(CleverTapInboxMessage *)message {
    CleverTapInboxMessageContent *content = message.content[0];
    if (content.mediaUrl == nil || [content.mediaUrl isEqual: @""]) {
        self.imageViewHeightContraint.priority = 999;
        self.imageViewLRatioContraint.priority = 750;
        self.imageViewPRatioContraint.priority = 750;
    } else if ([message.orientation.uppercaseString isEqualToString:@"P"] || message.orientation == nil ) {
        self.imageViewPRatioContraint.priority = 999;
        self.imageViewLRatioContraint.priority = 750;
        self.imageViewHeightContraint.priority = 750;
    } else {
        self.imageViewHeightContraint.priority = 750;
        self.imageViewPRatioContraint.priority = 750;
        self.imageViewLRatioContraint.priority = 999;
    }
    // set content mode for media
    if (content.mediaIsGif) {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    self.cellImageView.clipsToBounds = YES;
    self.titleLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.titleColor];
    self.bodyLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.messageColor];
    self.dateLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.titleColor];
    if (content.actionHasLinks) {
        self.actionView.hidden = NO;
        self.actionViewHeightContraint.constant = 45;
        self.actionView.delegate = self;
    } else {
        self.actionView.hidden = YES;
        self.actionViewHeightContraint.constant = 0;
    }
    self.actionView.firstButton.hidden = YES;
    self.actionView.secondButton.hidden = YES;
    self.actionView.thirdButton.hidden = YES;
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (void)setupMessage:(CleverTapInboxMessage *)message {
    self.message = message;
     if (!message.content || message.content.count < 0) {
         self.titleLabel.text = nil;
         self.bodyLabel.text = nil;
         self.dateLabel.text = nil;
         self.cellImageView.image = nil;
         self.cellIcon = nil;
         return;
     }
    CleverTapInboxMessageContent *content = message.content[0];
    if (message.isRead) {
        self.readView.hidden = YES;
        self.readViewWidthContraint.constant = 0;
    } else {
        self.readView.hidden = NO;
        self.readViewWidthContraint.constant = 16;
    }
    self.titleLabel.text = content.title;
    self.bodyLabel.text = content.message;
    self.dateLabel.text = message.relativeDate;

    [self setupInboxMessageActions:content];

    // set content mode for media
    if (content.mediaIsGif) {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    if (content.mediaUrl && !content.mediaIsVideo && !content.mediaIsAudio) {
        self.cellImageView.hidden = NO;
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                              placeholderImage:nil
                                       options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    } else if (content.mediaIsVideo || content.mediaIsAudio) {
        [self setupMediaPlayer];
    }
    
    if (content.iconUrl) {
        [self.cellIcon sd_setImageWithURL:[NSURL URLWithString:content.iconUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    }
}
@end
