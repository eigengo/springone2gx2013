#import "ImageEncoder.h"

@implementation ImageEncoder

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image {
	// Create image rectangle with current image width/height
	CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
	
	// Grayscale color space
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	// Create bitmap content with current image size and grayscale colorspace
	CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
	
	// Draw image into current context, with specified rectangle
	// using previously defined context (with grayscale colorspace)
	CGContextDrawImage(context, imageRect, [image CGImage]);
	
	// Create bitmap image info from pixel data in current context
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	
	// Create a new UIImage object
	UIImage *newImage = [UIImage imageWithCGImage:imageRef];
	
	// Release colorspace, context and bitmap information
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CFRelease(imageRef);
	
	// Return the new grayscale image
	return newImage;
}

- (void)encode:(CMSampleBufferRef)frame withPreflight:(bool (^)(CGImageRef))preflight andSuccess:(void (^)(NSData *))success {

	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(frame);
	// Lock the image buffer
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	// Get information about the image
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	// Create a CGImageRef from the CVImageBufferRef
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	//CGContextRef newContext;
	CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	CGImageRef newImage = CGBitmapContextCreateImage(newContext);
	
	// We release some components
	CGContextRelease(newContext);
	CGColorSpaceRelease(colorSpace);

	// preflight
	bool accepted = true;
	if (preflight != nil) accepted = preflight(newImage);
	
	if (accepted) {
		// scale & save
		UIImage *image = [UIImage imageWithCGImage:newImage];
		image = [self convertImageToGrayScale:image];
		image = [self imageWithImage:image scaledToSize:CGSizeMake(600, 400)];
		NSData *jpeg = UIImageJPEGRepresentation(image, 0.3);
		
		success(jpeg);
	}
	
	// We relase the CGImageRef
	CGImageRelease(newImage);
	
	// We unlock the  image buffer
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
