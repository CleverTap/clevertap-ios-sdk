//
//  CTTriggerOperator.h
//  CleverTapSDK
//
//  Copyright © 2023 CleverTap. All rights reserved.
//
//  Operator codes for a trigger property condition. Extracted from CTTriggerCondition.h
//  when CTTriggerCondition was migrated to Swift. The enum stays in Objective-C because
//  it is used as a method-parameter type in CTTriggerEvaluator.h (an Objective-C header)
//  and must remain an open integer type: unknown, server-sent operator codes are stored
//  verbatim on CTTriggerCondition and routed to "no match" by CTTriggerEvaluator's switch
//  default — behaviour a sealed Swift @objc enum could not represent.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CTTriggerOperator){
    CTTriggerOperatorGreaterThan = 0,
    CTTriggerOperatorEquals = 1,
    CTTriggerOperatorLessThan = 2,
    CTTriggerOperatorContains = 3,
    CTTriggerOperatorBetween = 4,
    CTTriggerOperatorNotEquals = 15,
    CTTriggerOperatorSet = 26, // Exists
    CTTriggerOperatorNotSet = 27, // Not exists
    CTTriggerOperatorNotContains = 28,
};
