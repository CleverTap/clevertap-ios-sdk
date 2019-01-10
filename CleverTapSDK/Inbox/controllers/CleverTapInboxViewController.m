#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#import "CTInboxSimpleMessageCell.h"
#import "CTCarouselMessageCell.h"
#import "CTCarouselImageMessageCell.h"
#import "CTInboxIconMessageCell.h"
#import "CTConstants.h"
#import "CTInAppResources.h"
#import "CTInAppUtils.h"
#import "UIView+CTToast.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

NSString* const kCellSimpleMessageIdentifier = @"CTInboxSimpleMessageCell";
NSString* const kCellCarouselMessageIdentifier = @"CTCarouselMessageCell";
NSString* const kCellCarouselImgMessageIdentifier = @"CTCarouselImageMessageCell";
NSString* const kCellIconMessageIdentifier = @"CTInboxIconMessageCell";

NSString* const kSimpleMessage = @"simple";
NSString* const kIconMessage = @"message-icon";
NSString* const kCarouselMessage = @"carousel";
NSString* const kCarouselImageMessage = @"carousel-image";

@interface CleverTapInboxViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *messages;
@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *filterMessages;
@property (nonatomic, copy) NSArray *tags;

@property (nonatomic, assign) NSIndexPath *currentVideoIndex;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMessageTapped:)
                                                 name:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:nil];
    
    [self registerNibs];
    [self loadData];
    [self setupLayout];
    if (_config.backgroundColor) {
        self.tableView.backgroundColor =  _config.backgroundColor;
    } else {
        self.tableView.backgroundColor =  [CTInAppUtils ct_colorWithHexString:@"#EAEAEA"];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)registerNibs {
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxSimpleMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellSimpleMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTCarouselMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellCarouselMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTCarouselImageMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellCarouselImgMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxIconMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellIconMessageIdentifier];
}

- (void)loadData {
    self.filterMessages = self.messages;
    if (_config.messageTags.count > 0) {
        NSString *defaultTag = @"All";
        NSMutableArray *tags = [NSMutableArray new];
        [tags addObject:defaultTag];
        [tags addObject:_config.messageTags[0]];
        if (_config.messageTags.count > 1) {
            [tags addObject:_config.messageTags[1]];
        }
        self.tags = [tags mutableCopy];
    }
}

#pragma mark - setup layout

- (void) traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    if (_config.messageTags.count > 0) {
        [self setupSegmentController];
    }
}

- (void)setupLayout {
    
    // set tableview
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 6.0)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    if (self.filterMessages.count == 0) {
        
        UILabel *lblMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, (CGFloat) [[UIScreen mainScreen] bounds].size.height/2, (CGFloat) [[UIScreen mainScreen] bounds].size.width, 44)];
        lblMessage.text = @"No message(s) to show";
        lblMessage.tag = 108;
        lblMessage.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:lblMessage];
        
    } else {
        UILabel *removeLabel;
        while((removeLabel = [self.view viewWithTag:108]) != nil) {
            [removeLabel removeFromSuperview];
        }
    }
    
    if (self.tags.count == 0) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithTitle:@"✕"
                                       style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(dismisstapped)];
        self.navigationItem.rightBarButtonItem = backButton;
        self.navigationItem.title = @"Notifications";
        self.navigationController.navigationBar.translucent = false;
        if (_config.navigationBarTintColor) {
            self.navigationController.navigationBar.barTintColor = _config.navigationBarTintColor;
        } else  {
            self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
        }
        
        if (_config.navigationBarTintColor) {
            self.navigationController.navigationBar.tintColor = _config.navigationTintColor;
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : _config.navigationTintColor};
        } else  {
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        }
        
    } else {
        [self setupSegmentController];
    }
}

- (void)setupSegmentController {
   
    // set navigation bar
    self.navigationController.navigationBar.translucent = false;
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    if (_config && _config.navigationBarTintColor) {
        [self.navigationController.navigationBar setBarTintColor:_config.navigationBarTintColor];
    } else {
        [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    }
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems: self.tags];
    [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 300.0f, 0.0f);
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.layer.masksToBounds = YES;
    segmentedControl.clipsToBounds = YES;
    
    if (_config && _config.tabBackgroundColor) {
        segmentedControl.backgroundColor = _config.tabBackgroundColor;
    }
    if (_config && _config.tabSelectedBgColor) {
        segmentedControl.tintColor = _config.tabSelectedBgColor;
    }
    if (_config && _config.tabSelectedTextColor) {
        [[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : _config.tabSelectedTextColor} forState:UIControlStateSelected];
    }
    if (_config && _config.tabUnSelectedTextColor) {
        [[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : _config.tabUnSelectedTextColor} forState:UIControlStateNormal];
    }
    
    if (self.tags.count > 1) {
        self.navigationItem.prompt = @"";
        self.navigationItem.titleView = segmentedControl;
    }
    
    [self.navigationController.view layoutSubviews];
    CGFloat topOffset = (self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height) - 34;
    
    CGFloat statusOffset = [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    
    [self.navigation removeFromSuperview];
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
                                 multiplier:1 constant:topOffset-3] setActive:YES];
    
    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.text = @"Notifications";
    [lblTitle setFont: [UIFont boldSystemFontOfSize:18.0]];
    [_navigation addSubview:lblTitle];
    lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[NSLayoutConstraint constraintWithItem:lblTitle
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:statusOffset] setActive:YES];
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
    [dismiss setTitle:@"✕" forState:UIControlStateNormal];
    [dismiss setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [dismiss addTarget:self action:@selector(dismisstapped) forControlEvents:UIControlEventTouchUpInside];
    [_navigation addSubview:dismiss];
    dismiss.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (_config && _config.navigationTintColor) {
        lblTitle.textColor = _config.navigationTintColor;
        [dismiss setTitleColor:_config.navigationTintColor forState:UIControlStateNormal];
    }
    
    [[NSLayoutConstraint constraintWithItem:dismiss
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:_navigation attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:statusOffset] setActive:YES];
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

- (void)segmentSelected:(UISegmentedControl *)sender {
        
    if (sender.selectedSegmentIndex == 0) {
        self.filterMessages = [self.messages mutableCopy];
    } else {
        [self filterNotifications: self.tags[sender.selectedSegmentIndex]];
    }
    
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self.tableView setContentOffset:CGPointZero animated:YES];

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
    if (!message.isRead){
        [self _notifyMessageViewed:message];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [message setRead:YES];
        });
    }

    if ([message.type isEqualToString:kSimpleMessage]) {
        
        CTInboxSimpleMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellSimpleMessageIdentifier forIndexPath:indexPath];
        cell.actionView.delegate = cell;
        [cell layoutNotification:message];
        
        if (message.content && message.content.count > 0) {
            [cell setupSimpleMessage:message];
        }
        if (message.backgroundColor && ![message.backgroundColor isEqual:@""]) {
            cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        } else {
            cell.containerView.backgroundColor = [UIColor whiteColor];
        }
        return cell;
        
    } else if ([message.type isEqualToString:kCarouselMessage]) {
        
        CTCarouselMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellCarouselMessageIdentifier forIndexPath:indexPath];
        [cell setupCarouselMessage:message];
        if (message.backgroundColor && ![message.backgroundColor isEqual:@""]) {
            cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        } else {
            cell.containerView.backgroundColor = [UIColor whiteColor];
        }
        [cell layoutIfNeeded];
        [cell layoutSubviews];
        return cell;
        
    } else if ([message.type isEqualToString:kCarouselImageMessage]) {
        
        CTCarouselImageMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellCarouselImgMessageIdentifier forIndexPath:indexPath];
        
        [cell setupCarouselImageMessage:message];
        
        if (message.backgroundColor && ![message.backgroundColor isEqual:@""]) {
            cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        } else {
            cell.containerView.backgroundColor = [UIColor whiteColor];
        }
        [cell layoutIfNeeded];
        [cell layoutSubviews];
        return cell;
        
    } else if ([message.type isEqualToString:kIconMessage]) {
        
        CTInboxIconMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIconMessageIdentifier forIndexPath:indexPath];
        [cell layoutNotification:message];

        if (message.content && message.content.count > 0) {
            [cell setupIconMessage:message];
        }
        cell.actionView.delegate = cell;
        if (message.backgroundColor && ![message.backgroundColor isEqual:@""]) {
            cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        } else {
            cell.containerView.backgroundColor = [UIColor whiteColor];
        }
        return cell;
        
    } else {
        CTInboxSimpleMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellSimpleMessageIdentifier forIndexPath:indexPath];
        return cell;
    }
}
    
- (UIImage *)getPlaceHolderImage {
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"placeholder" ofType:@"png"];
    return [UIImage imageWithContentsOfFile:imagePath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if([cell isKindOfClass:[CTInboxSimpleMessageCell class]]){
        CTInboxSimpleMessageCell *messageCell = (CTInboxSimpleMessageCell*)cell;
        CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
        if(message.content[0].mediaIsVideo){
            [messageCell play];
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if([cell isKindOfClass:[CTInboxSimpleMessageCell class]]){
        CTInboxSimpleMessageCell *messageCell = (CTInboxSimpleMessageCell*)cell;
        if  (self.filterMessages.count > 0 && self.filterMessages.count > indexPath.section) {
            CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
            if(message.content[0].mediaIsVideo){
                [messageCell pause];
             }else if (message.content[0].mediaIsAudio) {
                 [messageCell pause];
           }
        }
    }
}


#pragma mark - Actions

- (void)dismisstapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Inbox Message Handling

- (void)handleMessageTapped:(NSNotification *)notification {
    
    CleverTapInboxMessage *message = (CleverTapInboxMessage*)notification.object;
    NSDictionary *userInfo = (NSDictionary *)notification.userInfo;
    int index = [[userInfo objectForKey:@"index"] intValue];
    int buttonIndex = [[userInfo objectForKey:@"buttonIndex"] intValue];
    if  (buttonIndex >= 0) {
        // handle copy to clipboard
        CleverTapInboxMessageContent *content = message.content[index];
        NSDictionary *link = content.links[buttonIndex];
        NSString *actionType = link[@"type"];
        if ([actionType caseInsensitiveCompare:@"copy"] == NSOrderedSame) {
            NSString *copy = link[@"copyText"][@"text"];
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = copy;
            [self.parentViewController.view makeToast:@"Copied to clipboard" duration:2.0 position:CSToastPositionBottom];
        }
    }
    
    [self _notifyMessageSelected:message atIndex:index withButtonIndex:buttonIndex];
}

- (void)_notifyMessageViewed:(CleverTapInboxMessage *)message {
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidShow:)]) {
        [self.analyticsDelegate messageDidShow:message];
    }
}

- (void)_notifyMessageSelected:(CleverTapInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageDidSelect:atIndex:withButtonIndex:)]) {
        [self.delegate messageDidSelect:message atIndex:index withButtonIndex:buttonIndex];
    }
    
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidSelect:atIndex:withButtonIndex:)]) {
        [self.analyticsDelegate messageDidSelect:message atIndex:index withButtonIndex:buttonIndex];
    }
}

@end
