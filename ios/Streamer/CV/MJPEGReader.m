#import "MJPEGReader.h"

@implementation MJPEGReader {
	NSString* path;
}

- (id)initWithPath:(NSString *)aPath {
	self = [super init];
	if (self) {
		path = aPath;
	}
	return self;
}

- (int)decodeInt32:(NSData*)data {
	if (data.length < 4) return 0;
	
	BytePtr bytes = (BytePtr)data.bytes;
	int b0 = (bytes[0] & 0x000000ff) << 24;
	int b1 = (bytes[1] & 0x000000ff) << 16;
	int b2 = (bytes[2] & 0x000000ff) << 8;
	int b3 = (bytes[3] & 0x000000ff);
	
	return b0 + b1 + b2 + b3;
}

- (void)readChunks:(void (^)(NSData *))block fps:(int)fps {
	NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	
	while (true) {
		NSData *data = [fileHandle readDataOfLength:4];
		int size = [self decodeInt32:data];
		if (size == 0) break;
		
		block([fileHandle readDataOfLength:size]);
		[NSThread sleepForTimeInterval:1.0 / (float)fps];
	}
	
	[fileHandle closeFile];
}

@end
