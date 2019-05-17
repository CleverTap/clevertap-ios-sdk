#import "CTAlertViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTInAppResources.h"

@interface CTAlertViewController ()

@end

@implementation CTAlertViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
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
    
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.window.alpha = 0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window makeKeyAndVisible];
    [self.window setHidden:NO];
    
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidShow:fromViewController:)]) {
            [self.delegate notificationDidShow:self.notification fromViewController:self];
        }
    };

    self.window.alpha = 1.0;
    completionBlock();
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
