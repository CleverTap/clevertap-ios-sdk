#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#import "CTInboxSimpleMessageCell.h"
#import "CTCarouselMessageCell.h"
#import "CTCarouselImageMessageCell.h"
#import "CTInboxIconMessageCell.h"
#import "CTInboxBaseMessageCell.h"
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
NSString* const kDefaultTag = @"All";

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

@property (nonatomic, weak) CTInboxBaseMessageCell *playingVideoCell;
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
    self = [self initWithNibName:NSStringFromClass([CleverTapInboxViewController class]) bundle:[NSBundle bundleForClass:CleverTapInboxViewController.class]];
    if (self) {
        _config = [config copy];
        _delegate = delegate;
        _analyticsDelegate = analyticsDelegate;
        _messages = messages;
        _filterMessages = _messages;
        
        NSMutableArray *tags = _config.messageTags.count > 0 ?  [NSMutableArray arrayWithArray:_config.messageTags] : [NSMutableArray new];
        if ([tags count] > 0) {
            [tags insertObject:kDefaultTag atIndex:0];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMessageTapped:)
                                                 name:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaPlayingNotification:)
                                                 name:CLTAP_INBOX_MESSAGE_MEDIA_PLAYING_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaMutedNotification:)
                                                 name:CLTAP_INBOX_MESSAGE_MEDIA_MUTED_NOTIFICATION object:nil];
    [self registerNibs];
    
    self.muted = YES;
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"✕"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(dismissTapped)];
    self.navigationItem.rightBarButtonItem = closeButton;
    self.navigationItem.title = [self getTitle];
    self.navigationController.navigationBar.translucent = false;
    
    if (_config && _config.backgroundColor) {
        self.view.backgroundColor = _config.backgroundColor;
        self.tableView.backgroundColor = _config.backgroundColor;
        self.view.backgroundColor = _config.backgroundColor;
        self.navigationController.view.backgroundColor = _config.backgroundColor;
    } else {
        UIColor *color = [CTInAppUtils ct_colorWithHexString:@"#EAEAEA"];
        self.tableView.backgroundColor = color;
        self.view.backgroundColor = color;
        self.navigationController.view.backgroundColor = color;
    }
    
    if (_config && _config.navigationBarTintColor) {
        self.navigationController.navigationBar.barTintColor = _config.navigationBarTintColor;
    } else  {
        self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    }
    
    if (_config && _config.navigationTintColor) {
        self.navigationController.navigationBar.tintColor = _config.navigationTintColor;
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : _config.navigationTintColor};
    } else  {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, kCellSpacing)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    self.tableViewVisibleFrame = self.tableView.frame;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self playVideoInVisibleCellsIfNeed];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerNibs {
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxSimpleMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellSimpleMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTCarouselMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellCarouselMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTCarouselImageMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellCarouselImgMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CTInboxIconMessageCell class]) bundle:[NSBundle bundleForClass:CTInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellIconMessageIdentifier];
}

- (NSString*)getTitle {
    return self.config.title ? self.config.title : @"Notifications";
}

- (void)traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    if ([self.tags count] > 0) {
        [self setupSegmentedControl];
    }
    [self showListEmptyLabel];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> completion) {
        UIInterfaceOrientation orientation = [[CTInAppResources getSharedApplication] statusBarOrientation];
        BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGRect currentFrame = self.tableView.frame;
        if (landscape) {
            self.tableView.frame = CGRectMake((screenBounds.size.width - screenBounds.size.height)/2, currentFrame.origin.y, screenBounds.size.height, currentFrame.size.height);
        } else {
            self.tableView.frame = CGRectMake(0, currentFrame.origin.y, self.view.frame.size.width, currentFrame.size.height);
        }
        [self showListEmptyLabel];
        [self stopPlayIfNeed];
        [self.tableView reloadData];
        [self playVideoInVisibleCellsIfNeed];
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)setupSegmentedControl {
    [self.navigationController.view layoutSubviews];
    [self.segmentedControlContainer removeFromSuperview];
    self.segmentedControlContainer = [[UIView alloc] init];
    self.segmentedControlContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.segmentedControlContainer.backgroundColor = (_config && _config.navigationBarTintColor) ? _config.navigationBarTintColor : [UIColor whiteColor];
    [self.navigationController.view addSubview:self.segmentedControlContainer];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems: self.tags];
    [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = _selectedSegmentIndex;
    segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    if (_config && _config.tabSelectedBgColor) {
        segmentedControl.tintColor = _config.tabSelectedBgColor;
    }
    if (_config && _config.tabSelectedTextColor) {
        [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : _config.tabSelectedTextColor} forState:UIControlStateSelected];
    }
    if (_config && _config.tabUnSelectedTextColor) {
        [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : _config.tabUnSelectedTextColor} forState:UIControlStateNormal];
    }
    [self.segmentedControlContainer addSubview:segmentedControl];
    
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat navBarY = self.navigationController.navigationBar.frame.origin.y;
    
    [self.tableView setContentInset:UIEdgeInsetsMake(_topContentOffset, 0, 0, 0)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointMake(0, -(self->_topContentOffset)) animated:NO];
    });
    
    
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
                                 multiplier:1 constant:5] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:-5] setActive:YES];
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
    [self stopPlayIfNeed];
    [self.tableView setContentOffset:CGPointMake(0, -_topContentOffset) animated:NO];
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self.tableView setContentOffset:CGPointMake(0, -_topContentOffset) animated:NO];
    [self playVideoInVisibleCellsIfNeed];
}

- (void)showListEmptyLabel {
    if (self.filterMessages.count <= 0) {
        CGRect frame = self.view.frame;
        if (!self.listEmptyLabel) {
            self.listEmptyLabel = [[UILabel alloc] init];
             self.listEmptyLabel.text = @"No message(s) to show";
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
    NSString *identifier = kCellSimpleMessageIdentifier;
    if ([message.type isEqualToString:kCarouselMessage]) {
        identifier = kCellCarouselMessageIdentifier;
    }
    else if ([message.type isEqualToString:kCarouselImageMessage]) {
        identifier = kCellCarouselImgMessageIdentifier;
    }
    else if ([message.type isEqualToString:kIconMessage]) {
        identifier = kCellIconMessageIdentifier;
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self handleQuickScrollIfNeed];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self handleScrollStopIfNeed];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self handleScrollStopIfNeed];
}

#pragma mark - Video Player Handling

/*
 Video Player Handling
 Inspired in part by https://github.com/newyjp/JPVideoPlayer
 
 MIT License:
 
 Copyright (c) 2016 NewPan
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

-(void)handleMediaPlayingNotification:(NSNotification*)notification {
    CTInboxBaseMessageCell *cell = (CTInboxBaseMessageCell*)notification.object;
    if (!self.playingVideoCell) {
        self.playingVideoCell = cell;
    }
    else if (self.playingVideoCell != cell) {
        [self stopPlayIfNeed];
        self.playingVideoCell = cell;
    }
}

-(void)handleMediaMutedNotification:(NSNotification*)notification {
    self.muted = [notification.userInfo[@"muted"] boolValue];
}

- (void)handleCellUnreachableTypeInVisibleCellsAfterReloadData {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UITableView *tableView = self.tableView;
        for(CTInboxBaseMessageCell *cell in tableView.visibleCells){
            [self handleCellUnreachableTypeForCell:cell atIndexPath:[tableView indexPathForCell:cell]];
        }
    });
}

- (void)handleCellUnreachableTypeForCell:(CTInboxBaseMessageCell *)cell
                             atIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = self.tableView;
    NSArray<UITableViewCell *> *visibleCells = [tableView visibleCells];
    if(!visibleCells.count){
        return;
    }
    
    NSUInteger unreachableCellCount = [self fetchUnreachableCellCountWithVisibleCellsCount:visibleCells.count];
    NSInteger sectionsCount = 1;
    if(tableView.dataSource && [tableView.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]){
        sectionsCount = [tableView.dataSource numberOfSectionsInTableView:tableView];
    }
    BOOL isFirstSectionInSections = YES;
    BOOL isLastSectionInSections = YES;
    if(sectionsCount > 1){
        if(indexPath.section != 0){
            isFirstSectionInSections = NO;
        }
        if(indexPath.section != (sectionsCount - 1)){
            isLastSectionInSections = NO;
        }
    }
    NSUInteger rows = [tableView numberOfRowsInSection:indexPath.section];
    if (unreachableCellCount > 0) {
        if (indexPath.row <= (unreachableCellCount - 1)) {
            if(isFirstSectionInSections){
                cell.unreachableCellType = CTVideoPlayerUnreachableCellTypeTop;
            }
        }
        else if (indexPath.row >= (rows - unreachableCellCount)){
            if(isLastSectionInSections){
                cell.unreachableCellType = CTVideoPlayerUnreachableCellTypeDown;
            }
        }
        else{
            cell.unreachableCellType = CTVideoPlayerUnreachableCellTypeNone;
        }
    }
    else{
        cell.unreachableCellType = CTVideoPlayerUnreachableCellTypeNone;
    }
}

- (void)playVideoInVisibleCellsIfNeed {
    if(self.playingVideoCell){
        [self playVideoWithCell:self.playingVideoCell];
        return;
    }
    [self handleCellUnreachableTypeInVisibleCellsAfterReloadData];
    
    NSArray<CTInboxBaseMessageCell *> *visibleCells = [self.tableView visibleCells];
    CTInboxBaseMessageCell *targetCell = nil;
    for (CTInboxBaseMessageCell *cell in visibleCells) {
        if ([cell hasVideo]) {
            targetCell = cell;
            break;
        }
    }
    if (targetCell) {
        [self playVideoWithCell:targetCell];
    }
}

- (void)stopPlayIfNeed {
    [self.playingVideoCell pause];
    self.playingVideoCell = nil;
}

- (BOOL)viewIsVisibleInVisibleFrameAtScrollViewDidScroll:(UIView *)view {
    return [self viewIsVisibleInTableViewVisibleFrame:view];
}

- (BOOL)playingCellIsVisible {
    if(CGRectIsEmpty(self.tableViewVisibleFrame)){
        return NO;
    }
    if(!self.playingVideoCell){
        return NO;
    }
    return [self viewIsVisibleInTableViewVisibleFrame:self.playingVideoCell];
}

- (BOOL)viewIsVisibleInTableViewVisibleFrame:(UIView *)view {
    CGRect referenceRect = [self.tableView.superview convertRect:self.tableViewVisibleFrame toView:nil];
    CGPoint viewLeftTopPoint = view.frame.origin;
    viewLeftTopPoint.y += 1;
    CGPoint topCoordinatePoint = [view.superview convertPoint:viewLeftTopPoint toView:nil];
    BOOL isTopContain = CGRectContainsPoint(referenceRect, topCoordinatePoint);
    
    CGFloat viewBottomY = viewLeftTopPoint.y + view.bounds.size.height;
    viewBottomY -= 2;
    CGPoint viewLeftBottomPoint = CGPointMake(viewLeftTopPoint.x, viewBottomY);
    CGPoint bottomCoordinatePoint = [view.superview convertPoint:viewLeftBottomPoint toView:nil];
    BOOL isBottomContain = CGRectContainsPoint(referenceRect, bottomCoordinatePoint);
    if(!isTopContain && !isBottomContain){
        return NO;
    }
    return YES;
}

- (CTInboxBaseMessageCell *)findTheBestPlayVideoCell {
    if(CGRectIsEmpty(self.tableViewVisibleFrame)){
        return nil;
    }
    CTInboxBaseMessageCell *targetCell = nil;
    UITableView *tableView = self.tableView;
    NSArray<CTInboxBaseMessageCell *> *visibleCells = [tableView visibleCells];
    
    CGFloat gap = MAXFLOAT;
    CGRect referenceRect = [tableView.superview convertRect:self.tableViewVisibleFrame toView:nil];
    
    for (CTInboxBaseMessageCell *cell in visibleCells) {
        if (![cell hasVideo]) {
            continue;
        }
        
        if (cell.unreachableCellType != CTVideoPlayerUnreachableCellTypeNone) {
            if (cell.unreachableCellType == CTVideoPlayerUnreachableCellTypeTop) {
                CGPoint strategyViewLeftUpPoint = cell.frame.origin;
                strategyViewLeftUpPoint.y += 2;
                CGPoint coordinatePoint = [cell.superview convertPoint:strategyViewLeftUpPoint toView:nil];
                if (CGRectContainsPoint(referenceRect, coordinatePoint)){
                    targetCell = cell;
                    break;
                }
            }
            else if (cell.unreachableCellType == CTVideoPlayerUnreachableCellTypeDown){
                CGPoint strategyViewLeftUpPoint = cell.frame.origin;
                CGFloat strategyViewDownY = strategyViewLeftUpPoint.y + cell.bounds.size.height;
                CGPoint strategyViewLeftDownPoint = CGPointMake(strategyViewLeftUpPoint.x, strategyViewDownY);
                strategyViewLeftDownPoint.y -= 1;
                CGPoint coordinatePoint = [cell.superview convertPoint:strategyViewLeftDownPoint toView:nil];
                if (CGRectContainsPoint(referenceRect, coordinatePoint)){
                    targetCell = cell;
                    break;
                }
            }
        }
        else{
            CGPoint coordinateCenterPoint = [cell.superview convertPoint:cell.center toView:nil];
            CGFloat delta = fabs(coordinateCenterPoint.y - referenceRect.size.height * 0.5 - referenceRect.origin.y);
            if (delta < gap) {
                gap = delta;
                targetCell = cell;
            }
        }
    }
    
    return targetCell;
}

- (NSUInteger)fetchUnreachableCellCountWithVisibleCellsCount:(NSUInteger)visibleCellsCount {
    if(![self.unreachableCellDictionary.allKeys containsObject:[NSString stringWithFormat:@"%d", (int)visibleCellsCount]]){
        return 0;
    }
    return [[self.unreachableCellDictionary valueForKey:[NSString stringWithFormat:@"%d", (int)visibleCellsCount]] intValue];
}

- (NSDictionary<NSString *, NSString *> *)unreachableCellDictionary {
    if(!_unreachableCellDictionary){
        _unreachableCellDictionary = @{
                                       @"4" : @"1",
                                       @"3" : @"1",
                                       @"2" : @"0"
                                       };
    }
    return _unreachableCellDictionary;
}

- (void)playVideoWithCell:(CTInboxBaseMessageCell *)cell {
    if(!cell){
        return;
    }
    self.playingVideoCell = cell;
    [cell mute:self.muted];
    [cell play];
}

- (void)handleQuickScrollIfNeed {
    if (!self.playingVideoCell) {
        return;
    }
    if (![self playingCellIsVisible]) {
        [self stopPlayIfNeed];
    }
}

- (void)handleScrollStopIfNeed {
    CTInboxBaseMessageCell *bestCell = [self findTheBestPlayVideoCell];
    if(!bestCell){
        return;
    }
    
    if(bestCell == self.playingVideoCell){
        return;
    }
    
    [self.playingVideoCell pause];
    [self playVideoWithCell:bestCell];
}

@end
