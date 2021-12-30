#import <XCTest/XCTest.h>

XCUIApplication *app;
@interface CleverTapSDKUITests : XCTestCase
@end

@implementation CleverTapSDKUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    app = [[XCUIApplication alloc] init];
    [app launch];
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
}

- (void)test_in_app_alert_shown {
    
    [app/*@START_MENU_TOKEN@*/.staticTexts[@"Request InApp Alert"]/*[[".buttons[@\"Request InApp Alert\"].staticTexts[@\"Request InApp Alert\"]",".staticTexts[@\"Request InApp Alert\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    BOOL alertExists = [app.alerts[@"Alert Title"]waitForExistenceWithTimeout:2.0];
    XCTAssertTrue(alertExists);
}

- (void)test_in_app_interstital_shown {
    
    [app/*@START_MENU_TOKEN@*/.staticTexts[@"Request InApp Interstitial"]/*[[".buttons[@\"Request InApp Interstitial\"].staticTexts[@\"Request InApp Interstitial\"]",".staticTexts[@\"Request InApp Interstitial\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    BOOL interstitalExists = [app.staticTexts[@"Title"] waitForExistenceWithTimeout:2.0] && [app.staticTexts[@"Message"]waitForExistenceWithTimeout:2.0];
    XCTAssertTrue(interstitalExists);
}

- (void)test_app_inbox_shown {
    
    [app/*@START_MENU_TOKEN@*/.staticTexts[@"Show Inbox"]/*[[".buttons[@\"Show Inbox\"].staticTexts[@\"Show Inbox\"]",".staticTexts[@\"Show Inbox\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    
    BOOL inboxExists = [app/*@START_MENU_TOKEN@*/.buttons[@"All"]/*[[".segmentedControls.buttons[@\"All\"]",".buttons[@\"All\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/waitForExistenceWithTimeout:2.0] &&
    [app/*@START_MENU_TOKEN@*/.buttons[@"tag1"]/*[[".segmentedControls.buttons[@\"tag1\"]",".buttons[@\"tag1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ waitForExistenceWithTimeout:2.0] &&
    [app/*@START_MENU_TOKEN@*/.buttons[@"tag2"]/*[[".segmentedControls.buttons[@\"tag2\"]",".buttons[@\"tag2\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ waitForExistenceWithTimeout:2.0] &&
    [app.navigationBars[@"Notifications"].staticTexts[@"Notifications"] waitForExistenceWithTimeout:2.0];
    XCTAssertTrue(inboxExists);
}

@end
