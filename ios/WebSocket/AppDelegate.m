#import "AppDelegate.h"

@implementation AppDelegate {
	WebSocket* socket;
}

- (void)wsSend {
	NSLog(@"A");
	WebSocketConnectConfig* config = [WebSocketConnectConfig configWithURLString:@"ws://192.168.0.100:8080/websocket/app/recog/mjpeg" origin:nil protocols:nil tlsSettings:nil headers:nil verifySecurityKey:NO extensions:nil];
	config.closeTimeout = 15.0;
	config.keepAlive = 15.0;
	socket = [WebSocket webSocketWithConfig:config delegate:self];
	[socket open];
	NSLog(@"B");
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
	
	[self wsSend];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - WebSocketDelegate

/**
 * Called when the web socket connects and is ready for reading and writing.
 **/
- (void) didOpen {
	NSLog(@"didOpen");
	[socket sendBinary:[@"Foobar" dataUsingEncoding:NSASCIIStringEncoding]];
//	[socket sendText:@"World"];
	[socket close];
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
