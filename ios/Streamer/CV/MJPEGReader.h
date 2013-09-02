#import <Foundation/Foundation.h>

@interface MJPEGReader : NSObject
- (id)initWithPath:(NSString*)path;
- (void)readChunks:(void (^)(NSData*))block fps:(int)fps;
@end
