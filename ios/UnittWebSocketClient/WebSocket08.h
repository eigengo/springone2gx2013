//
//  WebSocket08.h
//  UnittWebSocketClient
//
//  Created by Josh Morris on 5/3/11.
//  Copyright 2011 UnitT Software. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License. You may obtain a copy of
//  the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "NSData+Base64.h"
#import "MutableQueue.h"


enum 
{
    WebSocketCloseStatusNormal = 1000, //indicates a normal closure, meaning whatever purpose the 
                                       //connection was established for has been fulfilled
    WebSocketCloseStatusEndpointGone = 1001, //indicates that an endpoint is "going away", such as a 
                                             //server going down, or a browser having navigated away from 
                                             //a page
    WebSocketCloseStatusProtocolError = 1002, //indicates that an endpoint is terminating the connection 
                                              //due to a protocol error
    WebSocketCloseStatusInvalidDataType = 1003, //indicates that an endpoint is terminating the connection
                                                //because it has received a type of data it cannot accept 
                                                //(e.g. an endpoint that understands only text data MAY 
                                                //send this if it receives a binary message)
    WebSocketCloseStatusMessageTooLarge = 1004, //indicates that an endpoint is terminating the connection
                                               //because it has received a message that is too large
    WebSocketCloseStatusNormalButMissingStatus = 1005, //designated for use in applications expecting a status code 
                                                       //to indicate that no status code was actually present
    WebSocketCloseStatusAbnormalButMissingStatus = 1006 //designated for use in	applications expecting a status code
                                                        //to indicate that the connection was closed abnormally, e.g.
                                                        //without sending or receiving a Close control frame.
};
typedef NSUInteger WebSocketCloseStatus;

enum 
{
    WebSocketReadyStateConnecting = 0, //The connection has not yet been established.
    WebSocketReadyStateOpen = 1, //The WebSocket connection is established and communication is possible.
    WebSocketReadyStateClosing = 2, //The connection is going through the closing handshake.
    WebSocketReadyStateClosed = 3 //The connection has been closed or could not be opened
};
typedef NSUInteger WebSocketReadyState;


__attribute__((deprecated))
@protocol WebSocket08Delegate <NSObject>

/**
 * Called when the web socket connects and is ready for reading and writing.
 **/
- (void) didOpen;

/**
 * Called when the web socket closes. aError will be nil if it closes cleanly.
 **/
- (void) didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError;

/**
 * Called when the web socket receives an error. Such an error can result in the
 socket being closed.
 **/
- (void) didReceiveError:(NSError*) aError;

/**
 * Called when the web socket receives a message.
 **/
- (void) didReceiveTextMessage:(NSString*) aMessage;

/**
 * Called when the web socket receives a message.
 **/
- (void) didReceiveBinaryMessage:(NSData*) aMessage;

@optional
/**
 * Called when pong is sent... For keep-alive optimization.
 **/
- (void) didSendPong:(NSData*) aMessage;

@end


__attribute__((deprecated))
@interface WebSocket08 : NSObject 
{
@private
    id<WebSocket08Delegate> delegate;
    NSURL* url;
    NSString* origin;
    AsyncSocket* socket;
    WebSocketReadyState readystate;
    NSError* closingError;
    BOOL isSecure;
    NSTimeInterval timeout;
    NSDictionary* tlsSettings;
    NSArray* protocols;
    NSString* serverProtocol;
    NSString* wsSecKey;
    NSString* wsSecKeyHandshake;
    BOOL verifyHandshake;
    NSUInteger maxPayloadSize;
    MutableQueue* pendingFragments;
    BOOL isClosing;
    NSUInteger closeStatusCode;
    NSString* closeMessage;
    BOOL sendCloseInfoToListener;
    NSTimeInterval closeTimeout;
}


/**
 * Callback delegate for websocket events.
 **/
@property(nonatomic,retain) id<WebSocket08Delegate> delegate;

/**
 * Max size of the payload. Any messages larger will be sent as fragments.
 **/
@property(nonatomic,assign) NSUInteger maxPayloadSize;

/**
 * Timeout used for sending messages, not establishing the socket connection. A
 * value of -1 will result in no timeouts being applied.
 **/
@property(nonatomic,assign) NSTimeInterval timeout;

/**
 * Timeout used for the closing handshake. If this timeout is exceeded, the socket
 * will be forced closed. A value of -1 will result in no timeouts being applied.
 **/
@property(nonatomic,assign) NSTimeInterval closeTimeout;

/**
 * URL of the websocket
 **/
@property(nonatomic,readonly) NSURL* url;

/**
 * Origin is used more in a browser setting, but it is intended to prevent cross-site scripting. If
 * nil, the client will fill this in using the url provided by the websocket.
 **/
@property(nonatomic,readonly) NSString* origin;

/**
 * Represents the state of the connection. It can have the following values:
 * - WebSocketReadyStateConnecting: The connection has not yet been established.
 * - WebSocketReadyStateOpen: The WebSocket connection is established and communication is possible.
 * - WebSocketReadyStateClosing: The connection is going through the closing handshake.
 * - WebSocketReadyStateClosed: The connection has been closed or could not be opened.
 **/
@property(nonatomic,readonly) WebSocketReadyState readystate;


/**
 * Settings for securing the connection using SSL/TLS.
 * 
 * The possible keys and values for the TLS settings are well documented.
 * Some possible keys are:
 * - kCFStreamSSLLevel
 * - kCFStreamSSLAllowsExpiredCertificates
 * - kCFStreamSSLAllowsExpiredRoots
 * - kCFStreamSSLAllowsAnyRoot
 * - kCFStreamSSLValidatesCertificateChain
 * - kCFStreamSSLPeerName
 * - kCFStreamSSLCertificates
 * - kCFStreamSSLIsServer
 * 
 * Please refer to Apple's documentation for associated values, as well as other possible keys.
 * 
 * If the value is nil or an empty dictionary, then the websocket cannot be secured.
 **/
@property(nonatomic,readonly) NSDictionary* tlsSettings;

/**
 * The subprotocols supported by the client. Each subprotocol is represented by an NSString.
 **/
@property(nonatomic,readonly) NSArray* protocols;

/**
 * True if the client should verify the handshake values sent by the server. Since many of
 * the web socket servers may not have been updated to support this, set to false to ignore
 * and simply accept the connection to the server.
 **/
@property(nonatomic,readonly) BOOL verifyHandshake; 

/**
 * The subprotocol selected by the server, nil if none was selected
 **/
@property(nonatomic,readonly) NSString* serverProtocol;


+ (id) webSocketWithURLString:(NSString*) aUrlString delegate:(id<WebSocket08Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake;
- (id) initWithURLString:(NSString *) aUrlString delegate:(id<WebSocket08Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake;


/**
 * Connect the websocket and prepare it for reading and writing.
 **/
- (void) open;

/**
 * Finish all reads/writes and close the websocket. Sends a status of WebSocketCloseStatusNormal and no message.
 **/
- (void) close;

/**
 * Finish all reads/writes and close the websocket. Sends the specified status and message.
 **/
- (void) close:(NSUInteger) aStatusCode message:(NSString*) aMessage;

/**
 * Write a UTF-8 encoded NSString message to the websocket.
 **/
- (void) sendText:(NSString*)message;

/**
 * Write a binary message to the websocket.
 **/
- (void) sendBinary:(NSData*)message;

/**
 * Send ping message to the websocket
 */
- (void) sendPing:(NSData*)message;

extern NSString *const WebSocket08Exception;
extern NSString *const WebSocket08ErrorDomain;

@end
