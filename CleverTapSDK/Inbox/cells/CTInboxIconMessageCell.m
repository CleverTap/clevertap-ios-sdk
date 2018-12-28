#import "CTInboxIconMessageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CTConstants.h"
#import "CTInAppUtils.h"

@implementation CTInboxIconMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.readView.layer.cornerRadius = 5;
    self.readView.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
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
    
    if (content.links.count == 0) {
        _actionView.hidden = YES;
        _actionViewHeightContraint.constant = 0;
    } else {
        _actionView.hidden = NO;
        _actionViewHeightContraint.constant = 44;
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
    } else {
        self.readView.hidden = NO;
    }
    
    self.titleLabel.text = content.title;
    self.bodyLabel.text = content.message;
    [self setupInboxMessageActions:content];
    
    if (content.mediaUrl && !content.mediaIsVideo) {
        [self.cellIcon sd_setImageWithURL:[NSURL URLWithString:content.iconUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
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
                                             toItem:self attribute:NSLayoutAttributeWidth
                                         multiplier:1.0 constant:0] setActive:YES];
           
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            
        } else if (content.links.count == 2) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self attribute:NSLayoutAttributeWidth
                                         multiplier:0.5 constant:0] setActive:YES];
            
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton forText:content.links[1] withIndex:1];
            
        } else if (content.links.count > 2) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self attribute:NSLayoutAttributeWidth
                                         multiplier:0.33 constant:0] setActive:YES];
           
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            _actionView.thirdButton = [_actionView setupViewForButton:_actionView.thirdButton forText:content.links[1] withIndex:1];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton forText:content.links[2] withIndex:2];
        }
    }
}

- (void)handleInboxNotificationFromIndex:(UIButton *)sender {
    
    NSInteger index = sender.tag;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:(int)index] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}

@end
