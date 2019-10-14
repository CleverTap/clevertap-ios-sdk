//
//  ViewController.m
//  testTVOS
//
//  Created by Peter Wilkniss on 6/26/18.
//  Copyright © 2018 Peter Wilkniss. All rights reserved.
//

#import "ViewController.h"
@import CleverTapSDK;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[CleverTap sharedInstance] recordEvent:@"testEventFromTVOS2"];

    // Do any additional setup after loading the view, typically from a nib.
    [CleverTap getLocationWithSuccess:^(CLLocationCoordinate2D location) {
        NSLog(@"location success: %f %f", location.latitude, location.longitude);
    } andError:^(NSString *error) {
        NSLog(@"location error: %@", error);
    }];
}


@end
