//   Based in part on Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>

typedef NS_ENUM(unsigned int, CTWebSocketReadyState) {
    CTWebSocketStateConnecting = 0,
    CTWebSocketStateOpen = 1,
    CTWebSocketStateClosing = 2,
    CTWebSocketStateClosed = 3,
};

@class CTWebSocket;

extern NSString *const CTWebSocketErrorDomain;

#pragma mark - CTWebSocketDelegate

@protocol CTWebSocketDelegate;

#pragma mark - CTWebSocket

@interface CTWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, assign) id <CTWebSocketDelegate> delegate;

@property (nonatomic, readonly) CTWebSocketReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (instancetype)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (instancetype)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (instancetype)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (instancetype)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue*) queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t) queue;

// By default, it will schedule itself on +[NSRunLoop mp_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// CTWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

@end

#pragma mark - CTWebSocketDelegate

@protocol CTWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(CTWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(CTWebSocket *)webSocket;
- (void)webSocket:(CTWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(CTWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end

#pragma mark - NSURLRequest (CTCertificateAdditions)

@interface NSURLRequest (CTCertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *CT_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (CTCertificateAdditions)

@interface NSMutableURLRequest (CTCertificateAdditions)

@property (nonatomic, retain) NSArray *CT_SSLPinnedCertificates;

@end

#pragma mark - NSRunLoop (SRWebSocket)

@interface NSRunLoop (CTWebSocket)

+ (NSRunLoop *)CT_networkRunLoop;

@end
