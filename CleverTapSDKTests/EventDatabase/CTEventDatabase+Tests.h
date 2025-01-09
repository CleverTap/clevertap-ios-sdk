//
//  CTEventDatabase+Tests.h
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 09/01/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTEventDatabase_Tests_h
#define CTEventDatabase_Tests_h

#import "CTEventDatabase.h"

@interface CTEventDatabase(Tests)

- (instancetype)initWithDispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager
                                       clock:(id<CTClock>)clock;

@end


#endif /* CTEventDatabase_Tests_h */
