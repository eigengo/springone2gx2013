#import <UIKit/UIKit.h>
#import "WebSocket.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, WebSocketDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
