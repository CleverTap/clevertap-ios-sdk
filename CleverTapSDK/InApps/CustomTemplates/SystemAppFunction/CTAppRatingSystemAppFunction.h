//
//  CTAppRatingSystemAppFunction.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 28/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTAppRatingSystemAppFunction_h
#define CTAppRatingSystemAppFunction_h
#import "CTCustomTemplate.h"
#import "CTSystemTemplateActionHandler.h"

@interface CTAppRatingSystemAppFunction : NSObject

+ (CTCustomTemplate *)buildTemplateWithHanlder:(CTSystemTemplateActionHandler *)systemTemplateActionHandler;

@end


#endif /* CTAppRatingSystemAppFunction_h */
