//
// Created by Jude Pereira on 21/11/2015.
// Copyright (c) 2015 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CleverTapSyncDelegate <NSObject>

@required

/*!
 
 @abstract 
 The `CleverTapSyncDelegate` protocol provides an additional/alternative method for
 notifying your application (the adopting delegate) about synchronization-related changes to the User Profile/Event History.
 
 @discussion
 the updates argument represents the changed data and is of the form:
    {
        "profile":{"<property1>":{"oldValue":<value>, "newValue":<value>}, ...},
        "events:{"<eventName>":
            {"count":
                {"oldValue":(int)<old count>, "newValue":<new count>},
            "firstTime":
                {"oldValue":(double)<old first time event occurred>, "newValue":<new first time event occurred>},
            "lastTime":
                {"oldValue":(double)<old last time event occurred>, "newValue":<new last time event occurred>},
            }, ...
        }
    }
 
 */

- (void)profileDataUpdated:(NSDictionary*)updates;

@end