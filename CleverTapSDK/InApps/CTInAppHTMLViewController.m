#import <WebKit/WebKit.h>
#import "CTInAppHTMLViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CleverTapJSInterface.h"
#import "CTInAppResources.h"
#import "CTDismissButton.h"
#import "CTUriHelper.h"

typedef enum {
    kWRSlideStatusNormal = 0,
    kWRSlideStatusLeftExpanded,
    kWRSlideStatusLeftExpanding,
    kWRSlideStatusRightExpanded,
    kWRSlideStatusRightExpanding,
} kWRSlideStatus;

typedef enum {
    WRSlideCellDirectionRight,
    WRSlideCellDirectionLeft,
} WRSlideCellDirection;

#define kMinimumVelocity  webView.frame.size.width*1.5
#define kMinimumPan       60.0
#define kBOUNCE_DISTANCE  0.0

@interface CTInAppHTMLViewController () <WKNavigationDelegate,  UIGestureRecognizerDelegate> {
    WKWebView *webView;
    CTDismissButton *_closeButton;
    kWRSlideStatus _currentStatus;
    CleverTapJSInterface *_jsInterface;
}
    
    @property(nonatomic, strong, readwrite) NSMutableDictionary *notif;
    @property(nonatomic, retain) UIPanGestureRecognizer *panGesture;
    @property(nonatomic, assign) CGFloat initialHorizontalCenter;
    @property(nonatomic, assign) CGFloat initialTouchPositionX;
    
    @property(nonatomic, assign) WRSlideCellDirection lastDirection;
    @property(nonatomic, assign) CGFloat originalCenter;
    
    @property(nonatomic, assign) BOOL revealing;
    
    @end

@implementation CTInAppHTMLViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification jsInterface:(CleverTapJSInterface *)jsInterface {
    self = [super initWithNotification:notification];
    _jsInterface = jsInterface;
    if (self) {
        self.shouldPassThroughTouches = (self.notification.position == CLTAP_INAPP_POSITION_TOP || self.notification.position == CLTAP_INAPP_POSITION_BOTTOM);
    }
    return self;
}
    
- (void)loadView {
    if (self.shouldPassThroughTouches) {
        self.view = [[CTInAppPassThroughView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        CTInAppPassThroughView *view = (CTInAppPassThroughView*)self.view;
        view.delegate = self;
    } else {
        [super loadView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self layoutNotification];
}
    
- (void)layoutNotification {
    _currentStatus = kWRSlideStatusNormal;
    
    // control the initial scale of the WKWebView
    NSString *js = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkScript = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkController = [[WKUserContentController alloc] init];
    [wkController addUserScript:wkScript];
    [wkController addScriptMessageHandler:_jsInterface name:@"clevertap"];
    WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
    wkConfig.userContentController = wkController;
    wkConfig.allowsInlineMediaPlayback = YES;
    webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:wkConfig];
    webView.scrollView.showsHorizontalScrollIndicator = NO;
    webView.scrollView.showsVerticalScrollIndicator = NO;
    webView.scrollView.scrollEnabled = NO;
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.tag = 188293;
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    
    [self loadWebView];
    if (!self.notification.showClose) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
        _panGesture.delegate = self;
        [webView addGestureRecognizer:_panGesture];
    }
}
    
- (void)loadWebView {
    CleverTapLogStaticInternal(@"%@: Loading the web view", [self class]);
    if (self.notification.url) {
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.notification.url]]];
        webView.navigationDelegate = nil;
    } else{
        [webView loadHTMLString:self.notification.html baseURL:nil];
    }
    boolean_t fixedWidth = false, fixedHeight = false;
    
    CGSize size = CGSizeZero;
    if (self.notification.width > 0) {
        // Ignore Constants.INAPP_X_PERCENT
        size.width = self.notification.width;
        fixedWidth = true;
    } else {
        float percent = self.notification.widthPercent;
        size.width = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.width * (percent / 100.0f));
    }
    
    if (self.notification.height > 0) {
        // Ignore Constants.INAPP_X_PERCENT
        size.height = self.notification.height;
        fixedHeight = true;
    } else {
        float percent = self.notification.heightPercent;
        size.height = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.height * (percent / 100.0f));
    }
    
    // prevent webview content insets for Cover
    if (@available(iOS 11.0, *)) {
        if (self.notification.heightPercent == 100.0) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    
    CleverTapLogStaticInternal(@"%@: In-app notification size: %f x %f", [self class], size.width, size.height);
    
    CGRect frame = webView.frame;
    frame.size = size;
    webView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    char pos = self.notification.position;
    CGFloat statusBarHeight = self.notification.heightPercent == 100.0 ? [[CTInAppResources getSharedApplication] statusBarFrame].size.height : 0.0;

    int extra = (int) (self.notification.showClose ? (self.notification.heightPercent == 100.0 ? (CLTAP_INAPP_CLOSE_IV_WIDTH) :  CLTAP_INAPP_CLOSE_IV_WIDTH / 2.0f) : 0.0f);
    switch (pos) {
        case CLTAP_INAPP_POSITION_TOP:
        frame.origin.x = (screenSize.width - size.width) / 2.0f;//-extra;
        frame.origin.y = 0.0f + extra + 20.0f;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
        break;
        case CLTAP_INAPP_POSITION_LEFT:
        frame.origin.x = 0.0f;
        frame.origin.y = (screenSize.height - size.height) / 2.0f;//+extra;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleRightMargin;
        break;
        case CLTAP_INAPP_POSITION_BOTTOM:
        frame.origin.x = (screenSize.width - size.width) / 2.0f;//-extra;
        frame.origin.y = screenSize.height - size.height;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
        break;
        case CLTAP_INAPP_POSITION_RIGHT:
        frame.origin.x = screenSize.width - size.width - extra;
        frame.origin.y = (screenSize.height - size.height) / 2.0f;//+extra;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleLeftMargin;
        break;
        case CLTAP_INAPP_POSITION_CENTER:
        frame.origin.x = (screenSize.width - size.width) / 2.0f;//-extra;
        frame.origin.y = (screenSize.height - size.height) / 2.0f;//+extra;
        break;
        default:
        CleverTapLogStaticInternal(@"Unknown position %c", pos);
        return;
    }
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    webView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    if (self.notification.darkenScreen) {
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    }
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    if (self.notification.showClose) {
        _closeButton = [CTDismissButton new];
        [_closeButton addTarget:self action:@selector(tappedDismiss) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.frame = CGRectMake(frame.origin.x + frame.size.width - extra, self.notification.heightPercent == 100.0 ? statusBarHeight : (frame.origin.y - extra), CLTAP_INAPP_CLOSE_IV_WIDTH, CLTAP_INAPP_CLOSE_IV_WIDTH);
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:_closeButton];
    }
    if (!fixedWidth) {
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
    }
    if (!fixedHeight) {
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}
    
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
    
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    CleverTapLogStaticInternal(@"%@: Navigation request: %@", [self class], navigationAction.request.URL);
    
    if (navigationAction.request.URL == nil || [[navigationAction.request.URL absoluteString] isEqualToString:@"about:blank"] || [self isInlineMedia:navigationAction.request.URL]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary new];
    NSString *urlString = [navigationAction.request.URL absoluteString];
    NSURL *dl = [NSURL URLWithString:urlString];
    
    // Try to extract the parameters from the URL and overrite default dl if applicable
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSArray *comps = [urlString componentsSeparatedByString:@"?"];
    if ([comps count] >= 2) {
        NSString *query = comps[1];
        for (NSString *param in [query componentsSeparatedByString:@"&"]) {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if ([elts count] < 2) continue;
            params[elts[0]] = [elts[1] stringByRemovingPercentEncoding];
        };
        mutableParams = [params mutableCopy];
        NSString *c2a = params[@"wzrk_c2a"];
        if (c2a) {
            c2a = [c2a stringByRemovingPercentEncoding];
            NSArray *parts = [c2a componentsSeparatedByString:@"__dl__"];
            if (parts && [parts count] == 2) {
                dl = [NSURL URLWithString:parts[1]];
                mutableParams[@"wzrk_c2a"] = parts[0];
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleNotificationCTA:buttonCustomExtras:forNotification:fromViewController:withExtras:)]) {
        [self.delegate handleNotificationCTA:dl buttonCustomExtras:nil forNotification:self.notification fromViewController:self withExtras:mutableParams];
    } else {
        [self hide:YES];
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    
}

- (BOOL)isInlineMedia:(NSURL *)url {
   NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", @"playsinline"];
   NSArray *queryItems = urlComponents.queryItems;
   if ([queryItems count] == 0) return NO;
   NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];
   NSString *value = queryItem.value;
   return value.boolValue;
   return NO;
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)recognizer {
    //begin pan...
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialTouchPositionX = [recognizer locationInView:self.view].x;
        self.initialHorizontalCenter = webView.center.x;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) { //status change
        
        CGFloat panAmount = _initialTouchPositionX - [recognizer locationInView:self.view].x;
        CGFloat newCenterPosition = _initialHorizontalCenter - panAmount;
        CGFloat centerX = webView.center.x;
        
        if (centerX > _originalCenter && _currentStatus != kWRSlideStatusLeftExpanding) {
            _currentStatus = kWRSlideStatusLeftExpanding;
        }
        else if (centerX < _originalCenter && _currentStatus != kWRSlideStatusRightExpanding) {
            _currentStatus = kWRSlideStatusRightExpanding;
        }
        
        if (panAmount > 0) {
            _lastDirection = WRSlideCellDirectionLeft;
        }
        else {
            _lastDirection = WRSlideCellDirectionRight;
        }
        
        if (newCenterPosition > self.view.bounds.size.width + webView.bounds.size.width) {
            newCenterPosition = self.view.bounds.size.width + webView.bounds.size.width;
        }
        else if (newCenterPosition < -webView.bounds.size.width) {
            newCenterPosition = -webView.bounds.size.width;
        }
        CGPoint center = webView.center;
        center.x = newCenterPosition;
        webView.layer.position = center;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded ||
             recognizer.state == UIGestureRecognizerStateCancelled) {
        
        CGPoint translation = [recognizer translationInView:self.view];
        CGFloat velocityX = [recognizer velocityInView:self.view].x;
        
        BOOL isNeedPush = (fabs(velocityX) > kMinimumVelocity);
        
        isNeedPush |= ((_lastDirection == WRSlideCellDirectionLeft && translation.x < -kMinimumPan) ||
                       (_lastDirection == WRSlideCellDirectionRight && translation.x > kMinimumPan));
        
        if (velocityX > 0 && _lastDirection == WRSlideCellDirectionLeft) {
            isNeedPush = NO;
        }
        
        else if (velocityX < 0 && _lastDirection == WRSlideCellDirectionRight) {
            isNeedPush = NO;
        }
        
        if (isNeedPush && !self.revealing) {
            
            if (_lastDirection == WRSlideCellDirectionRight) {
                _currentStatus = kWRSlideStatusLeftExpanding;
            }
            else {
                _currentStatus = kWRSlideStatusRightExpanding;
            }
            [self _slideOutContentViewInDirection:_lastDirection];
            [self _setRevealing:YES];
        }
        else if (self.revealing && translation.x != 0) {
            WRSlideCellDirection direct = _currentStatus == kWRSlideStatusRightExpanding ? WRSlideCellDirectionLeft : WRSlideCellDirectionRight;
            
            [self _slideInContentViewFromDirection:direct];
            [self _setRevealing:NO];
        }
        else if (translation.x != 0) {
            // Figure out which side we've dragged on.
            WRSlideCellDirection finalDir = WRSlideCellDirectionRight;
            if (translation.x < 0)
            finalDir = WRSlideCellDirectionLeft;
            [self _slideInContentViewFromDirection:finalDir];
            [self _setRevealing:NO];
        }
    }
}
    
#pragma mark - revealing setter
    
- (void)setRevealing:(BOOL)revealing {
    if (_revealing == revealing) {
        return;
    }
    [self _setRevealing:revealing];
    
    if (self.revealing) {
        [self _slideOutContentViewInDirection:_lastDirection];
    } else {
        [self _slideInContentViewFromDirection:_lastDirection];
    }
}
    
- (void)_setRevealing:(BOOL)revealing {
    _revealing = revealing;
}
    
#pragma mark - ContentView Sliding
    
- (void)_slideInContentViewFromDirection:(WRSlideCellDirection)direction {
    CGFloat bounceDistance;
    
    if (webView.center.x == _originalCenter)
    return;
    
    switch (direction) {
        case WRSlideCellDirectionRight:
        bounceDistance = kBOUNCE_DISTANCE;
        break;
        case WRSlideCellDirectionLeft:
        bounceDistance = (CGFloat) -kBOUNCE_DISTANCE;
        break;
        default:
        break;
    }
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self->webView.center = CGPointMake(self->_originalCenter, self->webView.center.y);
                     }
                     completion:^(BOOL f) {
                         [UIView animateWithDuration:0.1 delay:0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self->webView.frame = CGRectOffset(self->webView.frame, bounceDistance, 0);
                                          }
                                          completion:^(BOOL f2) {
                                              [UIView animateWithDuration:0.1 delay:0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self->webView.frame = CGRectOffset(self->webView.frame, -bounceDistance, 0);
                                                               }
                                                               completion:^(BOOL f1) {
                                                                   self->_currentStatus = kWRSlideStatusNormal;
                                                               }];
                                          }];
                     }];
}
    
- (void)_slideOutContentViewInDirection:(WRSlideCellDirection)direction; {
    CGFloat newCenterX;
    CGFloat bounceDistance;
    switch (direction) {
        case WRSlideCellDirectionLeft: {
            newCenterX = -webView.bounds.size.width;
            bounceDistance = (CGFloat) -kBOUNCE_DISTANCE;
            _currentStatus = kWRSlideStatusLeftExpanded;
        }
        break;
        case WRSlideCellDirectionRight: {
            newCenterX = self.view.bounds.size.width + webView.bounds.size.width;
            bounceDistance = kBOUNCE_DISTANCE;
            _currentStatus = kWRSlideStatusRightExpanded;
        }
        break;
        default:
        break;
    }
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self->webView.center = CGPointMake(newCenterX, self->webView.center.y);
                     }
                     completion:^(BOOL f) {
                         [UIView animateWithDuration:0.1 delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self->webView.frame = CGRectOffset(self->webView.frame, -bounceDistance, 0);
                                          }
                                          completion:^(BOOL f1) {
                                              [UIView animateWithDuration:0.1 delay:0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self->webView.frame = CGRectOffset(self->webView.frame, bounceDistance, 0);
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [self hide:NO];
                                                               }];
                                          }];
                     }];
}
    
#pragma mark - UIGestureRecognizerDelegate
    
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _panGesture) {
        UIScrollView *superview = (UIScrollView *) self.view.superview;
        CGPoint translation = [(UIPanGestureRecognizer *) gestureRecognizer translationInView:superview];
        // Make it scrolling horizontally
        return fabs(translation.x) / fabs(translation.y) > 1;
    }
    return YES;
}
    
- (void)showFromWindow:(BOOL)animated {
    if (!self.notification) return;
    Class windowClass = self.shouldPassThroughTouches ? CTInAppPassThroughWindow.class : UIWindow.class;
    self.window = [[windowClass alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.window.alpha = 0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window setHidden:NO];
    
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidShow:fromViewController:)]) {
            [self.delegate notificationDidShow:self.notification fromViewController:self];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 1.0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}
    
-(void)hideFromWindow:(BOOL)animated {
    void (^completionBlock)(void) = ^ {
        [self.window removeFromSuperview];
        self.window = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidDismiss:fromViewController:)]) {
            [self.delegate notificationDidDismiss:self.notification fromViewController:self];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}
    
#pragma mark - Public
    
-(void)show:(BOOL)animated {
    if (!self.notification.html) return;
    [self showFromWindow:animated];
}
    
-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
