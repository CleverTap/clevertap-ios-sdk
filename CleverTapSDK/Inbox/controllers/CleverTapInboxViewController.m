#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#import "CTInboxMessageCell.h"
#import "CTInboxSingleMediaCell.h"
#import "CTInboxMultiMediaCell.h"
#import "CTConstants.h"
#import "CTInAppResources.h"
#import <SDWebImage/UIImageView+WebCache.h>

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#if __has_include(<SDWebImage/FLAnimatedImage.h>)
#import <SDWebImage/FLAnimatedImage.h>
#endif

#if __has_include(<SDWebImage/FLAnimatedImageView.h>)
#import <SDWebImage/FLAnimatedImageView.h>
#endif

NSString* const kCellMessageIdentifier = @"CTInboxMessageCell";
NSString* const kCellMediaIdentifier = @"CTInboxMediaCell";
NSString* const kCellMultiMediaIdentifier = @"CTInboxMultiMediaCell";

NSString* const kSingleMessage = @"single-message";
NSString* const kSingleMedia = @"single-media";
NSString* const kMultiMedia = @"multi-media";

static CGFloat kSegmentHeight = 32.0;
static CGFloat kToolbarHeight = 48.0;

@interface CleverTapInboxViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *messages;
@property (nonatomic, strong) CleverTapInboxStyleConfig *config;

@property (nonatomic, weak) id<CleverTapInboxViewControllerDelegate> delegate;
@property (nonatomic, weak) id<CleverTapInboxViewControllerAnalyticsDelegate> analyticsDelegate;

@end

@implementation CleverTapInboxViewController

- (instancetype)initWithMessages:(NSArray *)messages
                          config:(CleverTapInboxStyleConfig *)config
                        delegate:(id<CleverTapInboxViewControllerDelegate>)delegate
               analyticsDelegate:(id<CleverTapInboxViewControllerAnalyticsDelegate>)analyticsDelegate {
    self = [self initWithNibName:NSStringFromClass([CleverTapInboxViewController class]) bundle:[NSBundle bundleForClass:CleverTapInboxViewController.class]];
    if (self) {
        _config = [config copy];
        _delegate = delegate;
        _analyticsDelegate = analyticsDelegate;
        _messages = messages;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_config && _config.backgroundColor) {
        self.view.backgroundColor = _config.backgroundColor;
    }
    
    [self setupLayout];
    [self registerNibs];
}

#pragma mark - setup layout

- (void)setupLayout {
    
    self.navigationController.navigationBar.topItem.title = @"Notifications";

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 2.0)];

//    self.edgesForExtendedLayout = UIRectEdgeNone;
//    self.extendedLayoutIncludesOpaqueBars = YES;
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self segmentControl];
}

- (void)segmentControl {
    
    // set segment control
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"All", @"Offers", @"Promotions", nil]];
    segmentedControl.frame = CGRectMake(20, 12, self.tableView.frame.size.width - 230, kSegmentHeight);
    
    CGFloat topOffset = self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, topOffset, self.navigationController.navigationBar.frame.size.width, kToolbarHeight)];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    toolbar.backgroundColor = [UIColor whiteColor];
    toolbar.clipsToBounds = YES;
    toolbar.translucent = NO;
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView: segmentedControl];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace                                                                                  target: nil  action: nil];
    [toolbar setItems:@[flexibleItem, segmentedControlItem, flexibleItem] animated:YES];
    [self.navigationController.view addSubview: toolbar];
    segmentedControl.selectedSegmentIndex = 0;
    
    // set tableview frame
    self.tableView.contentInset = UIEdgeInsetsMake(topOffset - 14, 0, 0, 0);
    CGRect currentFrame = self.tableView.frame;
    [self.tableView setFrame: CGRectMake(currentFrame.origin.x,
                                         currentFrame.origin.y,
                                         currentFrame.size.width,
                                         currentFrame.size.height + 44)];
}

- (void)registerNibs {
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxMessageCell.class]] forCellReuseIdentifier:kCellMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxSingleMediaCell class]) bundle:[NSBundle bundleForClass:CTInboxMessageCell.class]] forCellReuseIdentifier:kCellMediaIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxMultiMediaCell class]) bundle:[NSBundle bundleForClass:CTInboxMessageCell.class]] forCellReuseIdentifier:kCellMultiMediaIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.messages) {
        return 0;
    }
    return [self.messages count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.messages) {
        return 0;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    CleverTapInboxMessage *message = [self.messages objectAtIndex:indexPath.section];
    [self _notifyMessageViewed:message];

    if ([message.type isEqualToString:kSingleMedia]) {
        
        CTInboxSingleMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellMediaIdentifier forIndexPath:indexPath];
        [self _notifyMessageViewed:message];
        
        cell.titleLabel.text = message.title;
        cell.bodyLabel.text = message.body;
        [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:message.imageUrl]
                              placeholderImage:[self getPlaceHolderImage]
                                       options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];

        if([message.media[@"content_type"]  isEqual: @"video"]) {
            
            cell.cellImageView.hidden = YES;
            cell.avPlayerContainerView.hidden = NO;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            cell.avPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:message.imageUrl]];
            AVPlayerViewController *playerController = [AVPlayerViewController new];
            playerController.player = cell.avPlayer;
            playerController.showsPlaybackControls = YES;
            playerController.view.backgroundColor = [UIColor clearColor];
            [self addChildViewController:playerController];
            [cell.avPlayerContainerView addSubview:playerController.view];

            playerController.view.translatesAutoresizingMaskIntoConstraints = NO;
            
            [[NSLayoutConstraint constraintWithItem:playerController.view
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:cell.avPlayerContainerView attribute:NSLayoutAttributeWidth
                                         multiplier:1 constant:0] setActive:YES];
            [[NSLayoutConstraint constraintWithItem:playerController.view
                                          attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                             toItem:cell.avPlayerContainerView attribute:NSLayoutAttributeHeight
                                         multiplier:1 constant:0] setActive:YES];
            [[NSLayoutConstraint constraintWithItem:playerController.view
                                          attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                             toItem:cell.avPlayerContainerView
                                          attribute:NSLayoutAttributeLeading
                                         multiplier:1 constant:0] setActive:YES];
            [[NSLayoutConstraint constraintWithItem:playerController.view
                                          attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                             toItem:cell.avPlayerContainerView attribute:NSLayoutAttributeTrailing
                                         multiplier:1 constant:0] setActive:YES];
            [[NSLayoutConstraint constraintWithItem:playerController.view
                                          attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                             toItem:cell.avPlayerContainerView attribute:NSLayoutAttributeCenterY
                                         multiplier:1 constant:0] setActive:YES];
            
            [playerController didMoveToParentViewController:self];
            
        }
        
        if (_config && _config.messageTitleColor) {
            cell.textLabel.textColor = _config.messageTitleColor;
        }
        if (_config && _config.cellBackgroundColor) {
            cell.contentView.backgroundColor = _config.cellBackgroundColor;
        }
        if (_config && _config.contentBackgroundColor) {
            cell.containerView.backgroundColor = _config.contentBackgroundColor;
        }
        if (_config && _config.contentBorderColor) {
            cell.containerView.layer.borderColor = _config.contentBorderColor.CGColor;
        }
        
        return cell;

    } else if ([message.type isEqualToString:kMultiMedia]) {
        
        CTInboxMultiMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellMultiMediaIdentifier forIndexPath:indexPath];
        cell.containerView.translatesAutoresizingMaskIntoConstraints = NO;
       
        if ([message.media[@"orientation"] isEqualToString:@"portrait"]) {
            [[NSLayoutConstraint constraintWithItem:cell.containerView
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:cell.containerView
                                          attribute:NSLayoutAttributeWidth
                                         multiplier:0.72 constant:0] setActive:YES];

        } else {
            [[NSLayoutConstraint constraintWithItem:cell.containerView
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:cell.containerView
                                          attribute:NSLayoutAttributeWidth
                                         multiplier:0.72 constant:0] setActive:YES];
        }
        [cell layoutIfNeeded];
        [cell layoutSubviews];
        [cell setupSwipeView:message];
        return cell;
    
    } else if ([message.type isEqualToString:kSingleMessage]) {
        
        CTInboxMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellMessageIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = message.title;
        cell.bodyLabel.text = message.body;
        
        if (_config && _config.messageTitleColor) {
            cell.textLabel.textColor = _config.messageTitleColor;
        }
        if (_config && _config.cellBackgroundColor) {
            cell.contentView.backgroundColor = _config.cellBackgroundColor;
        }
        if (_config && _config.contentBackgroundColor) {
            cell.containerView.backgroundColor = _config.cellBackgroundColor;
        }
        if (_config && _config.contentBorderColor) {
            cell.containerView.layer.borderColor = _config.contentBorderColor.CGColor;
        }
        
        return cell;
        
    } else {
        
        CTInboxMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellMessageIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = message.title;
        cell.bodyLabel.text = message.body;
        return cell;
        
    }
}
    
- (UIImage *)getPlaceHolderImage {
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"placeholder" ofType:@"png"];
    return [UIImage imageWithContentsOfFile:imagePath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CleverTapInboxMessage *message = [self.messages objectAtIndex:indexPath.section];
    CleverTapLogStaticDebug(@"%@: message selected: %@", self, message);
    [self _notifyMessageSelected:message];    
}

- (void)_notifyMessageViewed:(CleverTapInboxMessage *)message {
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidShow:)]) {
        [self.analyticsDelegate messageDidShow:message];
    }
}

- (void)_notifyMessageSelected:(CleverTapInboxMessage *)message {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageDidSelect:)]) {
        [self.delegate messageDidSelect:message];
    }
    
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidSelect:)]) {
        [self.analyticsDelegate messageDidSelect:message];
    }
}
@end
