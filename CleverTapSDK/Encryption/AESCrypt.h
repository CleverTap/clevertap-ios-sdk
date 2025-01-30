//
//  AESCrypt.h
//  Pods
//
//  Created by Kushagra Mishra on 29/01/25.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface AESCrypt : NSObject

+ (NSData *)AES128WithOperation:(CCOperation)operation
                            key:(NSString *)key
                     identifier:(NSString *)identifier
                           data:(NSData *)data;

@end
