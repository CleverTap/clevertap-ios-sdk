#import "CTInboxIconMessageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation CTInboxIconMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
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

- (void)setupIconMessage:(CTInboxNotificationContentItem *)message {
    
    if (message.mediaUrl == nil || [message.mediaUrl isEqual: @""]) {
        self.imageViewHeightContraint.priority = 999;
        self.imageViewRatioContraint.priority = 750;
    } else {
        self.imageViewRatioContraint.priority = 999;
        self.imageViewHeightContraint.priority = 750;
    }
    
    [self.cellIcon sd_setImageWithURL:[NSURL URLWithString:message.iconUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    
    [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:message.mediaUrl] placeholderImage: nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];

    
    self.titleLabel.text = message.title;
    self.bodyLabel.text = message.message;
    
    if (message.links && message.links.count > 0) {
        _actionView.firstButton.hidden = YES;
        _actionView.secondButton.hidden = YES;
        _actionView.thirdButton.hidden = YES;
        
        _actionView.thirdButton = [_actionView setupViewForButton:_actionView.thirdButton withData:message withIndex:0];
        
        if (message.links.count > 1) {
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton withData:message withIndex:1];
            [[NSLayoutConstraint constraintWithItem:self.actionView.secondButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                         multiplier:1 constant:0] setActive:YES];
        } else if (message.links.count > 2) {
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton withData:message withIndex:1];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton withData:message withIndex:2];

        }
    }
}

@end
