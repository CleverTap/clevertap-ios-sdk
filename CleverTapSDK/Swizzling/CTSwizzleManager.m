//
//  CTSwizzleManager.m
//  Pods
//
//  Created by Akash Malhotra on 27/06/23.
//

#import "CTSwizzleManager.h"
#import "CTUtils.h"
#import "CTUIUtils.h"
#import <objc/runtime.h>
#import <UserNotifications/UserNotifications.h>
#import "CTSwizzle.h"
#import "CleverTapInternal.h"
#import "CTConstants.h"

@implementation CTSwizzleManager

+ (void)swizzleAppDelegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIApplication *sharedApplication = [CTUIUtils getSharedApplication];
        if (sharedApplication == nil) {
            return;
        }
        
        __strong id appDelegate = [sharedApplication delegate];
        Class cls = [sharedApplication.delegate class];
        SEL sel;
        
        // Token Handling
        sel = NSSelectorFromString(@"application:didFailToRegisterForRemoteNotificationsWithError:");
        if (!class_getInstanceMethod(cls, sel)) {
            SEL newSel = @selector(ct_application:didFailToRegisterForRemoteNotificationsWithError:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        } else {
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSError *error) {
                [self ct_application:application didFailToRegisterForRemoteNotificationsWithError:error];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&error atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        }
        
        sel = NSSelectorFromString(@"application:didRegisterForRemoteNotificationsWithDeviceToken:");
        if (!class_getInstanceMethod(cls, sel)) {
            SEL newSel = @selector(ct_application:didRegisterForRemoteNotificationsWithDeviceToken:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        } else {
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSData *token) {
                [self ct_application:application didRegisterForRemoteNotificationsWithDeviceToken:token];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&token atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        }
        
        // Notification Handling
#if !defined(CLEVERTAP_TVOS)
        if (@available(iOS 10.0, *)) {
            Class ncdCls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if ([UNUserNotificationCenter class] && !ncdCls) {
                [[UNUserNotificationCenter currentNotificationCenter] addObserver:[CleverTap sharedInstance] forKeyPath:@"delegate" options:0 context:nil];
            } else {
                if (class_getInstanceMethod(ncdCls, NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))) {
                    sel = NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
                    __block NSInvocation *invocation = nil;
                    invocation = [ncdCls ct_swizzleMethod:sel withBlock:^(id obj, UNUserNotificationCenter *center, UNNotificationResponse *response, void (^completion)(void) ) {
                        [CleverTap handlePushNotification:response.notification.request.content.userInfo openDeepLinksInForeground:YES];
                        [invocation setArgument:&center atIndex:2];
                        [invocation setArgument:&response atIndex:3];
                        [invocation setArgument:&completion atIndex:4];
                        [invocation invokeWithTarget:obj];
                    } error:nil];
                }
                [CTSwizzleManager swizzleWillPresentOnClass:ncdCls];
            }
        }
        if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:"))) {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSDictionary *userInfo, void (^completion)(UIBackgroundFetchResult result) ) {
                [CleverTap handlePushNotification:userInfo openDeepLinksInForeground:NO];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation setArgument:&completion atIndex:4];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:didReceiveRemoteNotification:"))) {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSDictionary *userInfo) {
                [CleverTap handlePushNotification:userInfo openDeepLinksInForeground:NO];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
            SEL newSel = @selector(ct_application:didReceiveRemoteNotification:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        }
#endif
        
        // URL handling
        if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:openURL:sourceApplication:annotation:"))) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
            sel = NSSelectorFromString(@"application:openURL:sourceApplication:annotation:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSURL *url, NSString *sourceApplication, id annotation ) {
                [[self class] ct_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&sourceApplication atIndex:4];
                [invocation setArgument:&annotation atIndex:5];
                [invocation invokeWithTarget:obj];
            } error:nil];
#endif
        } else if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:openURL:options:"))) {
            sel = NSSelectorFromString(@"application:openURL:options:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSURL *url, NSDictionary<UIApplicationOpenURLOptionsKey, id> *options ) {
                [[self class] ct_application:application openURL:url options:options];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&options atIndex:4];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else {
            if (@available(iOS 9.0, *)) {
                sel = NSSelectorFromString(@"application:openURL:options:");
                SEL newSel = @selector(ct_application:openURL:options:);
                Method newMeth = class_getClassMethod([self class], newSel);
                IMP imp = method_getImplementation(newMeth);
                const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
                class_addMethod(cls, sel, imp, methodTypeEncoding);
            } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
                sel = NSSelectorFromString(@"application:openURL:sourceApplication:annotation:");
                SEL newSel = @selector(ct_application:openURL:sourceApplication:annotation:);
                Method newMeth = class_getClassMethod([self class], newSel);
                IMP imp = method_getImplementation(newMeth);
                const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
                class_addMethod(cls, sel, imp, methodTypeEncoding);
#endif
            }
            // UIApplication caches whether or not the delegate responds to certain selectors. Clearing out the delegate and resetting it gaurantees that gets updated
            [sharedApplication setDelegate:nil];
            // UIApplication won't assume ownership of AppDelegate for setDelegate calls add a retain here
            [sharedApplication setDelegate:(__bridge id)CFRetain((__bridge CFTypeRef)appDelegate)];
        }
    });
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
#if !defined(CLEVERTAP_TVOS)
+ (BOOL)ct_application:(UIApplication *)application
               openURL:(NSURL *)url
     sourceApplication:(NSString *)sourceApplication
            annotation:(id)annotation {
    CleverTapLogStaticDebug(@"Handling openURL:sourceApplication: %@", url);
    [CleverTap handleOpenURL:url];
    return NO;
}
#endif
#endif
+ (BOOL)ct_application:(UIApplication *)application
               openURL:(NSURL *)url
               options:(NSDictionary<NSString*, id> *)options {
    CleverTapLogStaticDebug(@"Handling openURL:options: %@", url);
    [CleverTap handleOpenURL:url];
    return NO;
}

+ (void)ct_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [CTUtils deviceTokenStringFromData:deviceToken];
    if (![CleverTap getInstances] || [[CleverTap getInstances] count] <= 0) {
        [[CleverTap sharedInstance] setPushTokenAsString:deviceTokenString];
        return;
    }
    for (CleverTap *instance in [[CleverTap getInstances] allValues]) {
        [instance setPushTokenAsString:deviceTokenString];
    }
}
+ (void)ct_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    CleverTapLogStaticDebug(@"Application failed to register for remote notification: %@", error);
}
+ (void)ct_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [CleverTap handlePushNotification:userInfo openDeepLinksInForeground:NO];
}

+ (void)swizzleWillPresentOnClass:(Class)cls {
    if (!cls) return;
#if !defined(CLEVERTAP_TVOS)
    if (@available(iOS 10.0, *)) {
        SEL willPresentSel = NSSelectorFromString(@"userNotificationCenter:willPresentNotification:withCompletionHandler:");
        Method willPresentMethod = class_getInstanceMethod(cls, willPresentSel);
        if (!willPresentMethod) return;

        // Capture the original IMP as a typed C function pointer to avoid
        // passing blocks through NSInvocation (which bypasses ARC and can
        // cause crashes with stack-allocated completion handler wrappers).
        IMP originalIMP = method_getImplementation(willPresentMethod);
        typedef void (*WillPresentIMP)(id, SEL, UNUserNotificationCenter *, UNNotification *, void (^)(UNNotificationPresentationOptions));

        IMP newIMP = imp_implementationWithBlock(^(id obj,
                                                    UNUserNotificationCenter *center,
                                                    UNNotification *notification,
                                                    void (^completion)(UNNotificationPresentationOptions)) {
            NSDictionary *userInfo = notification.request.content.userInfo;
            BOOL isCTPush = [[CleverTap sharedInstance] isCleverTapNotification:userInfo];
            BOOL silentInForeground = isCTPush && [userInfo[CLTAP_NOTIFICATION_SILENT_IN_FOREGROUND] boolValue];

            if (silentInForeground) {
                void (^wrappedCompletion)(UNNotificationPresentationOptions) = ^(UNNotificationPresentationOptions options) {
                    if (@available(iOS 14.0, *)) {
                        completion(UNNotificationPresentationOptionList);
                    } else {
                        completion(UNNotificationPresentationOptionNone);
                    }
                };
                ((WillPresentIMP)originalIMP)(obj, willPresentSel, center, notification, wrappedCompletion);
            } else {
                ((WillPresentIMP)originalIMP)(obj, willPresentSel, center, notification, completion);
            }
        });

        const char *typeEncoding = method_getTypeEncoding(willPresentMethod);
        if (!class_addMethod(cls, willPresentSel, newIMP, typeEncoding)) {
            method_setImplementation(willPresentMethod, newIMP);
        }
    }
#endif
}

@end
