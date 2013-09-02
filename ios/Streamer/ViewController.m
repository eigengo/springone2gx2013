#import "ViewController.h"
#import "MJPEGReader.h"

#define FRAMES_PER_SECOND_MOD 5

@implementation ViewController {
	CVServerTransactionConnection *serverTransactionConnection;
	id<CVServerConnectionInput> serverConnectionInput;
	
	AVCaptureSession *captureSession;
	AVCaptureVideoPreviewLayer *previewLayer;
	int frameMod;
	
	bool capturing;
}

#pragma mark - Housekeeping

- (void)viewDidLoad {
    [super viewDidLoad];
	capturing = false;
	[self.statusLabel setText:@""];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Video capture (using the back camera)

- (CVServerConnection*)serverConnection {
	NSURL *serverBaseUrl = [NSURL URLWithString:[NSString stringWithFormat:@"ws://%@/websocket/", self.serverAddress.text]];
	return [CVServerConnection connection:serverBaseUrl];
}

- (void)startCapture {
#if !(TARGET_IPHONE_SIMULATOR)
	// Video capture session; without a device attached to it.
	captureSession = [[AVCaptureSession alloc] init];
	[captureSession setSessionPreset:AVCaptureSessionPreset640x480];
	
	// Preview layer that will show the video
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = CGRectMake(0, 100, 320, 640);
	previewLayer.contentsGravity = kCAGravityResizeAspectFill;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer:previewLayer];
	
	// begin the capture
	AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	// video output is the callback
	AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	videoOutput.alwaysDiscardsLateVideoFrames = YES;
	videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	dispatch_queue_t queue = dispatch_queue_create("VideoCaptureQueue", NULL);
	[videoOutput setSampleBufferDelegate:self queue:queue];
	
	// video input is the camera
	AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
	
	// capture session connects the input with the output (camera -> self.captureOutput)
	[captureSession addInput:videoInput];
	[captureSession addOutput:videoOutput];
	
	// start the capture session
	[captureSession startRunning];
	
	// begin a transaction
	serverTransactionConnection = [[self serverConnection] begin];
	
	// (a) using static images
	//serverConnectionInput = [serverTransactionConnection staticInput:self];
	
	// (b) using MJPEG stream
	serverConnectionInput = [serverTransactionConnection mjpegInput:self];
	
	// (c) using H.264 stream
	//serverConnectionInput = [serverTransactionConnection h264Input:self];

	// (d) using RTSP server
	//NSURL *url;
	//serverConnectionInput = [serverTransactionConnection rtspServerInput:self url:&url];
	//[self.statusLabel setText:[url absoluteString]];
#endif
}

- (void)stopCapture {
#if !(TARGET_IPHONE_SIMULATOR)
	[captureSession stopRunning];
	[serverConnectionInput stopRunning];
	
	[previewLayer removeFromSuperlayer];
	
	previewLayer = nil;
	captureSession = nil;
	serverConnectionInput = nil;
	serverTransactionConnection = nil;
#endif
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
#if !(TARGET_IPHONE_SIMULATOR)
	@autoreleasepool {
		frameMod++;
		if (frameMod % FRAMES_PER_SECOND_MOD == 0) {
			[serverConnectionInput submitFrame:sampleBuffer];
			NSLog(@"Network bytes %ld", [serverConnectionInput getStats].networkBytes);
		}
	}
#endif
}

#pragma mark - UI

- (IBAction)startStop:(id)sender {
	if (capturing) {
		[self stopCapture];
		[self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
		[self.startStopButton setTintColor:[UIColor greenColor]];
		capturing = false;
		self.predefButton.enabled = true;
	} else {
		[self startCapture];
		[self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.startStopButton setTintColor:[UIColor redColor]];
		capturing = true;
	}
}

- (IBAction)predefStopStart:(id)sender {
	self.startStopButton.enabled = false;

	serverTransactionConnection = [[self serverConnection] begin];
	serverConnectionInput = [serverTransactionConnection mjpegInput:self];
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"coins2" ofType:@"mjpeg"];
	MJPEGReader *reader = [[MJPEGReader alloc] initWithPath:filePath];
	[reader readChunks:^(NSData* data) { [serverConnectionInput submitFrameRaw:data]; } fps:20];
	[serverConnectionInput stopRunning];

	self.startStopButton.enabled = true;
}

#pragma mark - CVServerConnectionDelegate methods

- (void)cvServerConnectionOk:(id)response {
	NSLog(@":))");
}

- (void)cvServerConnectionAccepted:(id)response {
	NSLog(@":)");
}

- (void)cvServerConnectionRejected:(id)response {
	NSLog(@":(");
}

- (void)cvServerConnectionFailed:(NSError *)reason {
	NSLog(@":((");
}

@end
