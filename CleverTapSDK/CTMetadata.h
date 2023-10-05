//
//  CTMetadata.h
//  Pods
//
//  Created by Akash Malhotra on 04/07/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTMetadata : NSObject

- (NSDictionary*)wzrkParams;
- (void)setWzrkParams:(NSDictionary *)params;
- (void)clearWzrkParams;

@end

NS_ASSUME_NONNULL_END
