#import "CTAlertViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTUIUtils.h"

@interface CTAlertViewController ()

@end

@implementation CTAlertViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super initWithNotification:notification];
    if (self) {
        self.notification = notification;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self dismissViewControllerAnimated:YES completion:nil];
    self.view.backgroundColor = [UIColor clearColor];
    [self setupDialogNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Setup Notification

- (void)setupDialogNotification {
    
    UIAlertController *dialogBox = [UIAlertController
                                    alertControllerWithTitle: self.notification.title
                                    message: self.notification.message
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    if (self.notification.buttons && self.notification.buttons.count > 0) {
        
        //Add Buttons
        UIAlertAction *firstButton = [UIAlertAction
                                      actionWithTitle:self.notification.buttons[0].text
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * action) {
            [self handleAlertButtonClickFromIndex:0];
        }];
        
        [dialogBox addAction:firstButton];
        
        if (self.notification.buttons.count == 2) {
            
            UIAlertAction *secondButton = [UIAlertAction
                                           actionWithTitle:self.notification.buttons[1].text
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                [self handleAlertButtonClickFromIndex:1];
            }];
            
            [dialogBox addAction:secondButton];
        } else if (self.notification.buttons.count == 3) {
            
            UIAlertAction *secondButton = [UIAlertAction
                                           actionWithTitle:self.notification.buttons[1].text
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                [self handleAlertButtonClickFromIndex:1];
            }];
            
            [dialogBox addAction:secondButton];
            
            UIAlertAction *thirdButton = [UIAlertAction
                                          actionWithTitle:self.notification.buttons[2].text
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * action) {
                [self handleAlertButtonClickFromIndex:2];
            }];
            
            [dialogBox addAction:thirdButton];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:dialogBox animated:YES completion:nil];
    });
}

- (void)handleAlertButtonClickFromIndex:(int)index {
    [self handleButtonClickFromIndex:index];
    [self hide:true];
}

- (void)showFromWindow:(BOOL)animated {

    if (!self.notification) return;

#if TARGET_OS_TV
    [self showAlertFromTopViewController];
#else
    if (@available(iOS 13, *)) {
        NSSet *connectedScenes = [CTUIUtils getSharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                self.window = [[UIWindow alloc] initWithFrame:
                               windowScene.coordinateSpace.bounds];
                self.window.windowScene = windowScene;
            }
        }
    } else {
        self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    self.window.alpha = 0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window makeKeyAndVisible];
    [self.window setHidden:NO];

    void (^completionBlock)(void) = ^ {
        if (self.delegate) {
            [self.delegate notificationDidShow:self.notification];
        }
    };

    self.window.alpha = 1.0;
    completionBlock();
#endif
}

#if TARGET_OS_TV
- (void)showAlertFromTopViewController {

    UIViewController *topVC = [self topViewController];
    if (!topVC) {
        [self hide:NO];
        return;
    }

    UIAlertController *dialogBox = [UIAlertController
                                    alertControllerWithTitle:self.notification.title
                                    message:self.notification.message
                                    preferredStyle:UIAlertControllerStyleAlert];

    if (self.notification.buttons && self.notification.buttons.count > 0) {
        for (NSUInteger i = 0; i < self.notification.buttons.count && i < 3; i++) {
            NSUInteger index = i;
            UIAlertAction *button = [UIAlertAction
                                     actionWithTitle:self.notification.buttons[i].text
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action) {
                [self handleAlertButtonClickFromIndex:(int)index];
            }];
            [dialogBox addAction:button];
        }
    } else {
        NSLog(@"[CT-tvOS] No buttons on notification");
    }

    if (self.delegate) {
        [self.delegate notificationDidShow:self.notification];
    }

    [topVC presentViewController:dialogBox animated:YES completion:^{
        NSLog(@"[CT-tvOS] Alert presentation completed");
    }];
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    keyWindow = [CTUIUtils getSharedApplication].keyWindow;
#pragma clang diagnostic pop

    if (!keyWindow) {
        if (@available(tvOS 13.0, *)) {
            NSSet *scenes = [CTUIUtils getSharedApplication].connectedScenes;
            for (UIScene *scene in scenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                    if (keyWindow) break;
                }
            }
        }
    }

    if (!keyWindow) {
        return nil;
    }

    UIViewController *topVC = keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}
#endif


#pragma mark - Public

- (void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

- (void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
