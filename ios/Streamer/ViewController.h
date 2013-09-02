#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CV/CVServer.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, CVServerConnectionDelegate>

- (IBAction)startStop:(id)sender;
- (IBAction)predefStopStart:(id)sender;

@property (nonatomic, retain) IBOutlet UIButton *startStopButton;
@property (nonatomic, retain) IBOutlet UIButton *predefButton;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UITextField *serverAddress;
@end
