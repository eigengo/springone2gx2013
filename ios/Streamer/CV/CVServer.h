#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "RTSP/RTSPServer.h"

#define CV_RAW_SUPPORT

/**
 * Implement this delegate to receive notifications from the ``CVServerConnection``
 */
@protocol CVServerConnectionDelegate
/**
 * This is the 200 response from the server. The image or stream was accepted.
 */
- (void)cvServerConnectionOk:(id)response;

/**
 * This is the 202 response from the server. The image or stream was accepted, but more
 * images or streams are expected before ``-cvServerConnectionOk`` may be called.
 */
- (void)cvServerConnectionAccepted:(id)response;

/**
 * This is the 400 response from the server. The image or stream is not acceptable and
 * sending the same image or stream will not succeed.
 */
- (void)cvServerConnectionRejected:(id)response;

/**
 * The server has failed: either HTTP 500 or no connection or such like.
 */
- (void)cvServerConnectionFailed:(NSError*)reason;
@end

/**
 * Statistics about the ``CVServerConnectionInput``
 */
typedef struct {
	unsigned long networkTime;
	unsigned long networkBytes;
	unsigned int  requestCount;
} CVServerConnectionInputStats;

/**
 * Submits the frames to the server
 */
@protocol CVServerConnectionInput

/**
 * Submit a frame to the server endpoint, accepting any frame
 */
- (void)submitFrame:(CMSampleBufferRef)frame;

/**
 * Submit a frame to the server endpoint, as long as ``preflight`` returns ``true``
 */
- (void)submitFrame:(CMSampleBufferRef)frame andPreflight:(bool (^)(CGImageRef))preflight;

/**
 * Complete the stream of frames
 */
- (void)stopRunning;

/**
 * Returns the current 'stats' about the connection
 */
- (CVServerConnectionInputStats)getStats;

#ifdef CV_RAW_SUPPORT
/**
 * Submit raw data to the server endpoint
 */
- (void)submitFrameRaw:(NSData*)rawFrame;
#endif
@end

/**
 * Connects to the running transaction on the CV server
 */
@interface CVServerTransactionConnection : NSObject

/**
 * Obtains the ``CVServerConnectionInput`` that expects one frame at a time.
 */
- (id<CVServerConnectionInput>)staticInput:(id<CVServerConnectionDelegate>)delegate;

/**
 * Obtains the ``CVServerConnectionInput`` that expects stream of frames.
 */
- (id<CVServerConnectionInput>)h264Input:(id<CVServerConnectionDelegate>)delegate;

/**
 * Obtains the ``CVServerConnectionInput`` that expects stream of frames.
 */
- (id<CVServerConnectionInput>)mjpegInput:(id<CVServerConnectionDelegate>)delegate;

/**
 * Obtains the ``CVServerConnectionInput`` that expects stream of frames and that
 * hosts the stream as RTSP server on the device.
 */
- (id<CVServerConnectionInput>)rtspServerInput:(id<CVServerConnectionDelegate>)delegate url:(out NSURL**)url;

@end

/**
 * Maintains the connection to the CVServer at some URL; and constructs objects that allow you to submit frames to the
 * server and reports the outcome of the processing that the server performed.
 *
 * Typical usage is (given some ``NSURL* serverUrl`` and ``id<CVServerConnectionDelegate> delegate``:
 * ```
 * @interface X<CVServerConnectionDelegate> 
 * @end
 *
 * @implementation X {
 *   AVCaptureSession* captureSession;
 *   CVServerConnection *connection;
 *   CVServerTransactionConnection *transactionConnection;
 *   id<CVServerConnectionDelegate> input;
 * }
 *
 * - (void)initialize {
 *   connection = [CVServerConnection connect:serverUrl];
 * }
 *
 * #pragma mark - AV Capture start and stop
 *
 * // when the user decides to start capturing
 * - (void)startCapture {
 *   transactionConnection = [connection begin];
 *   input = [transactionConnection streamInput:self];
 *   // start capture session; connecting some AVVideoOutput* to self (implementing AVCaptureVideoDataOutputSampleBufferDelegate) on some queue
 *   captureSession = [[AVCaptureSession alloc] init];
 *   AVVideoOutput *videoOutput = ...
 *   [videoOutput setSampleBufferDelegate:self queue:queue];
 *   ...
 *   [captureSession startRunning];
 * }
 *
 * // when the user decides to stop capture
 * - (void)stopCapture {
 *   [captureSession stopRunning];
 *   [input stopRunning];
 * }
 * 
 * // when frames arrive
 * - (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
 *   [input submitFrame:sampleBuffer];
 * }
 *
 *
 * #pragma mark - CVServerConnectionDelegate methods
 *
 * // the CV server accepted the entire operation (potentially consisting of multiple images or streams)
 * - (void)cvServerConnectionOk:(id)response {
 *   NSLog(@":))");
 * }
 *
 * // the CV server accepted the image or stream, but more images or streams must follow
 * - (void)cvServerConnectionAccepted:(id)response {
 *   NSLog(@":)");
 * }
 *
 * // the CV server rejected the image or stream
 * - (void)cvServerConnectionRejected:(id)response {
 *   NSLog(@":(");
 * }
 *
 * // the CV server may have failed or there is no connection to it or something else catastrophic
 * - (void)cvServerConnectionFailed:(NSError *)reason {
 *   NSLog(@":((");
 * }
 *
 *
 * @end
 * ```
 */
@interface CVServerConnection : NSObject

/**
 * Creates the connection to the CV server at the given URL.
 */
+ (CVServerConnection*)connection:(NSURL*)baseUrl;

/**
 * Begins a new transaction and returns a connection to that transaction
 */
- (CVServerTransactionConnection*)begin;

@end


