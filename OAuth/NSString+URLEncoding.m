#import "NSString+URLEncoding.h"

@implementation NSString (URLEncodingAdditions)

- (NSString *)URLEncodedString 
{
    return  [NSMakeCollectable( CFURLCreateStringByAddingPercentEscapes(
                                kCFAllocatorDefault, 
                                (CFStringRef)self,
                                NULL,
								CFSTR("!*'();:@&=+$,/?%#[]"),
                                kCFStringEncodingUTF8) ) autorelease];
}

- (NSString*)URLDecodedString
{
	return [NSMakeCollectable( CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                    kCFAllocatorDefault,
                                    (CFStringRef)self,
                                    CFSTR(""),
                                    kCFStringEncodingUTF8) ) autorelease];
}

@end
