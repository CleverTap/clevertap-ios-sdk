#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#import "CTInboxSimpleMessageCell.h"
#import "CTCarouselMessageCell.h"
#import "CTCarouselImageMessageCell.h"
#import "CTInboxIconMessageCell.h"
#import "CTConstants.h"
#import "CTInAppResources.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+GIF.h>

#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#if __has_include(<SDWebImage/FLAnimatedImage.h>)
#import <SDWebImage/FLAnimatedImage.h>
#endif

#if __has_include(<SDWebImage/FLAnimatedImageView.h>)
#import <SDWebImage/FLAnimatedImageView.h>
#endif

NSString* const kCellSimpleMessageIdentifier = @"CTInboxSimpleMessageCell";
NSString* const kCellCarouselMessageIdentifier = @"CTCarouselMessageCell";
NSString* const kCellCarouselImgMessageIdentifier = @"CTCarouselImageMessageCell";
NSString* const kCellIconMessageIdentifier = @"CTInboxIconMessageCell";

NSString* const kSimpleMessage = @"simple-message";
NSString* const kIconMessage = @"icon-message";
NSString* const kCarouselMessage = @"carousel";
NSString* const kCarouselImageMessage = @"carousel-image";

NSString* const kMultiMedia = @"multi-media";

static CGFloat kSegmentHeight = 32.0;
static CGFloat kToolbarHeight = 48.0;

@interface CleverTapInboxViewController () <UITableViewDelegate, UITableViewDataSource, CTInboxActionViewDelegate>

@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *messages;
@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *filterMessages;
@property (nonatomic, copy) NSArray *tags;

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIView *navigation;


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
    [self registerNibs];
    [self loadData];
    [self setupLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat topOffset = self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    _toolbar.frame  = CGRectMake(0, topOffset, self.navigationController.navigationBar.frame.size.width, kToolbarHeight);
//
//    NSLog(@"titleview %f:", self.navigationItem.titleView.frame.size.height);
//    _navigation.frame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, topOffset - 39);
}

- (void)registerNibs {
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxSimpleMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellSimpleMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTCarouselMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellCarouselMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTCarouselImageMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellCarouselImgMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxIconMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellIconMessageIdentifier];
}

- (void)loadData {
    self.filterMessages = self.messages;
    self.tags = [NSArray arrayWithObjects:@"All", @"Offers", @"Promotions", nil];
}

#pragma mark - setup layout

- (void)setupLayout {
    
    // set tableview
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.allowsSelection = NO;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
//    [self setupNavigationBar];
    [self setupSegmentController];
}

- (void)setupSegmentController {
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    self.navigationItem.prompt = @"";
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems: self.tags];
    [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 300.0f, 0.0f);
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.navigationItem.titleView = segmentedControl;
    
    CGFloat topOffset = self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    _navigation = [[UIView alloc] init];
    [self.navigationController.view addSubview:_navigation];
    
    _navigation.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[NSLayoutConstraint constraintWithItem:_navigation
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:_navigation
                                  attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:_navigation
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:_navigation
                                  attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:topOffset] setActive:YES];
    
    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.text = @"Notifications";
    [lblTitle setFont: [UIFont boldSystemFontOfSize:18.0]];

    [_navigation addSubview:lblTitle];
    lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[NSLayoutConstraint constraintWithItem:lblTitle
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:20] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:lblTitle
                                  attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:lblTitle
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:lblTitle
                                  attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeBottom
                                 multiplier:1 constant:0] setActive:YES];
    lblTitle.textAlignment = NSTextAlignmentCenter;
    
    UIButton *dismiss = [[UIButton alloc] init];
    [dismiss setTitle:@"✖️" forState:UIControlStateNormal];
    [dismiss addTarget:self action:@selector(dismisstapped) forControlEvents:UIControlEventTouchUpInside];
    
    [_navigation addSubview:dismiss];
    dismiss.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[NSLayoutConstraint constraintWithItem:dismiss
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:20] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:dismiss
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:dismiss
                                  attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeBottom
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:dismiss
                                  attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:60] setActive:YES];
}

- (void)setupNavigationBar {
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
//    self.navigationItem.prompt = @"";
    self.navigationItem.title = @"Notifications";
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems: self.tags];
    [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl sizeToFit];
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    CGFloat topOffset = self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    _toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, topOffset, self.navigationController.navigationBar.frame.size.width, kToolbarHeight)];
    _toolbar.barTintColor = [UIColor whiteColor];
    _toolbar.clipsToBounds = YES;
    _toolbar.translucent = NO;
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView: segmentedControl];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace                                                                                  target: nil  action: nil];
    [_toolbar setItems:@[flexibleItem, segmentedControlItem, flexibleItem] animated:YES];
    [self.navigationController.view addSubview: _toolbar];
    
    // set tableview frame
    self.tableView.contentInset = UIEdgeInsetsMake(topOffset, 0, 0, 0);
}

- (void)segmentSelected:(UISegmentedControl *)sender {
        
    if (sender.selectedSegmentIndex == 0) {
        self.filterMessages = [self.messages mutableCopy];
    } else {
        [self filterNotifications: self.tags[sender.selectedSegmentIndex]];
    }
    [self.tableView reloadData];
    
    [self.tableView layoutIfNeeded];
    self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top);
}

- (void)filterNotifications: (NSString *)filter{
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.tagString CONTAINS[c] %@", filter];
    self.filterMessages = [self.messages filteredArrayUsingPredicate:filterPredicate];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.filterMessages) {
        return 0;
    }
    return [self.filterMessages count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.filterMessages) {
        return 0;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    [self _notifyMessageViewed:message];
    
    if ([message.type isEqualToString:kSimpleMessage]) {
        
        CTInboxSimpleMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellSimpleMessageIdentifier forIndexPath:indexPath];
        
        if (message.content && message.content.count > 0) {
            [cell setupSimpleMessage:message.content[0]];
        }
        cell.actionView.hidden = YES;
        cell.titleLabel.text = message.title;
        cell.bodyLabel.text = message.body;
        cell.cellImageView.image = nil;
        cell.cellImageView.animatedImage = nil;
        cell.avPlayerContainerView.hidden = YES;
        
        [[NSLayoutConstraint constraintWithItem:cell.actionView
                                      attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:0] setActive:YES];
        
        if (message.imageUrl) {
            cell.cellImageView.hidden = NO;
            cell.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
            [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:message.imageUrl]
                                  placeholderImage:[self getPlaceHolderImage]
                                           options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
        }
        
        if (message.imageUrl == nil || [message.imageUrl isEqual: @""]) {
            cell.imageViewHeightContraint.priority = 999;
            cell.imageViewRatioContraint.priority = 750;
        } else {
            cell.imageViewRatioContraint.priority = 999;
            cell.imageViewHeightContraint.priority = 750;
        }

        if ([message.media[@"content_type"]  isEqual: @"video"]) {
            
            [cell setupVideoPlayer:message];
        }

        if (_config && _config.messageTitleColor) {
            cell.textLabel.textColor = _config.messageTitleColor;
        }
        if (_config && _config.cellBackgroundColor) {
            cell.contentView.backgroundColor = _config.cellBackgroundColor;
        }
        if (_config && _config.contentBorderColor) {
            cell.containerView.layer.borderColor = _config.contentBorderColor.CGColor;
        }
        
        [cell.contentView setNeedsLayout];
        [cell.contentView layoutIfNeeded];
        return cell;

    } else if ([message.type isEqualToString:kMultiMedia]) {
        
        CTCarouselMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellCarouselMessageIdentifier forIndexPath:indexPath];
        [cell setupCarouselMessage:message];
        [cell.contentView setNeedsLayout];
        [cell.contentView layoutIfNeeded];
        return cell;
    
    } else if ([message.type isEqualToString:kCarouselImageMessage]) {
        
        CTCarouselImageMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellCarouselImgMessageIdentifier forIndexPath:indexPath];
        [cell setupCarouselImageMessage:message];
        [cell.contentView setNeedsLayout];
        [cell.contentView layoutIfNeeded];
        return cell;
        
    } else if ([message.type isEqualToString:kIconMessage]) {
        
        CTInboxIconMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIconMessageIdentifier forIndexPath:indexPath];
        if (message.content && message.content.count > 0) {
            [cell setupIconMessage:message.content[0]];
        }
        cell.actionView.delegate = self;
        [cell.contentView setNeedsLayout];
        [cell.contentView layoutIfNeeded];
        return cell;
        
    } else {
        
        CTInboxSimpleMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellSimpleMessageIdentifier forIndexPath:indexPath];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    if ([message.type isEqualToString:kSimpleMessage]) {
        CTInboxSimpleMessageCell *messageCell = (CTInboxSimpleMessageCell*)cell;
         if ([message.media[@"content_type"]  isEqual: @"video"]) {
             [messageCell.playerLayer.player play];
         }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.filterMessages.count > 0) {
//        CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
//        if ([message.type isEqualToString:kSimpleMessage]) {
//            CTInboxSimpleMessageCell *messageCell = cell;
//            if ([message.media[@"content_type"]  isEqual: @"video"]) {
//                //            [messageCell.playerLayer.player pause];
//                //            messageCell.playerLayer.player = nil;
//            }
//        }
    }
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

- (void)inboxButtonDidTapped {
    
    CleverTapLogStaticDebug(@"%@: message link clicked:", self);
    // TODO handle button data
}

#pragma mark - Actions

- (void)dismisstapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
