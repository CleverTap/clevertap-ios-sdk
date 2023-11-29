
#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#import "CTCarouselImageMessageCell.h"
#import "CTInboxSimpleMessageCell.h"
#import "CTInboxIconMessageCell.h"
#import "CTInboxBaseMessageCell.h"
#import "CTCarouselMessageCell.h"

#import "CTUIUtils.h"
#import "CTConstants.h"
#import "CTInboxUtils.h"
#import "UIView+CTToast.h"

#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

NSString * const kCellSimpleMessageIdentifier = @"CTInboxSimpleMessageCell";
NSString * const kCellCarouselMessageIdentifier = @"CTCarouselMessageCell";
NSString * const kCellCarouselImgMessageIdentifier = @"CTCarouselImageMessageCell";
NSString * const kCellIconMessageIdentifier = @"CTInboxIconMessageCell";

NSString * const kDefaultTab = @"All";
static const float kCellSpacing = 6;
static const int kMaxTags = 3;

@interface CleverTapInboxViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *messages;
@property (nonatomic, copy) NSArray<CleverTapInboxMessage *> *filterMessages;
@property (nonatomic, copy) NSArray *tags;

@property (nonatomic, assign) int selectedSegmentIndex;
@property (nonatomic, assign) NSIndexPath *currentVideoIndex;
@property (nonatomic, strong) UIView *segmentedControlContainer;
@property (nonatomic, strong) UILabel *listEmptyLabel;

@property (nonatomic, strong) CleverTapInboxStyleConfig *config;

@property (nonatomic, weak) id<CleverTapInboxViewControllerDelegate> delegate;
@property (nonatomic, weak) id<CleverTapInboxViewControllerAnalyticsDelegate> analyticsDelegate;

@property (nonatomic, weak) CTInboxBaseMessageCell *playingCell;
@property (nonatomic, assign) CGRect tableViewVisibleFrame;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *unreachableCellDictionary;

@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) CGFloat topContentOffset;


@end

@implementation CleverTapInboxViewController

- (instancetype)initWithMessages:(NSArray *)messages
                          config:(CleverTapInboxStyleConfig *)config
                        delegate:(id<CleverTapInboxViewControllerDelegate>)delegate
               analyticsDelegate:(id<CleverTapInboxViewControllerAnalyticsDelegate>)analyticsDelegate {
    self = [self initWithNibName:NSStringFromClass([CleverTapInboxViewController class]) bundle:[CTInboxUtils bundle: CleverTapInboxViewController.class]];
    if (self) {
        _config = [config copy];
        _delegate = delegate;
        _analyticsDelegate = analyticsDelegate;
        _messages = messages;
        _filterMessages = _messages;
        
        NSMutableArray *tags = _config.messageTags.count > 0 ?  [NSMutableArray arrayWithArray:_config.messageTags] : [NSMutableArray new];
        
        if ([tags count] > 0) {
            // Use the first tab title if specified in the config, or else fallback to the Default one
            NSString *firstTabTitle = (config.firstTabTitle && config.firstTabTitle.length > 0) ? config.firstTabTitle : kDefaultTab;
            [tags insertObject:firstTabTitle atIndex:0];
            _topContentOffset = 33.f;
        }
        if ([tags count] > kMaxTags) {
            _tags = [tags subarrayWithRange:NSMakeRange(0, kMaxTags)];
        } else {
            _tags = tags;
        }
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"✕"
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(dismissTapped)];
    self.navigationItem.rightBarButtonItem = closeButton;
    self.navigationItem.title = [self getTitle];
    self.navigationController.navigationBar.translucent = false;
    
    self.muted = YES;
    [self addObservers];
    [self registerNibs];
    [self setUpInboxLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self playVideoInVisibleCells];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateInboxLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    if (self.segmentedControlContainer) {
        [self.segmentedControlContainer removeFromSuperview];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self calculateTableViewVisibleFrame];
}

- (void)loadView {
    [super loadView];
}

- (void)traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    [self updateInboxLayout];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMessageTapped:)
                                                 name:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaPlayingNotification:)
                                                 name:CLTAP_INBOX_MESSAGE_MEDIA_PLAYING_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaMutedNotification:)
                                                 name:CLTAP_INBOX_MESSAGE_MEDIA_MUTED_NOTIFICATION object:nil];
    
}

- (void)setUpInboxLayout {
    
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"#EAEAEA"];
    self.view.backgroundColor = (_config && _config.backgroundColor) ? _config.backgroundColor : color;
    self.tableView.backgroundColor = (_config && _config.backgroundColor) ? _config.backgroundColor : color;
    
    // Update Background and Bar Tint Color of Navigation Bar
    self.navigationController.view.backgroundColor = (_config && _config.navigationBarTintColor) ? _config.navigationBarTintColor : [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = (_config && _config.navigationBarTintColor) ? _config.navigationBarTintColor : [UIColor whiteColor];
    // Update Tint and Title Color of Navigation Bar
    self.navigationController.navigationBar.tintColor = (_config && _config.navigationTintColor) ? _config.navigationTintColor : [UIColor blackColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : (_config && _config.navigationTintColor) ? _config.navigationTintColor : [UIColor blackColor]};
    
    [self setUpTableViewLayout];
    [self calculateTableViewVisibleFrame];
}

- (void)setUpTableViewLayout {
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, kCellSpacing)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
    }
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)updateInboxLayout {
    if ([self.tags count] > 0) {
        [self setUpSegmentedContainer];
    }
    [self showListEmptyLabel];
    [self calculateTableViewVisibleFrame];
}

- (void)registerNibs {
    [self.tableView registerNib:[UINib nibWithNibName:[CTInboxUtils getXibNameForControllerName:NSStringFromClass([CTInboxSimpleMessageCell class])]
                                               bundle:[CTInboxUtils bundle: CTInboxSimpleMessageCell.class]]
         forCellReuseIdentifier:kCellSimpleMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:[CTInboxUtils getXibNameForControllerName:NSStringFromClass([CTCarouselMessageCell class])]
                                               bundle:[CTInboxUtils bundle: CTCarouselMessageCell.class]]
         forCellReuseIdentifier:kCellCarouselMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:[CTInboxUtils getXibNameForControllerName:NSStringFromClass([CTCarouselImageMessageCell class])]
                                               bundle:[CTInboxUtils bundle: CTCarouselImageMessageCell.class]]
         forCellReuseIdentifier:kCellCarouselImgMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:[CTInboxUtils getXibNameForControllerName:NSStringFromClass([CTInboxIconMessageCell class])]
                                               bundle:[CTInboxUtils bundle: CTInboxIconMessageCell.class]]
         forCellReuseIdentifier:kCellIconMessageIdentifier];
}

- (NSString *)getTitle {
    return self.config.title ? self.config.title : @"Notifications";
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        [self loadView];
        [self registerNibs];
        [self setUpInboxLayout];
        if ([self.tags count] > 0) {
            [self setUpSegmentedContainer];
        }
        [self showListEmptyLabel];
        [self stopPlay];
        [self.tableView reloadData];
        [self playVideoInVisibleCells];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)calculateTableViewVisibleFrame {
    CGRect frame = self.tableView.frame;
    BOOL landscape = [CTUIUtils isDeviceOrientationLandscape];
    if (landscape) {
        frame.origin.y += self.topContentOffset;
        frame.size.height -= self.topContentOffset;
    }
    self.tableViewVisibleFrame = frame;
}

- (void)setUpSegmentedContainer {
    [self.navigationController.view layoutSubviews];
    [self.segmentedControlContainer removeFromSuperview];
    self.segmentedControlContainer = [[UIView alloc] init];
    self.segmentedControlContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.segmentedControlContainer.backgroundColor = (_config && _config.navigationBarTintColor) ? _config.navigationBarTintColor : [UIColor whiteColor];
    [self.navigationController.view addSubview:self.segmentedControlContainer];
    [self addSegmentedControl];
}

- (void)addSegmentedControl {
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems: self.tags];
    segmentedControl.selectedSegmentIndex = _selectedSegmentIndex;
    segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [segmentedControl addTarget:self
                         action:@selector(segmentSelected:)
               forControlEvents:UIControlEventValueChanged];
    
    /// Update the Segment Control Tint Color
    if (@available(iOS 13.0, *)) {
        segmentedControl.selectedSegmentTintColor = (_config && _config.tabSelectedBgColor) ? _config.tabSelectedBgColor : [UIColor whiteColor];
    } else {
        segmentedControl.tintColor = (_config && _config.tabSelectedBgColor) ? _config.tabSelectedBgColor : [UIColor whiteColor];
    }
    
    /// Update the Segment Control Tab Selected Color
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName :(_config && _config.tabSelectedTextColor) ? _config.tabSelectedTextColor : [UIColor blackColor]} forState:UIControlStateSelected];
    /// Update the Segment Control Tab UnSelected Color
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName :(_config && _config.tabUnSelectedTextColor) ? _config.tabUnSelectedTextColor : [UIColor blackColor]} forState:UIControlStateNormal];
    /// Add Segment Control
    [self.segmentedControlContainer addSubview:segmentedControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(_topContentOffset, 0, 0, 0)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointMake(0, -(self->_topContentOffset))
                                animated:NO];
    });
    [self updateSegmentedLayoutConstraint: segmentedControl];
}

- (void)updateSegmentedLayoutConstraint:(UISegmentedControl *)segmentedControl {
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat navBarY = self.navigationController.navigationBar.frame.origin.y;
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:(navigationBarHeight+navBarY)] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:_topContentOffset] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:25] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:-25] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:30] setActive:YES];
}

- (void)segmentSelected:(UISegmentedControl *)sender {
    _selectedSegmentIndex = (int)sender.selectedSegmentIndex;
    if (sender.selectedSegmentIndex == 0) {
        self.filterMessages = self.messages;
    } else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.tagString CONTAINS[c] %@", self.tags[sender.selectedSegmentIndex]];
        self.filterMessages = [self.messages filteredArrayUsingPredicate:filterPredicate];
    }
    [self _reloadTableView];
}

- (void)_reloadTableView {
    [self showListEmptyLabel];
    [self stopPlay];
    [self.tableView setContentOffset:CGPointMake(0, -_topContentOffset) animated:NO];
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self.tableView setContentOffset:CGPointMake(0, -_topContentOffset) animated:NO];
    [self playVideoInVisibleCells];
}

- (void)showListEmptyLabel {
    if (self.filterMessages.count <= 0) {
        CGRect frame = self.view.frame;
        if (!self.listEmptyLabel) {
            self.listEmptyLabel = [[UILabel alloc] init];
            self.listEmptyLabel.text = self.config.noMessageViewText ? self.config.noMessageViewText : [NSString stringWithFormat:@"%@", @"No message(s) to show"];
            self.listEmptyLabel.textColor = self.config.noMessageViewTextColor ? self.config.noMessageViewTextColor : UIColor.blackColor;
            self.listEmptyLabel.textAlignment = NSTextAlignmentCenter;
        }
        if ([self.listEmptyLabel isDescendantOfView:self.view]) {
            [self.listEmptyLabel removeFromSuperview];
        }
        self.listEmptyLabel.frame = CGRectMake(0, 10, frame.size.width, 44);
        [self.view addSubview:self.listEmptyLabel];
    } else {
        if (self.listEmptyLabel) {
            [self.listEmptyLabel removeFromSuperview];
        }
    }
}


#pragma mark - UITableViewDataSource

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
    CTInboxMessageType messageType = [CTInboxUtils inboxMessageTypeFromString:message.type];
    NSString *identifier = kCellSimpleMessageIdentifier;
    switch (messageType) {
        case CTInboxMessageTypeSimple:
            identifier = kCellSimpleMessageIdentifier;
            break;
        case CTInboxMessageTypeCarousel:
            identifier = kCellCarouselMessageIdentifier;
            break;
        case CTInboxMessageTypeCarouselImage:
            identifier = kCellCarouselImgMessageIdentifier;
            break;
        case CTInboxMessageTypeMessageIcon:
            identifier = kCellIconMessageIdentifier;
            break;
        default:
            CleverTapLogStaticDebug(@"unknown Inbox Message Type, defaulting to Simple message");
            identifier = kCellSimpleMessageIdentifier;
            break;
    }
    CTInboxBaseMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [cell configureForMessage:message];
    if ([cell hasVideo]) {
        [cell mute:self.muted];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CleverTapInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    if (!message.isRead){
        [self _notifyMessageViewed:message];
        [message setRead:YES];
    }
}


#pragma mark - Actions

- (void)dismissTapped {
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
            [self.parentViewController.view ct_makeToast:@"Copied to clipboard" duration:2.0 position:CTToastPositionBottom];
        } else if ([actionType caseInsensitiveCompare:@"rfp"] == NSOrderedSame) {
            BOOL fbSettings = link[@"fbSettings"] ? [link[@"fbSettings"] boolValue] : NO;
            [self.analyticsDelegate messageDidSelectForPushPermission:fbSettings];
            return;
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageButtonTappedWithCustomExtras:)]) {
        if (!(buttonIndex < 0)) {
            CleverTapInboxMessageContent *content = (CleverTapInboxMessageContent*)message.content[index];
            NSDictionary *customExtras = [content customDataForLinkAtIndex:buttonIndex];
            if (customExtras && customExtras.count > 0) {
                [self.delegate messageButtonTappedWithCustomExtras:customExtras];
            }
        }
    }
    
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidSelect:atIndex:withButtonIndex:)]) {
        [self.analyticsDelegate messageDidSelect:message atIndex:index withButtonIndex:buttonIndex];
    }
}


#pragma mark - Video Player Handling

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self handleScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self handleScrollStop];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self handleScrollStop];
}

- (void)handleMediaPlayingNotification:(NSNotification*)notification {
    CTInboxBaseMessageCell *cell = (CTInboxBaseMessageCell*)notification.object;
    if (!self.playingCell) {
        self.playingCell = cell;
    } else if (self.playingCell != cell) {
        [self stopPlay];
        self.playingCell = cell;
    }
}

- (void)handleMediaMutedNotification:(NSNotification*)notification {
    self.muted = [notification.userInfo[@"muted"] boolValue];
    NSArray<CTInboxBaseMessageCell *> *visibleCells = [self.tableView visibleCells];
    for (CTInboxBaseMessageCell *cell in visibleCells) {
        if ([cell hasVideo]) {
            [cell mute:self.muted];
        }
    }
}

- (void)playVideoInVisibleCells {
    if (self.playingCell) {
        [self playWithCell:self.playingCell];
        return;
    }
    [self playWithCell:[self findTheBestPlayCell]];
}

- (void)stopPlay {
    [self.playingCell pause];
    self.playingCell = nil;
}

- (BOOL)cellMediaIsVisible:(CTInboxBaseMessageCell *)cell {
    if (CGRectIsEmpty(self.tableViewVisibleFrame) || !cell) {
        return NO;
    }
    CGRect referenceRect = [self.tableView.superview convertRect:self.tableViewVisibleFrame toView:nil];
    // use fallback for MessageIcon
    CGRect localMediaRect = (cell.messageType == CTInboxMessageTypeMessageIcon) ? CGRectZero : [cell videoRect];
    // video
    if (!CGRectIsEmpty(localMediaRect)) {
        CGRect referenceMediaRect = [cell convertRect:localMediaRect toView:nil];
        return CGRectContainsRect(referenceRect, referenceMediaRect);
    }
    // audio/fallback test
    CGPoint viewTopPoint = cell.frame.origin;
    CGFloat topOffset = 1;
    CGFloat bottomOffset = 2;
    CGFloat cellHeight =  cell.bounds.size.height;
    CGFloat multiplier = [CTUIUtils isUserInterfaceIdiomPad] ? 1.5 : 1;
    
    switch (cell.mediaPlayerCellType) {
        case CTMediaPlayerCellTypeTopLandscape:
            topOffset = 30.0 * multiplier;
            bottomOffset = 100.0 * multiplier;
            break;
        case CTMediaPlayerCellTypeTopPortrait:
            topOffset = 80.0 * multiplier;
            bottomOffset = 150.0 * multiplier;
            break;
        case CTMediaPlayerCellTypeMiddleLandscape:
            topOffset = 75.0 * multiplier;
            bottomOffset = 100.0 * multiplier;
            break;
        case CTMediaPlayerCellTypeMiddlePortrait:
            topOffset = 125.0 * multiplier;
            bottomOffset = 150.0 * multiplier;
            break;
        case CTMediaPlayerCellTypeBottomLandscape:
            topOffset = 100.0 * multiplier;
            bottomOffset = 50.0 * multiplier;
            break;
        case CTMediaPlayerCellTypeBottomPortrait:
            topOffset = 150.0 * multiplier;
            bottomOffset = 100.0 * multiplier;
            break;
        default:
            return NO;
            break;
    }
    CGPoint viewLeftTopPoint = viewTopPoint;
    viewLeftTopPoint.y += topOffset;
    CGPoint topCoordinatePoint = [cell.superview convertPoint:viewLeftTopPoint toView:nil];
    BOOL isTopContain = CGRectContainsPoint(referenceRect, topCoordinatePoint);
    
    CGFloat viewBottomY = viewTopPoint.y + cellHeight;
    viewBottomY -= bottomOffset;
    CGPoint viewLeftBottomPoint = CGPointMake(viewTopPoint.x, viewBottomY);
    CGPoint bottomCoordinatePoint = [cell.superview convertPoint:viewLeftBottomPoint toView:nil];
    BOOL isBottomContain = CGRectContainsPoint(referenceRect, bottomCoordinatePoint);
    if(!isTopContain || !isBottomContain){
        return NO;
    }
    return YES;
}

- (CTInboxBaseMessageCell *)findTheBestPlayCell {
    if(CGRectIsEmpty(self.tableViewVisibleFrame)){
        return nil;
    }
    CTInboxBaseMessageCell *targetCell = nil;
    UITableView *tableView = self.tableView;
    NSArray<CTInboxBaseMessageCell *> *visibleCells = [tableView visibleCells];
    
    for (CTInboxBaseMessageCell *cell in visibleCells) {
        if (![cell hasVideo]) {
            continue;
        }
        if ([self cellMediaIsVisible:cell]) {
            targetCell = cell;
            break;
        }
    }
    return targetCell;
}

- (void)playWithCell:(CTInboxBaseMessageCell *)cell {
    if (!cell) {
        return;
    }
    self.playingCell = cell;
    [cell mute:self.muted];
    [cell play];
}

- (void)handleScroll {
    if (!self.playingCell) {
        return;
    }
    if (![self cellMediaIsVisible:self.playingCell]) {
        [self stopPlay];
    }
}

- (void)handleScrollStop {
    if (self.playingCell && [self cellMediaIsVisible:self.playingCell]) {
        return;
    }
    
    CTInboxBaseMessageCell *bestCell = [self findTheBestPlayCell];
    if (!bestCell) {
        [self stopPlay];
        return;
    }
    [self stopPlay];
    [self playWithCell:bestCell];
}

@end
