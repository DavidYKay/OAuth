/* Copyright (c) 1011 Sven Weidauer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

#import "NSURLConnection+AsyncBlock.h"


@implementation NSURLConnection (AsyncBlock)

#if defined( NS_BLOCKS_AVAILABLE )
+ (void) sendAsyncRequest: (NSURLRequest *) request withBlock: (void (^)( NSData *data, NSURLResponse *resp, NSError *error )) block;
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
        dispatch_async( currentQueue, ^{
            block( data, response, error );  
        } );
    } );
}
#endif


// Format des Selektors für den callback
// receivedResponse: (NSURLResponse *) resp data: (NSData *)data error: (NSError *)error forRequest: (NSURLRequest *)request;

#if !defined( NS_BLOCKS_AVAILABLE )

static NSString * const kURLRequestKey = @"request";
static NSString * const kDelegateKey = @"delegate";
static NSString * const kSelectorKey = @"selector";


+ (void) OAuth__doRequestInBackground: (NSDictionary *)dict;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSURLRequest *request = [dict objectForKey: kURLRequestKey];
	id delegate = [dict objectForKey: kDelegateKey];
	SEL selector = [[dict objectForKey: kSelectorKey] pointerValue];
	
	NSError *error = nil;
	NSURLResponse *response = nil;
	NSData *data = [self sendSynchronousRequest: request returningResponse:&response error:&error];

	NSMethodSignature *signature = [delegate methodSignatureForSelector: selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
	[invocation setSelector: selector];
	[invocation setArgument: &response atIndex: 2];
	[invocation setArgument: &data atIndex: 3];
	[invocation setArgument: &error atIndex: 4];
	[invocation setArgument: &request atIndex: 5];
	[invocation retainArguments];
	
	[invocation performSelectorOnMainThread: @selector( invokeWithTarget: ) withObject: delegate waitUntilDone: NO];

	[pool release];
}
#endif

+ (void) sendAsyncRequest: (NSURLRequest *) request delegate: (id)delegate  completionSelector: (SEL)selector;
{
	NSAssert( [delegate respondsToSelector: selector], @"Delegate must respond to specified selector" );
#if defined( NS_BLOCKS_AVAILABLE )
	[self sendAsyncRequest: request withBlock: ^(NSData *data, NSURLResponse *resp, NSError *err ) {
		IMP imp = [delegate methodForSelector: selector];
		imp( delegate, selector, resp, data, err, request );
	}];
#else
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: 
									request, kURLRequestKey,
									delegate, kDelegateKey,
									[NSValue valueWithPointer: selector], kSelectorKey,
									nil];
	[self performSelectorInBackground: @selector(OAuth__doRequestInBackground:) withObject: parameters];
#endif
}

@end
