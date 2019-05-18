//
//  CTWebViewVC.m
//  ObjCStarter
//
//  Created by Aditi Agrawal on 16/05/19.
//  Copyright © 2019 Aditi Agrawal. All rights reserved.
//

#import "CTWebViewVC.h"
#import <WebKit/WebKit.h>
#import <CleverTapSDK/CleverTapJSInterface.h>

@interface CTWebViewVC ()

@property(strong,nonatomic) WKWebView *webView;

@end

@implementation CTWebViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self addWebview];
}

- (void)addWebview {
   
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sampleHTMLCode" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    // Inititialize the Webview and add the CleverTapJSInterface as a script message handler
    CleverTapJSInterface *ctInterface = [[CleverTapJSInterface alloc] initWithConfig:nil];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    [self.webView.configuration.userContentController addScriptMessageHandler:ctInterface name:@"clevertap"];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
