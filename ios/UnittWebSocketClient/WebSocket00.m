//
//  WebSocket00.m
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

#import "WebSocket00.h"


@interface WebSocket00(Private)
- (void) dispatchFailure:(NSError*) aError;
- (void) dispatchClosed:(NSError*) aWasClean;
- (void) dispatchOpened;
- (void) dispatchMessageReceived:(NSString*) aMessage;
- (void) readNextMessage;
- (NSString*) buildOrigin;
- (NSString*) buildHost;
- (NSString*) getRequest:(NSString*) aRequestPath;
- (NSData*) getMD5:(NSData*) aPlainText;
- (void) generateSecKeys;
- (BOOL) isUpgradeResponse: (NSString*) aResponse;
- (NSString*) getServerProtocol:(NSString*) aResponse;
@end


@implementation WebSocket00

NSString* const WebSocket00Exception = @"WebSocketException";
NSString* const WebSocket00ErrorDomain = @"WebSocketErrorDomain";

enum 
{
    TagHandshake = 0,
    TagMessage = 1
};


@synthesize delegate;
@synthesize url;
@synthesize origin;
@synthesize readystate;
@synthesize timeout;
@synthesize tlsSettings;
@synthesize protocols;
@synthesize verifyHandshake;
@synthesize serverProtocol;
@synthesize useKeys;


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
    }
    @catch (NSException *exception) 
    {
        error = [NSError errorWithDomain:WebSocket00ErrorDomain code:0 userInfo:exception.userInfo]; 
    }
    @finally 
    {
        if (!successful)
        {
            [self dispatchClosed:error];
        }
    }
}

- (void) close
{
    readystate = WebSocketReadyStateClosing;
    [socket disconnectAfterWriting];
}

- (void) send:(NSString*) aMessage
{
    NSMutableData* data = [NSMutableData data];
    [data appendBytes:"\x00" length:1];
    [data appendData:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:"\xFF" length:1];
    [socket writeData:data withTimeout:self.timeout tag:TagMessage];
}


#pragma mark Internal Web Socket Logic
- (void) readNextMessage 
{
    [socket readDataToData:[NSData dataWithBytes:"\xFF" length:1] withTimeout:self.timeout tag:TagMessage];
}

- (NSData*) getMD5:(NSData*) aPlainText 
{
    unsigned char result[16];
    CC_MD5( aPlainText.bytes, [aPlainText length], result );
    return [NSData dataWithBytes:result length:16];
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

// TODO: use key1, key2, key3 handshake stuff
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
                    "Origin: %@\r\n"
                    "Sec-WebSocket-Protocol: %@\r\n"
                    "\r\n",
                    aRequestPath, [self buildHost], self.origin, protocolFragment];
        }
    }
    
    //return request normally
    return [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
            "Upgrade: WebSocket\r\n"
            "Connection: Upgrade\r\n"
            "Host: %@\r\n"
            "Origin: %@\r\n"
            "\r\n",
            aRequestPath, [self buildHost], self.origin];
}

int randFromRange(int min, int max)
{
    return (arc4random() % max) + min;
}

- (NSData*) createRandomBytes
{
    NSMutableData* result = [NSMutableData data];
    for (int i = 0; i < 8; i++) 
    {
        unichar byte = randFromRange(48,122);
        [result appendBytes:&byte length:1];
    }
    return result;
}

- (NSString*) insertRandomCharacters: (NSString*) aString
{
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSString* result = aString;
    int count = randFromRange(1, 12);
    
    for (int i = 0; i < count; i++) 
    {
        int split = randFromRange(1, [result length] - 1);
        NSString* part1 = [result substringWithRange:NSMakeRange(0, split)];
        NSString* part2 = [result substringWithRange:NSMakeRange(split, [result length] - split)];
        result = [NSString stringWithFormat:@"%@%c%@", part1, [letters characterAtIndex: randFromRange(0, [letters length])], part2];
    }
    
    return result;
}

- (NSString*) insertSpaces:(int) aSpaces string:(NSString*) aString
{
    NSString* result = aString;
    for (int i = 0; i < aSpaces; i++) 
    {
        int split = randFromRange(1, [result length] - 1);
        NSString* part1 = [result substringWithRange:NSMakeRange(0, split)];
        NSString* part2 = [result substringWithRange:NSMakeRange(split, [result length] - split)];
        result = [NSString stringWithFormat:@"%@ %@", part1, part2];
    }
    
    return result;
}

- (void) generateSecKeys
{
    int spaces1 = randFromRange(1,12);
    int spaces2 = randFromRange(1,12);
    
    int max1 = INT32_MAX / spaces1;
    int max2 = INT32_MAX / spaces2;
    
    int number1 = randFromRange(0, max1);
    int number2 = randFromRange(0, max2);
    
    int product1 = number1 * spaces1;
    int product2 = number2 * spaces2;
    
    key1 = [NSString stringWithFormat:@"%i", product1];
    key2 = [NSString stringWithFormat:@"%i", product2];
    
    key1 = [self insertRandomCharacters:key1];
    key2 = [self insertRandomCharacters:key2];
    
    key1 = [[self insertSpaces:spaces1 string:key1] copy];
    key2 = [[self insertSpaces:spaces2 string:key2] copy];
    
    key3 = [[self createRandomBytes] retain];
    
    NSMutableData* challenge = [NSMutableData data];
    int key1int = [key1 intValue];
    int key2int = [key2 intValue];
    [challenge appendBytes:(char*)&key1int length:4];
    [challenge appendBytes:(char*)&key2int length:4];
    [challenge appendBytes:[key3 bytes] length:8];
    
    serverHandshake = [[self getMD5:challenge] retain];
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
            if (!verifiedHandshake)
            {
                NSData* handshakeData = [item dataUsingEncoding:NSASCIIStringEncoding];
                verifiedHandshake = [handshakeData rangeOfData:serverHandshake options:NSDataSearchBackwards range:NSMakeRange(0, [handshakeData length])].length > 0;
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

- (void) dispatchClosed:(NSError*) aError
{
    if (delegate)
    {
        [delegate didClose: aError];
    }
}

- (void) dispatchOpened 
{
    if (delegate) 
    {
        [delegate didOpen];
    }
}

- (void) dispatchMessageReceived:(NSString*) aMessage 
{
    if (delegate)
    {
        [delegate didReceiveMessage:aMessage];
    }
}


#pragma mark AsyncSocket Delegate
- (void) onSocketDidDisconnect:(AsyncSocket*) aSock 
{
    readystate = WebSocketReadyStateClosed;
    [self dispatchClosed: closingError];
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
    NSLog(@"Request path: %@", requestPath);
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
            [self readNextMessage];
        } 
        else 
        {
            [self dispatchFailure:[NSError errorWithDomain:WebSocket00ErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Bad handshake" forKey:NSLocalizedFailureReasonErrorKey]]];
        }
    } 
    else if (aTag == TagMessage) 
    {
        unsigned char firstByte = 0xFF;
        [aData getBytes:&firstByte length:1];
        if (firstByte != 0x00) return; // Discard message
        NSString* message = [[[NSString alloc] initWithData:[aData subdataWithRange:NSMakeRange(1, [aData length]-2)] encoding:NSUTF8StringEncoding] autorelease];
        [self dispatchMessageReceived:message];
        [self readNextMessage];
    }
}


#pragma mark Lifecycle
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (id) webSocketWithURLString:(NSString*) aUrlString delegate:(id<WebSocket00Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake
{
    return [[[[self class] alloc] initWithURLString:aUrlString delegate:aDelegate origin:aOrigin protocols:aProtocols tlsSettings:aTlsSettings verifyHandshake:aVerifyHandshake] autorelease];
}

+ (id) webSocketWithURLString:(NSString*) aUrlString delegate:(id<WebSocket00Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake useKeys:(BOOL) aUseKeys
{
    return [[[[self class] alloc] initWithURLString:aUrlString delegate:aDelegate origin:aOrigin protocols:aProtocols tlsSettings:aTlsSettings verifyHandshake:aVerifyHandshake useKeys:aUseKeys] autorelease];
}


- (id) initWithURLString:(NSString *) aUrlString delegate:(id<WebSocket00Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake
{
    self = [super init];
    if (self) 
    {
        //validate
        NSURL* tempUrl = [NSURL URLWithString:aUrlString];
        if (![tempUrl.scheme isEqualToString:@"ws"] && ![tempUrl.scheme isEqualToString:@"wss"]) 
        {
            [NSException raise:WebSocket00Exception format:@"Unsupported protocol %@",tempUrl.scheme];
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
        verifyHandshake = NO;
        useKeys = false;
        socket = [[AsyncSocket alloc] initWithDelegate:self];
        self.timeout = 30.0;
    }
    return self;
}

- (id) initWithURLString:(NSString *) aUrlString delegate:(id<WebSocket00Delegate>) aDelegate origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings verifyHandshake:(BOOL) aVerifyHandshake useKeys:(BOOL) aUseKeys
{
    self = [super init];
    if (self) 
    {
        //validate
        NSURL* tempUrl = [NSURL URLWithString:aUrlString];
        if (![tempUrl.scheme isEqualToString:@"ws"] && ![tempUrl.scheme isEqualToString:@"wss"]) 
        {
            [NSException raise:WebSocket00Exception format:@"Unsupported protocol %@",tempUrl.scheme];
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
        verifyHandshake = NO;
        useKeys = aUseKeys;
        socket = [[AsyncSocket alloc] initWithDelegate:self];
        self.timeout = 30.0;
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
    [key1 release];
    [key2 release];
    [key3 release];
    [serverHandshake release];
    [serverProtocol release];
    [super dealloc];
}

@end
