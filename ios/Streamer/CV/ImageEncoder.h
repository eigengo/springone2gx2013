#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 * Image format representation
 */
enum ImageFormat {
	PNG,
	JPEG
};

@interface ImageEncoder : NSObject

  /**
   * Encodes the ``CMSampleBufferRef`` by turning it into a ``CGImageRef`` and applying the
   * ``preflight`` function to it. If it returns ``true``, it will be turned into
   * the desired image format, resized, and the ``success`` function applied to the
   * bytes that make up the image.
   */
- (void)encode:(CMSampleBufferRef)frame withPreflight:(bool (^)(CGImageRef))preflight andSuccess:(void (^)(NSData*))success;

/**
 * if != nil, the compression quality for the JPEG compression. Ignored when
 * ``imageFormat`` is ``PNG``
 */
@property NSNumber *jpegImageQuality;
/**
 * The image format: either PNG or JPEG
 */
@property enum ImageFormat imageFormat;
/**
 * if != nil, the desired image size. The code will keep the aspect ratio of the image.
 * If you have 1020 * 720 image and ask it to be resized to 1020 * 800, nothing will
 * happen.
 */
@property CGSize* resizeTo;

@end
