#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#import "CTInboxSimpleMessageCell.h"
#import "CTCarouselMessageCell.h"
#import "CTCarouselImageMessageCell.h"
#import "CTInboxIconMessageCell.h"
#import "CTConstants.h"
#import "CTInAppResources.h"
#import "CTInAppUtils.h"

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
NSString* const kIconMessage = @"icon-message";
NSString* const kCarouselMessage = @"carousel";
NSString* const kCarouselImageMessage = @"carousel-image";

static CGFloat kSegmentHeight = 32.0;
static CGFloat kToolbarHeight = 48.0;

NSString* const kACTION_TYPE_COPY = @"copy";
NSString* const kACTION_TYPE_URL = @"url";

NSString* const kACTION_TYPE = @"type";
NSString* const kACTION_COPY_TEXT = @"copyText";
NSString* const kACTION_DL = @"url";

@interface CleverTapInboxViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *messages;
@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *filterMessages;
@property (nonatomic, copy) NSArray *tags;

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
    
    [self.navigationController.navigationBar sizeToFit];
    [self registerNibs];
    [self loadData];
    [self setupLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topOffset = self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
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
//    self.tags = _config.messageTags;
}

#pragma mark - setup layout

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self setupSegmentController];
}

- (void)setupLayout {
    
    // set tableview
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setupSegmentController];
}

- (void)setupSegmentController {
   
    // set navigatiob bar
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems: self.tags];
    [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 300.0f, 0.0f);
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.selectedSegmentIndex = 0;
    
    CGFloat topOffset = self.navigationController.navigationBar.frame.size.height + [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    
    CGFloat statusOffset = [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    
    if (self.tags.count > 1) {
        self.navigationItem.prompt = @"";
        self.navigationItem.titleView = segmentedControl;
    }
    
    [self.navigation removeFromSuperview];
    _navigation = [[UIView alloc] init];
    [self.navigationController.navigationBar addSubview:_navigation];
    _navigation.translatesAutoresizingMaskIntoConstraints = NO;
//    _navigation.backgroundColor = [UIColor redColor];
    
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
    [dismiss setTitle:@"✖️" forState:UIControlStateNormal];
    [dismiss addTarget:self action:@selector(dismisstapped) forControlEvents:UIControlEventTouchUpInside];
    
    [_navigation addSubview:dismiss];
    dismiss.translatesAutoresizingMaskIntoConstraints = NO;
    
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
    [self.tableView layoutSubviews];
    [self.tableView layoutIfNeeded];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top);
    });
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
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];

    if (!message.isRead){
        [self _notifyMessageViewed:message];
//        [[CleverTap sharedInstance] markReadInboxMessage:message];
    }

    if ([message.type isEqualToString:kSimpleMessage]) {
        
        CTInboxSimpleMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellSimpleMessageIdentifier forIndexPath:indexPath];
        cell.actionView.delegate = cell;
        [cell layoutNotification:message];
        
        if (message.content && message.content.count > 0) {
            [cell setupSimpleMessage:message];
        }

        cell.dateLabel.text = message.relativeDate;
        
        if (message.content[0].mediaIsVideo) {
            
            cell.avPlayerContainerView.hidden = NO;
            cell.cellImageView.hidden = YES;
            [cell setupVideoPlayer:message];
        }

        cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        
        return cell;
        
    } else if ([message.type isEqualToString:kCarouselMessage]) {
        
        CTCarouselMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellCarouselMessageIdentifier forIndexPath:indexPath];
        [cell setupCarouselMessage:message];
        cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        return cell;
    } else if ([message.type isEqualToString:kCarouselImageMessage]) {
        
        CTCarouselImageMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellCarouselImgMessageIdentifier forIndexPath:indexPath];
        [cell setupCarouselImageMessage:message];
        cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
        return cell;
    } else if ([message.type isEqualToString:kIconMessage]) {
        
        CTInboxIconMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIconMessageIdentifier forIndexPath:indexPath];
        [cell layoutNotification:message];

        if (message.content && message.content.count > 0) {
            [cell setupIconMessage:message];
        }
        cell.actionView.delegate = cell;
        cell.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    CleverTapLogStaticDebug(@"%@: message selected: %@", self, message);
    if (message.content.count == 1) {
        CleverTapInboxMessageContent *content = (CleverTapInboxMessageContent*)message.content[0];
        if ([content.actionType isEqualToString:@"onmessage"]) {
            [self _notifyMessageSelected:message];
            [self handleDeeplinks: content.actionUrl];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    if ([message.type isEqualToString:kSimpleMessage]) {
        CTInboxSimpleMessageCell *messageCell = (CTInboxSimpleMessageCell*)cell;
         if (message.content[0].mediaIsVideo) {
//             [messageCell.playerLayer.player play];
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

#pragma mark - Actions

- (void)dismisstapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Message Handling

- (void)handleMessageTapped:(NSNotification *)notification {
    
    CleverTapInboxMessage *message = (CleverTapInboxMessage*)notification.object;
    [self _notifyMessageSelected:message];
    
    NSDictionary *userInfo = (NSDictionary *)notification.userInfo;
    int index = [[userInfo objectForKey:@"index"] intValue];
    
    if (message.content.count > 1) {
        
        CleverTapInboxMessageContent *content = (CleverTapInboxMessageContent*)message.content[index];
        if (content.actionUrl && content.actionUrl != @""){
            [self handleDeeplinks:content.actionUrl];
        }
    } else {
        
        if ([message.content[0] isKindOfClass:[CleverTapInboxMessageContent class]]) {
            
            CleverTapInboxMessageContent *content = (CleverTapInboxMessageContent*)message.content[0];
            NSDictionary *link = content.links[index];
            NSString *actionType = link[kACTION_TYPE];
            
            if ([actionType isEqualToString:kACTION_TYPE_COPY]) {
                NSString *copyText = link[kACTION_COPY_TEXT];
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = copyText;
            } else if ( [actionType isEqualToString:kACTION_TYPE_URL]) {
                [self handleDeeplinks:link[@"url"][@"ios"]];
            }
        }
    }
}

- (void)handleDeeplinks:(NSString *)dl {
    
    UIApplication *application = [CTInAppResources getSharedApplication];
    
    if (dl && [dl isKindOfClass:[NSString class]]) {
        __block NSURL *dlURL = [NSURL URLWithString:dl];
        if (dlURL) {
            if (@available(iOS 10.0, *)) {
                if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                    NSMethodSignature *signature = [UIApplication instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
                    NSInvocation *invocation = [NSInvocation
                                                invocationWithMethodSignature:signature];
                    [invocation setTarget:application];
                    [invocation setSelector:@selector(openURL:options:completionHandler:)];
                    NSDictionary *options = @{};
                    id completionHandler = nil;
                    [invocation setArgument:&dlURL atIndex:2];
                    [invocation setArgument:&options atIndex:3];
                    [invocation setArgument:&completionHandler atIndex:4];
                    [invocation invoke];
                } else {
                    if ([application respondsToSelector:@selector(openURL:)]) {
                        [application performSelector:@selector(openURL:) withObject:dlURL];
                    }
                }
            } else {
                if ([application respondsToSelector:@selector(openURL:)]) {
                    [application performSelector:@selector(openURL:) withObject:dlURL];
                }
            }
        }
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

@end
