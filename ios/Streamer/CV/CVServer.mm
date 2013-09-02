#import "CVServer.h"
#import "AFNetworking/AFHTTPRequestOperation.h"
#import "AFNetworking/AFHTTPClient.h"
#import "H264/AVEncoder.h"
#import "ImageEncoder.h"
#import "H264/NALUnit.h"
#import "WebSocket.h"

@interface AbstractCVServerConnectionInput : NSObject<WebSocketDelegate> {
@protected
	dispatch_semaphore_t socketSemaphore;
	id<CVServerConnectionDelegate> delegate;
	CVServerConnectionInputStats stats;
	ImageEncoder *imageEncoder;
	WebSocket* socket;
}
- (id)initWithUrl:(NSURL*)url andDelegate:(id<CVServerConnectionDelegate>)delegate;
- (void)initConnectionInput;
- (CVServerConnectionInputStats)getStats;
- (void)submitFrameRaw:(NSData *)rawFrame;
@end

@interface AbstractStreamingCVServerConnectionInput : AbstractCVServerConnectionInput
- (void)stopRunning;
@end

@interface CVServerConnectionInputStatic : AbstractCVServerConnectionInput<CVServerConnectionInput>
@end

@interface CVServerConnectionInputH264 : AbstractStreamingCVServerConnectionInput<CVServerConnectionInput>
@end

@interface CVServerConnectionInputMJPEG : AbstractStreamingCVServerConnectionInput<CVServerConnectionInput>
@end

@interface CVServerConnectionRTSPServer : AbstractCVServerConnectionInput<CVServerConnectionInput>
- (id)initWithRtspUrl:(NSURL *)rtspUrl andDelegate:(id<CVServerConnectionDelegate>)delegate;
@end

@implementation CVServerTransactionConnection {
	NSURL *baseUrl;
}

- (CVServerTransactionConnection*)initWithUrl:(NSURL*)aBaseUrl {
	self = [super init];
	if (self) {
		baseUrl = aBaseUrl;
	}
	return self;
}

- (NSURL*)inputUrl:(NSString*)path {
	return [baseUrl URLByAppendingPathComponent:path];
}

- (id<CVServerConnectionInput>)staticInput:(id<CVServerConnectionDelegate>)delegate {
	return [[CVServerConnectionInputStatic alloc] initWithUrl:[self inputUrl:@"app/recog/image"] andDelegate:delegate];
}

- (id<CVServerConnectionInput>)h264Input:(id<CVServerConnectionDelegate>)delegate {
	return [[CVServerConnectionInputH264 alloc] initWithUrl:[self inputUrl:@"app/recog/h264"] andDelegate:delegate];
}

- (id<CVServerConnectionInput>)mjpegInput:(id<CVServerConnectionDelegate>)delegate {
	return [[CVServerConnectionInputMJPEG alloc] initWithUrl:[self inputUrl:@"app/recog/mjpeg"] andDelegate:delegate];
}

- (id<CVServerConnectionInput>)rtspServerInput:(id<CVServerConnectionDelegate>)delegate url:(out NSURL**)url {
    NSString* ipaddr = [RTSPServer getIPAddress];
	*url = [NSURL URLWithString:[NSString stringWithFormat:@"rtsp://%@/", ipaddr]];
	CVServerConnectionRTSPServer *conn = [[CVServerConnectionRTSPServer alloc] initWithRtspUrl:*url andDelegate:delegate];
	return conn;
}

@end

#pragma mark - Connection to CV server 

@implementation CVServerConnection {
	NSURL *baseUrl;
}

- (id)initWithUrl:(NSURL *)aBaseUrl {
	self = [super init];
	if (self) {
		baseUrl = aBaseUrl;
	}
	
	return self;
}

+ (CVServerConnection*)connection:(NSURL *)baseUrl {
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	
	return [[CVServerConnection alloc] initWithUrl:baseUrl];
}

- (CVServerTransactionConnection*)begin {
	return [[CVServerTransactionConnection alloc] initWithUrl:baseUrl];
}

@end

#pragma mark - AbstractCVServerConnectionInput

@implementation AbstractCVServerConnectionInput

- (id)initWithUrl:(NSURL*)url andDelegate:(id<CVServerConnectionDelegate>)aDelegate {
	self = [super init];
	if (self == nil) return nil;
	
	stats.networkBytes = 0;
	stats.requestCount = 1;
	stats.networkTime = 0;

	delegate = aDelegate;
	imageEncoder = [[ImageEncoder alloc] init];
	WebSocketConnectConfig* config = [WebSocketConnectConfig configWithURLString:[url absoluteString]
																		  origin:nil
																	   protocols:nil
																	 tlsSettings:nil
																		 headers:nil
															   verifySecurityKey:NO
																	  extensions:nil];
	config.closeTimeout = 15.0;
	config.keepAlive = 15.0;
	socket = [WebSocket webSocketWithConfig:config delegate:self];
	socketSemaphore = dispatch_semaphore_create(0);
	[socket open];
	
	[self initConnectionInput];
	
	dispatch_semaphore_wait(socketSemaphore, DISPATCH_TIME_FOREVER);
	
	return self;
}

- (void)initConnectionInput {
	
}

- (CVServerConnectionInputStats)getStats {
	return stats;
}

- (void)submitFrameRaw:(NSData *)rawFrame {
	stats.networkBytes += rawFrame.length;
	stats.requestCount += 1;
	
	if (socket.readystate == WebSocketReadyStateOpen) {
		[socket sendBinary:rawFrame]; //[@"ABC" dataUsingEncoding:NSASCIIStringEncoding]];
	} else {
		NSLog(@"Attempting to send data with no socket open");
	}
}

#pragma mark - WebSocketDelegate methods

/**
 * Called when the web socket connects and is ready for reading and writing.
 **/
- (void) didOpen {
	dispatch_semaphore_signal(socketSemaphore);
}

/**
 * Called when the web socket closes. aError will be nil if it closes cleanly.
 **/
- (void) didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError {
	NSLog(@"didClose");
}

/**
 * Called when the web socket receives an error. Such an error can result in the
 socket being closed.
 **/
- (void) didReceiveError:(NSError*) aError {
	NSLog(@"didReceiveError %@", aError);
}

/**
 * Called when the web socket receives a message.
 **/
- (void) didReceiveTextMessage:(NSString*) aMessage {
	NSLog(@"didReceiveTextMessage %@", aMessage);
}

/**
 * Called when the web socket receives a message.
 **/
- (void) didReceiveBinaryMessage:(NSData*) aMessage {
	NSLog(@"didReceiveBinaryMessage %@", aMessage);
}

@end

#pragma mark - Single image posts

/**
 * Uses plain JPEG encoding to submit the images from the incoming stream of frames
 */
@implementation CVServerConnectionInputStatic

- (void)submitFrame:(CMSampleBufferRef)frame {
	[self submitFrame:frame andPreflight:^bool(CGImageRef) {
		return true;
	}];
}

- (void)submitFrame:(CMSampleBufferRef)frame andPreflight:(bool (^)(CGImageRef))preflight {
	[imageEncoder encode:frame withPreflight:preflight andSuccess:^(NSData* data) {
		[self submitFrameRaw:data];
	}];
}

- (void)stopRunning {
	// This is a static connection. Nothing to see here.
}

@end

#pragma mark - HTTP Streaming delegates

@implementation AbstractStreamingCVServerConnectionInput

- (void)stopRunning {
	[socket close];
}

@end

/**
 * Uses the i264 encoder to encode the incoming stream of frames. 
 */
@implementation CVServerConnectionInputH264 {
	AVEncoder* encoder;
}

- (void)initConnectionInput {
	[super initConnectionInput];
	
	encoder = [AVEncoder encoderForHeight:480 andWidth:720];
	[encoder encodeWithBlock:^int(NSArray *data, double pts) {
		for (NSData* e in data) {
			[self submitFrameRaw:e];
		}
		return 0;
	} onParams:^int(NSData *params) {
		[self submitFrameRaw:params];
		return 0;
	}];
}

- (void)submitFrame:(CMSampleBufferRef)frame {
	[encoder encodeFrame:frame];
}

- (void)submitFrame:(CMSampleBufferRef)frame andPreflight:(bool (^)(CGImageRef))preflight {
	[imageEncoder encode:frame withPreflight:preflight andSuccess:^(NSData *) {
		[encoder encodeFrame:frame];
	}];
}

@end

@implementation CVServerConnectionInputMJPEG 

- (void)submitFrame:(CMSampleBufferRef)frame {
	[self submitFrame:frame andPreflight:^bool(CGImageRef) {
		return true;
	}];
}

- (void)submitFrame:(CMSampleBufferRef)frame andPreflight:(bool (^)(CGImageRef))preflight {
	[imageEncoder encode:frame withPreflight:preflight andSuccess:^(NSData* data) {
		[self submitFrameRaw:data];
	}];
}

@end

@implementation CVServerConnectionRTSPServer {
	NSURL* rtspUrl;
	AVEncoder* encoder;
	RTSPServer *server;
}

- (id)initWithRtspUrl:(NSURL *)aRtspUrl andDelegate:(id<CVServerConnectionDelegate>)aDelegate {
	self = [super init];
	stats.networkBytes = 0;
	stats.networkTime = 0;
	stats.requestCount = 0;
	if (self) {
		delegate = aDelegate;
		rtspUrl = aRtspUrl;
		[self initConnectionInput];
	}
	return self;

}

- (void)initConnectionInput {
	encoder = [AVEncoder encoderForHeight:480 andWidth:720];
	[encoder encodeWithBlock:^int(NSArray *data, double pts) {
		server.bitrate = encoder.bitspersecond;
		if ([server connectionCount] > 0) {
			for (NSData* e in data) {
				stats.networkBytes += e.length;
			}
			[server onVideoData:data time:pts];
		}
		return 0;
	} onParams:^int(NSData *params) {
		stats.requestCount++;
		server = [RTSPServer setupListener:params];
		return 0;
	}];
}

- (void)submitFrame:(CMSampleBufferRef)frame {
	[encoder encodeFrame:frame];
}

- (void)submitFrame:(CMSampleBufferRef)frame andPreflight:(bool (^)(CGImageRef))preflight {
	[imageEncoder encode:frame withPreflight:preflight andSuccess:^(NSData *) {
		[encoder encodeFrame:frame];
	}];
}

- (void)submitFrameRaw:(NSData *)rawFrame {
	// do nothing
}

- (void)stopRunning {
	[server shutdownServer];
}

@end
