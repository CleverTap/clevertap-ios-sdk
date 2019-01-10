#import "CTInboxIconMessageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CTConstants.h"
#import "CTInAppUtils.h"

@implementation CTInboxIconMessageCell

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
    // Initialization code
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOnMessageTapGesture:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapGesture];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)layoutNotification:(CleverTapInboxMessage *)message {
    
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
        _actionView.hidden = NO;
        _actionViewHeightContraint.constant = 45;
    } else {
        _actionView.hidden = YES;
        _actionViewHeightContraint.constant = 0;
    }
    
    self.actionView.firstButton.hidden = YES;
    self.actionView.secondButton.hidden = YES;
    self.actionView.thirdButton.hidden = YES;
    
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (void)setupIconMessage:(CleverTapInboxMessage *)message {
    
    self.message = message;
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
    if (content.actionHasLinks) {
        [self setupInboxMessageActions:content];
    }
    
    if (content.mediaUrl && !content.mediaIsVideo) {
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    }
    
    if (content.iconUrl) {
        [self.cellIcon sd_setImageWithURL:[NSURL URLWithString:content.iconUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    }
}

- (void)setupInboxMessageActions:(CleverTapInboxMessageContent *)content {
    
    _actionView.hidden = NO;
    if (content.links && content.links.count > 0) {
        _actionView.firstButton.hidden = YES;
        _actionView.secondButton.hidden = YES;
        _actionView.thirdButton.hidden = YES;
        
        if (content.links.count == 1) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self.containerView attribute:NSLayoutAttributeWidth
                                         multiplier:1.0 constant:0] setActive:YES];
           
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            
        } else if (content.links.count == 2) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self.containerView attribute:NSLayoutAttributeWidth
                                         multiplier:0.5 constant:0] setActive:YES];
            
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton forText:content.links[1] withIndex:1];
            
        } else if (content.links.count > 2) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self.containerView attribute:NSLayoutAttributeWidth
                                         multiplier:0.33 constant:0] setActive:YES];
           
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            _actionView.thirdButton = [_actionView setupViewForButton:_actionView.thirdButton forText:content.links[1] withIndex:1];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton forText:content.links[2] withIndex:2];
        }
    }
}

- (void)handleInboxNotificationAtIndex:(int)index {
    int i = index;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:0] forKey:@"index"];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"buttonIndex"];   
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}
- (void)handleOnMessageTapGesture:(UITapGestureRecognizer *)sender{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:0] forKey:@"index"];
    [userInfo setObject:[NSNumber numberWithInt:-1] forKey:@"buttonIndex"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}


@end
