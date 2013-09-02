//
//  WebSocket10.m
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

#import "WebSocket10.h"
#import "WebSocketFragment.h"


enum 
{
    WebSocketWaitingStateMessage = 0, //Starting on waiting for a new message
    WebSocketWaitingStateHeader = 1, //Waiting for the remaining header bytes
    WebSocketWaitingStatePayload = 2, //Waiting for the remaining payload bytes
    WebSocketWaitingStateFragment = 3 //Waiting for the next fragment
};
typedef NSUInteger WebSocketWaitingState;


@interface WebSocket10(Private)
- (void) dispatchFailure:(NSError*) aError;
- (void) dispatchClosed:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError;
- (void) dispatchOpened;
- (void) dispatchTextMessageReceived:(NSString*) aMessage;
- (void) dispatchBinaryMessageReceived:(NSData*) aMessage;
- (void) continueReadingMessageStream;
- (NSString*) buildOrigin;
- (NSString*) buildPort;
- (NSString*) getRequest: (NSString*) aRequestPath;
- (NSData*) getSHA1:(NSData*) aPlainText;
- (void) generateSecKeys;
- (BOOL) isUpgradeResponse: (NSString*) aResponse;
- (NSString*) getServerProtocol:(NSString*) aResponse;
- (void) sendClose:(NSUInteger) aStatusCode message:(NSString*) aMessage;
- (void) sendMessage:(NSData*) aMessage messageWithOpCode:(MessageOpCode) aOpCode;
- (void) sendMessage:(WebSocketFragment*) aFragment;
- (void) handleMessageData:(NSData*) aData;
- (void) handleCompleteFragment:(WebSocketFragment*) aFragment;
- (void) handleCompleteFragments;
- (void) handleClose:(WebSocketFragment*) aFragment;
- (void) handlePing:(NSData*) aMessage;
- (void) closeSocket;
- (void) scheduleForceCloseCheck:(NSTimeInterval) aInterval;
- (void) checkClose:(NSTimer*) aTimer;
@end


@implementation WebSocket10

NSString* const WebSocket10Exception = @"WebSocketException";
NSString* const WebSocket10ErrorDomain = @"WebSocketErrorDomain";

enum 
{
    TagHandshake = 0,
    TagMessage = 1
};

WebSocketWaitingState waitingState;

@synthesize maxPayloadSize;
@synthesize delegate;
@synthesize url;
@synthesize origin;
@synthesize readystate;
@synthesize timeout;
@synthesize closeTimeout;
@synthesize tlsSettings;
@synthesize protocols;
@synthesize verifyHandshake;
@synthesize serverProtocol;


#pragma mark Public Interface
- (void) open
{
    UInt16 port = isSecure ? 443 : 80;
    if (self.url.port)
    {
        port = [self.url.port intValue];
    }
    NSError* error = nil;
    BOOL successful = false;
    @try 
    {
        successful = [socket connectToHost:self.url.host onPort:port error:&error];
        closeStatusCode = 0;
        closeMessage = nil;
    }
    @catch (NSException *exception) 
    {
        error = [NSError errorWithDomain:WebSocket10ErrorDomain code:0 userInfo:exception.userInfo]; 
    }
    @finally 
    {
        if (!successful)
        {
            [self dispatchClosed:WebSocketCloseStatusProtocolError message:nil error:error];
        }
    }
}

- (void) close
{
    [self close:WebSocketCloseStatusNormal message:nil];
}

- (void) close:(NSUInteger) aStatusCode message:(NSString*) aMessage
{
    readystate = WebSocketReadyStateClosing;
    if ([aMessage canBeConvertedToEncoding:NSUTF8StringEncoding])
    {
        [self sendClose:aStatusCode message:aMessage];
    }
    else
    {
        [self sendClose:aStatusCode message:nil];
    }
    isClosing = YES;
}

- (void) scheduleForceCloseCheck
{
    [NSTimer scheduledTimerWithTimeInterval:self.closeTimeout
                                     target:self
                                   selector:@selector(checkClose:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void) checkClose:(NSTimer*) aTimer
{
    if (self.readystate == WebSocketReadyStateClosing)
    {
        [self closeSocket];
    }
}

- (void) sendClose:(NSUInteger) aStatusCode message:(NSString*) aMessage
{
    //create payload
    NSMutableData* payload = nil;
    if (aStatusCode > 0)
    {
        closeStatusCode = aStatusCode;
        payload = [NSMutableData data];
        unsigned char current = (unsigned char)(aStatusCode/0x100);
        [payload appendBytes:&current length:1];
        current = (unsigned char)(aStatusCode%0x100);
        [payload appendBytes:&current length:1];
        if (aMessage)
        {
            closeMessage = aMessage;
            [payload appendData:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    //send close message
    [self sendMessage:[WebSocketFragment fragmentWithOpCode:MessageOpCodeClose isFinal:YES payload:payload]];
    
    //schedule the force close
    if (self.closeTimeout >= 0)
    {
        [self scheduleForceCloseCheck];
    }
}

- (void) sendText:(NSString*) aMessage
{
    //no reason to grab data if we won't send it anyways
    if (!isClosing)
    {
        NSData* messageData = [aMessage dataUsingEncoding:NSUTF8StringEncoding];
        if (messageData)
        {
            [self sendMessage:messageData messageWithOpCode:MessageOpCodeText];
        }
        else if (aMessage)
        {
            [self close:WebSocketCloseStatusInvalidData message:nil];
        }
    }
}

- (void) sendBinary:(NSData*) aMessage
{
    [self sendMessage:aMessage messageWithOpCode:MessageOpCodeBinary];
}

- (void) sendPing:(NSData*) aMessage
{
    [self sendMessage:aMessage messageWithOpCode:MessageOpCodePing];
}

- (void) sendMessage:(NSData*) aMessage messageWithOpCode:(MessageOpCode) aOpCode
{
    if (!isClosing)
    {
        NSUInteger messageLength = [aMessage length];
        if (messageLength <= self.maxPayloadSize)
        {
            //create and send fragment
            WebSocketFragment* fragment = [WebSocketFragment fragmentWithOpCode:aOpCode isFinal:YES payload:aMessage];
            [self sendMessage:fragment];
        }
        else
        {
            NSMutableArray* fragments = [NSMutableArray array];
            unsigned int fragmentCount = messageLength / self.maxPayloadSize;
            if (messageLength % self.maxPayloadSize)
            {
                fragmentCount++;
            }
            
            //build fragments
            for (int i = 0; i < fragmentCount; i++)
            {
                WebSocketFragment* fragment = nil;
                unsigned int fragmentLength = self.maxPayloadSize;
                if (i == 0)
                {
                    fragment = [WebSocketFragment fragmentWithOpCode:aOpCode isFinal:NO payload:[aMessage subdataWithRange:NSMakeRange(i * self.maxPayloadSize, fragmentLength)]];
                }
                else if (i == fragmentCount - 1)
                {
                    fragmentLength = messageLength % self.maxPayloadSize;
                    if (fragmentLength == 0)
                    {
                        fragmentLength = self.maxPayloadSize;
                    }
                    fragment = [WebSocketFragment fragmentWithOpCode:MessageOpCodeContinuation isFinal:YES payload:[aMessage subdataWithRange:NSMakeRange(i * self.maxPayloadSize, fragmentLength)]];
                }
                else
                {
                    fragment = [WebSocketFragment fragmentWithOpCode:MessageOpCodeContinuation isFinal:NO payload:[aMessage subdataWithRange:NSMakeRange(i * self.maxPayloadSize, fragmentLength)]];
                }
                [fragments addObject:fragment];
            }
            
            //send fragments
            for (WebSocketFragment* fragment in fragments) 
            {
                [self sendMessage:fragment];
            }
        }  
    }
}

- (void) sendMessage:(WebSocketFragment*) aFragment
{
    if (!isClosing || aFragment.opCode == MessageOpCodeClose)
    {
        [socket writeData:aFragment.fragment withTimeout:self.timeout tag:TagMessage];
    }
}


#pragma mark Internal Web Socket Logic
- (void) continueReadingMessageStream 
{
    [socket readDataWithTimeout:self.timeout tag:TagMessage];
}

- (void) closeSocket
{
    readystate = WebSocketReadyStateClosing;
    [socket disconnectAfterWriting];
}

- (void) handleCompleteFragment:(WebSocketFragment*) aFragment
{
    //if we are not in continuation and its final, dequeue
    if (aFragment.isFinal && aFragment.opCode != MessageOpCodeContinuation)
    {
        [pendingFragments dequeue];
    }
    
    //continue to process
    switch (aFragment.opCode) 
    {
        case MessageOpCodeContinuation:
            if (aFragment.isFinal)
            {
                [self handleCompleteFragments];
            }
            break;
        case MessageOpCodeText:
            if (aFragment.isFinal)
            {
                if (aFragment.payloadData.length)
                {
                    NSString* textMsg = [[[NSString alloc] initWithData:aFragment.payloadData encoding:NSUTF8StringEncoding] autorelease];
                    if (textMsg)
                    {
                        [self dispatchTextMessageReceived:textMsg];
                    }
                    else
                    {
                        [self close:WebSocketCloseStatusInvalidData message:nil];
                    }
                }
            }
            break;
        case MessageOpCodeBinary:
            if (aFragment.isFinal)
            {
                [self dispatchBinaryMessageReceived:aFragment.payloadData];
            }
            break;
        case MessageOpCodeClose:
            [self handleClose:aFragment];
            break;
        case MessageOpCodePing:
            [self handlePing:aFragment.payloadData];
            break;
    }
}

- (void) handleCompleteFragments
{
    WebSocketFragment* fragment = [pendingFragments dequeue];
    if (fragment != nil)
    {
        //init
        NSMutableData* messageData = [NSMutableData data];
        MessageOpCode messageOpCode = fragment.opCode;
        
        //loop through, constructing single message
        while (fragment != nil) 
        {
            [messageData appendData:fragment.payloadData];
            fragment = [pendingFragments dequeue];
        }
        
        //handle final message contents        
        switch (messageOpCode) 
        {            
            case MessageOpCodeText:
            {
                NSString* textMsg = [[[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding] autorelease];
                if (textMsg)
                {
                    [self dispatchTextMessageReceived:textMsg];
                }
                else
                {
                    [self close:WebSocketCloseStatusInvalidData message:nil];
                }
                break;
            }
            case MessageOpCodeBinary:
                [self dispatchBinaryMessageReceived:messageData];
                break;
        }
    }
}

- (void) handleClose:(WebSocketFragment*) aFragment
{
    //close status & message
    BOOL invalidUTF8 = NO;
    if (aFragment.payloadData)
    {
        NSUInteger length = aFragment.payloadData.length;
        if (length >= 2)
        {
            //get status code
            unsigned char buffer[2];
            [aFragment.payloadData getBytes:&buffer length:2];
            closeStatusCode = buffer[0] << 8 | buffer[1];
            
            //get message
            if (length > 2)
            {
                closeMessage = [[NSString alloc] initWithData:[aFragment.payloadData subdataWithRange:NSMakeRange(2, length - 2)] encoding:NSUTF8StringEncoding];
                if (!closeMessage)
                {
                    invalidUTF8 = YES;
                }
            }
        }
    }
    
    //handle close
    if (isClosing)
    {
        [self closeSocket];
    }
    else
    {
        isClosing = YES;
        if (!invalidUTF8)
        {
            [self close:0 message:nil];
        }
        else
        {
            [self close:WebSocketCloseStatusInvalidData message:nil];
        }
    }
}

- (void) handlePing:(NSData*) aMessage
{
    [self sendMessage:aMessage messageWithOpCode:MessageOpCodePong];
    if ([delegate respondsToSelector:@selector(didSendPong:)])
    {
        [delegate didSendPong:aMessage];
    }
}

- (void) handleMessageData:(NSData*) aData
{
    //grab last fragment, use if not complete
    WebSocketFragment* fragment = [pendingFragments lastObject];
    if (!fragment || fragment.isValid)
    {
        //assign web socket fragment since the last one was complete
        fragment = [WebSocketFragment fragmentWithData:aData];
        [pendingFragments enqueue:fragment];
    }
    else
    {
        //append the data
        [fragment.fragment appendData:aData];
    }

    NSAssert(fragment != nil, @"Websocket fragment should never be nil");

    //parse the data, if possible
    if (fragment.canBeParsed)
    {
        [fragment parseContent];

        //if we have a complete fragment, handle it
        if (fragment.isValid)
        {
            [self handleCompleteFragment:fragment];
        }
    }

    //if we have extra data, handle it
    if (fragment.messageLength > 0 && ([aData length] > fragment.messageLength))
    {
        [self handleMessageData:[aData subdataWithRange:NSMakeRange(fragment.messageLength, [aData length] - fragment.messageLength)]];
    }
}

- (NSData*) getSHA1:(NSData*) aPlainText 
{
    CC_SHA1_CTX ctx;
    uint8_t * hashBytes = NULL;
    NSData * hash = nil;
    
    // Malloc a buffer to hold hash.
    hashBytes = malloc( CC_SHA1_DIGEST_LENGTH * sizeof(uint8_t) );
    memset((void *)hashBytes, 0x0, CC_SHA1_DIGEST_LENGTH);
    
    // Initialize the context.
    CC_SHA1_Init(&ctx);
    // Perform the hash.
    CC_SHA1_Update(&ctx, (void *)[aPlainText bytes], [aPlainText length]);
    // Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);
    
    // Build up the SHA1 blob.
    hash = [NSData dataWithBytes:(const void *)hashBytes length:(NSUInteger)CC_SHA1_DIGEST_LENGTH];
    
    if (hashBytes) free(hashBytes);
    
    return hash;
}

- (NSString*) buildOrigin
{
    if (self.url.port && [self.url.port intValue] != 80 && [self.url.port intValue] != 443)
    {
        return [NSString stringWithFormat:@"%@://%@:%i%@", isSecure ? @"https" : @"http", self.url.host, [self.url.port intValue], self.url.path ? self.url.path : @""];
    }
    
    return [NSString stringWithFormat:@"%@://%@%@", isSecure ? @"https" : @"http", self.url.host, self.url.path ? self.url.path : @""];
}

- (NSString*) buildHost
{
    if (self.url.port)
    {
        if ([self.url.port intValue] == 80 || [self.url.port intValue] == 443)
        {
            return self.url.host;
        }
        
        return [NSString stringWithFormat:@"%@:%i", self.url.host, [self.url.port intValue]];
    }
    
    return self.url.host;
}

- (NSString*) getRequest: (NSString*) aRequestPath
{
    [self generateSecKeys];
    if (self.protocols && self.protocols.count > 0)
    {
        //build protocol fragment
        NSMutableString* protocolFragment = [NSMutableString string];
        for (NSString* item in protocols)
        {
            if ([protocolFragment length] > 0) 
            {
                [protocolFragment appendString:@", "];
            }
            [protocolFragment appendString:item];
        }
        
        //return request with protocols
        if ([protocolFragment length] > 0)
        {
            return [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
                    "Upgrade: WebSocket\r\n"
                    "Connection: Upgrade\r\n"
                    "Host: %@\r\n"
                    "Sec-WebSocket-Origin: %@\r\n"
                    "Sec-WebSocket-Protocol: %@\r\n"
                    "Sec-WebSocket-Key: %@\r\n"
                    "Sec-WebSocket-Version: 8\r\n"
                    "\r\n",
                    aRequestPath, [self buildHost], self.origin, protocolFragment, wsSecKey];
        }
    }
    
    //return request normally
    return [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
            "Upgrade: WebSocket\r\n"
            "Connection: Upgrade\r\n"
            "Host: %@\r\n"
            "Sec-WebSocket-Origin: %@\r\n"
            "Sec-WebSocket-Key: %@\r\n"
            "Sec-WebSocket-Version: 10\r\n"
            "\r\n",
            aRequestPath, [self buildHost], self.origin, wsSecKey];
}

- (void) generateSecKeys
{
    NSString* initialString = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    NSData *data = [initialString dataUsingEncoding:NSUTF8StringEncoding];
	NSString* key = [data base64EncodedString];
    wsSecKey = [key copy];
    key = [NSString stringWithFormat:@"%@%@", wsSecKey, @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"];
    data = [self getSHA1:[key dataUsingEncoding:NSUTF8StringEncoding]];
    key = [data base64EncodedString];
    wsSecKeyHandshake = [key copy];
}

- (BOOL) isUpgradeResponse: (NSString*) aResponse
{
    //a HTTP 101 response is the only valid one
    if ([aResponse hasPrefix:@"HTTP/1.1 101"])
    {        
        //continuing verifying that we are upgrading
        NSArray *listItems = [aResponse componentsSeparatedByString:@"\r\n"];
        BOOL foundUpgrade = NO;
        BOOL foundConnection = NO;
        BOOL verifiedHandshake = !verifyHandshake;
        
        //loop through headers testing values
        for (NSString* item in listItems) 
        {
            //search for -> Upgrade: websocket & Connection: Upgrade
            if ([item rangeOfString:@"Upgrade" options:NSCaseInsensitiveSearch].length)
            {
                if (!foundUpgrade) 
                {
                    foundUpgrade = [item rangeOfString:@"WebSocket" options:NSCaseInsensitiveSearch].length;
                }
                if (!foundConnection) 
                {
                    foundConnection = [item rangeOfString:@"Connection" options:NSCaseInsensitiveSearch].length;
                }
            }
            
            //if we are verifying - do so
            if (!verifiedHandshake && [item rangeOfString:@"Sec-WebSocket-Accept" options:NSLiteralSearch].length)
            {
                //grab the key
                NSRange range = [item rangeOfString:@":" options:NSLiteralSearch];
                NSString* value = [item substringFromIndex:range.length + range.location];
                value = [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                verifiedHandshake = [wsSecKeyHandshake isEqualToString:value];
            }
            
            //if we have what we need, get out
            if (foundUpgrade && foundConnection && verifiedHandshake)
            {
                return true;
            }
        }
    }
    
    return false;
}

- (NSString*) getServerProtocol:(NSString*) aResponse
{
    //loop through headers looking for the protocol    
    NSArray *listItems = [aResponse componentsSeparatedByString:@"\r\n"];
    for (NSString* item in listItems) 
    {
        //if this is the protocol - return the value
        if ([item rangeOfString:@"Sec-WebSocket-Protocol" options:NSCaseInsensitiveSearch].length)
        {
            NSRange range = [item rangeOfString:@":" options:NSLiteralSearch];
            NSString* value = [item substringFromIndex:range.length + range.location];
            return [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        }
    }
    
    return nil;
}


#pragma mark Web Socket Delegate
- (void) dispatchFailure:(NSError*) aError 
{
    if(delegate) 
    {
        [delegate didReceiveError:aError];
    }
}

- (void) dispatchClosed:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError
{
    if (delegate)
    {
        [delegate didClose:aStatusCode message:aMessage error:aError];
    }
}

- (void) dispatchOpened 
{
    if (delegate) 
    {
        [delegate didOpen];
    }
}

- (void) dispatchTextMessageReceived:(NSString*) aMessage 
{
    if (delegate)
    {
        [delegate didReceiveTextMessage:aMessage];
    }
}

- (void) dispatchBinaryMessageReceived:(NSData*) aMessage 
{
    if (delegate)
    {
        [delegate didReceiveBinaryMessage:aMessage];
    }
}


#pragma mark AsyncSocket Delegate
- (void) onSocketDidDisconnect:(AsyncSocket*) aSock 
{
    readystate = WebSocketReadyStateClosed;
    if (closeStatusCode == 0)
    {
        if (closingError != nil)
        {
            closeStatusCode = WebSocketCloseStatusAbnormalButMissingStatus;
        }
        else
        {
            closeStatusCode = WebSocketCloseStatusNormalButMissingStatus;
        }
    }
    [self dispatchClosed:closeStatusCode message:closeMessage error:closingError];
}

- (void) onSocket:(AsyncSocket *) aSocket willDisconnectWithError:(NSError *) aError
{
    switch (self.readystate) 
    {
        case WebSocketReadyStateOpen:
        case WebSocketReadyStateConnecting:
            readystate = WebSocketReadyStateClosing;
            [self dispatchFailure:aError];
        case WebSocketReadyStateClosing:
            closingError = [aError retain]; 
    }
}

- (void) onSocket:(AsyncSocket*) aSocket didConnectToHost:(NSString*) aHost port:(UInt16) aPort 
{
    //start TLS if this is a secure websocket
    if (isSecure)
    {
        // Configure SSL/TLS settings
        NSDictionary *settings = self.tlsSettings;
        
        //seed with defaults if missing
        if (!settings)
        {
            settings = [NSMutableDictionary dictionaryWithCapacity:3];
        }
        
        [socket startTLS:settings];
    }
    
    //continue with handshake
    NSString *requestPath = self.url.path;
    if (requestPath == nil || requestPath.length == 0) {
        requestPath = @"/";
    }
    if (self.url.query)
    {
        requestPath = [requestPath stringByAppendingFormat:@"?%@", self.url.query];
    }
    NSString* getRequest = [self getRequest: requestPath];
    [aSocket writeData:[getRequest dataUsingEncoding:NSASCIIStringEncoding] withTimeout:self.timeout tag:TagHandshake];
}

- (void) onSocket:(AsyncSocket*) aSocket didWriteDataWithTag:(long) aTag 
{
    if (aTag == TagHandshake) 
    {
        [aSocket readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:self.timeout tag:TagHandshake];
    }
}

- (void) onSocket: (AsyncSocket*) aSocket didReadData:(NSData*) aData withTag:(long) aTag 
{
    if (aTag == TagHandshake) 
    {
        NSString* response = [[[NSString alloc] initWithData:aData encoding:NSASCIIStringEncoding] autorelease];
        if ([self isUpgradeResponse: response]) 
        {
            //grab protocol from server
            NSString* protocol = [self getServerProtocol:response];
            if (protocol)
            {
                serverProtocol = [protocol copy];
            }
            
            //handle state & delegates
            readystate = WebSocketReadyStateOpen;
            [self dispatchOpened];
            [self continueReadingMessageStream];
        } 
        else 
        {
            [self dispatchFailure:[NSError errorWithDomain:WebSocket10ErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Bad handshake" forKey:NSLocalizedFailureReasonErrorKey]]];
        }
    } 
    else if (aTag == TagMessage) 
    {
        //handle data
        [self handleMessageData:aData];
        
        //keep reading
        [self continueReadingMessageStream];
    }
}


#pragma mark Lifecycle
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (id) webSocketWithURLString:(NSString*) aUrlString delegate:(id<WebSocket10Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake
{
    return [[[[self class] alloc] initWithURLString:aUrlString delegate:aDelegate origin:aOrigin protocols:aProtocols tlsSettings:aTlsSettings verifyHandshake:aVerifyHandshake] autorelease];
}

- (id) initWithURLString:(NSString *) aUrlString delegate:(id<WebSocket10Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake
{
    self = [super init];
    if (self) 
    {
        //validate
        NSURL* tempUrl = [NSURL URLWithString:aUrlString];
        if (![tempUrl.scheme isEqualToString:@"ws"] && ![tempUrl.scheme isEqualToString:@"wss"]) 
        {
            [NSException raise:WebSocket10Exception format:@"Unsupported protocol %@",tempUrl.scheme];
        }
        
        //apply properties
        url = [tempUrl retain];
        self.delegate = aDelegate;
        isSecure = [self.url.scheme isEqualToString:@"wss"];
        if (aOrigin)
        {
            origin = [aOrigin copy];
        }
        else
        {
            origin = [[self buildOrigin] copy];
        }
        if (aProtocols)
        {
            protocols = [aProtocols retain];
        }
        if (aTlsSettings)
        {
            tlsSettings = [aTlsSettings retain];
        }
        verifyHandshake = aVerifyHandshake;
        socket = [[AsyncSocket alloc] initWithDelegate:self];
        self.timeout = 30.0;
        self.closeTimeout = 30.0;
        maxPayloadSize = 32*1024;
        pendingFragments = [[MutableQueue alloc] init];
        isClosing = NO;
    }
    return self;
}
#pragma clang diagnostic pop

-(void) dealloc 
{
    socket.delegate = nil;
    [socket disconnect];
    [socket release];
    [delegate release];
    [url release];
    [origin release];
    [closingError release];
    [protocols release];
    [tlsSettings release];
    [pendingFragments release];
    [closeMessage release];
    [wsSecKey release];
    [wsSecKeyHandshake release];
    [serverProtocol release];
    [super dealloc];
}

@end
