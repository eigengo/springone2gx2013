#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef struct {
	bool leftEdge;
	bool rightEdge;
	bool bottomEdge;
	bool topEdge;
	
	bool face;
	
	bool focus;
} DocumentPreflightResult;

@interface DocumentPreflight : NSObject
- (DocumentPreflightResult)preflight:(CGImageRef)frame;
@end
