# User Event Logging APIs

CleverTap iOS SDK 7.1.0 and above provides following new APIs to track user level event logging. Be sure to call enablePersonalization (typically once at app launch) prior to using this method. These API call involves a database query and we recommend to call API from background thread like shown below.

#### Objective-C
```objc
// Call the method from a background thread
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // To get count of times an event occurred
    int eventCount = [[CleverTap sharedInstance] getUserEventLogCount:@"Product viewed"];
    NSLog(@"eventCount: %ld", (long)eventCount);
});
```

#### Swift
```swift
// Call the method from a background thread
DispatchQueue.global(qos: .background).async {
    // To get count of times an event occurred
    let eventCount = CleverTap.sharedInstance()?.getUserEventLogCount("Product viewed")
    print("Event count: \(String(describing: eventCount))")
}
```

## Get user event details
#### Objective-C
```objc
CleverTapEventDetail *event = [[CleverTap sharedInstance] getUserEventLog:@"Product viewed"];
if (event) {
    NSString *eventName = event.eventName;
    NSTimeInterval firstTime = event.firstTime;
    NSTimeInterval lastTime = event.lastTime;
    NSInteger eventCount = event.count;
    NSString *deviceId = event.deviceID;
    NSLog(@"eventName: %@, firstTime: %f, lastTime: %f, count: %ld, deviceID: %@", eventName, firstTime, lastTime, (long)eventCount, deviceId);
} else {
    NSLog(@"Event not exists");
}
```

#### Swift
```swift
let event: CleverTapEventDetail? = CleverTap.sharedInstance()?.getUserEventLog("Product viewed")
if let event = event {
    let eventName: String = event.eventName
    let firstTime: Double = event.firstTime
    let lastTime: Double = event.lastTime
    let count: UInt = event.count
    let deviceID: String = event.deviceID
    print("Event name: \(eventName), first time: \(firstTime), last time: \(lastTime), count: \(count), device id: \(deviceID)")
} else {
    print("Event not exists")
}
```

## Get count of event occurrences
#### Objective-C
```objc
int eventCount = [[CleverTap sharedInstance] getUserEventLogCount:@"Product viewed"];
NSLog(@"Event count: %ld", (long)eventCount);
```

#### Swift
```swift
let eventCount = CleverTap.sharedInstance()?.getUserEventLogCount("Product viewed")
print("Event count: \(String(describing: eventCount))")
```

## Get full event history for user
#### Objective-C
```objc
NSDictionary<NSString *, CleverTapEventDetail *> *allEvents = [[CleverTap sharedInstance] getUserEventLogHistory];
for (NSString *key in allEvents) {
    NSString *eventName = allEvents[key].eventName;
    NSTimeInterval firstTime = allEvents[key].firstTime;
    NSTimeInterval lastTime = allEvents[key].lastTime;
    NSInteger eventCount = allEvents[key].count;
    NSString *deviceId = allEvents[key].deviceID;
    NSLog(@"Event name: %@, firstTime: %f, lastTime: %f, count: %ld, deviceID: %@", eventName, firstTime, lastTime, (long)eventCount, deviceId);
}
```

#### Swift
```swift
let allEvents = CleverTap.sharedInstance()?.getUserEventLogHistory()
if let allEvents = allEvents {
    for eventDetails in allEvents.values {
        let eventDetails: CleverTapEventDetail = eventDetails as! CleverTapEventDetail
        let eventName: String = eventDetails.eventName
        let firstTime: Double = eventDetails.firstTime
        let lastTime: Double = eventDetails.lastTime
        let count: UInt = eventDetails.count
        let deviceID: String = eventDetails.deviceID
        print("Event name: \(eventName), first time: \(firstTime), last time: \(lastTime), count: \(count), device id: \(deviceID)")
    }
} else {
    print("No events found")
}
```

## Get total number of app launches by user
#### Objective-C
```objc
int appLaunchCount = [[CleverTap sharedInstance] getUserAppLaunchCount];
NSLog(@"App launched count: %d", appLaunchCount);
```

#### Swift
```swift
let appLaunchCount = CleverTap.sharedInstance()?.getUserAppLaunchCount()
print("App launched count: \(String(describing: appLaunchCount))")
```

## Get user last app visit timestamp
#### Objective-C
```objc
NSTimeInterval lastVisit = [[CleverTap sharedInstance] getUserLastVisitTs];
NSLog(@"User last visit timestamp: %f", lastVisit);
```

#### Swift
```swift
let userLastVisit = CleverTap.sharedInstance()?.getUserLastVisitTs()
print("User last visit timestamp: \(String(describing: userLastVisit))")
```
