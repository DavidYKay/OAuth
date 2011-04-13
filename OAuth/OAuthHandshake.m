/* Copyright (c) 1011 Sven Weidauer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */


#import "OAuthHandshake.h"
#import "OAuthMultiDictionary.h"
#import "OAuthMutableURLRequest.h"
#import "NSURLConnection+AsyncBlock.h"

@interface OAuthHandshake ()

@property (assign, readwrite, getter=isAuthenticated) BOOL authenticated;
- (void) _sendError: (NSError *) error;

@end

@implementation OAuthHandshake

@synthesize tokenRequestURL;
@synthesize tokenAuthURL;
@synthesize consumerKey;
@synthesize consumerSecret;
@synthesize token, tokenSecret;
@synthesize callbackURL;
@synthesize delegate;
@synthesize authenticated = isAuthenticated;

- (void) _sendError: (NSError *) error;
{
    if ([delegate respondsToSelector: @selector( handshake:failedWithError: )]) [delegate handshake: self failedWithError: error];
}

- (OAuthMutableURLRequest *) requestForURL: (NSURL *) url withMethod: (NSString *) method;
{
    OAuthMutableURLRequest *request = [[[OAuthMutableURLRequest alloc] initWithURL: url] autorelease];
    
    [request setConsumerKey: consumerKey secret: consumerSecret];
    if (token != nil) [request setToken: token secret: tokenSecret];
    
    [request setHTTPMethod: method];
    
    return request;
}

- (void) beginHandshake;
{
    [self setAuthenticated: NO];
    [self setToken: nil];
    [self setTokenSecret: nil];
    
    OAuthMutableURLRequest *request = [self requestForURL: tokenRequestURL withMethod: @"POST"];
    if (callbackURL != nil) [request setValue: callbackURL forOAuthParameter: @"oauth_callback"];
    [request sign];
    
    [NSURLConnection sendAsyncRequest: request withBlock: ^( NSData *data, NSURLResponse *response, NSError *error ) {
        if (data == nil) {
            [self _sendError: error];
            return;
        }
        
        OAuthMultiDictionary *dict = [OAuthMultiDictionary dictionaryWithQueryString: [[[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding] autorelease]];
        [self setToken: [dict objectForKey: @"oauth_token"]];
        [self setTokenSecret: [dict objectForKey: @"oauth_token_secret"]];
        
        [delegate handshake: self requestsUserToAuthenticateToken: token];
    }];
}

- (void) continueHandshakeWithVerifier: (NSString *) verifier;
{
    OAuthMutableURLRequest *request = [self requestForURL: tokenAuthURL withMethod: @"POST"];
    [request setValue: verifier forOAuthParameter: @"oauth_verifier"];
    [request sign];
    
    [NSURLConnection sendAsyncRequest: request withBlock: ^( NSData *data, NSURLResponse *response, NSError *error ) {
        if (data == nil) {
            [self _sendError: error];
            return;
        }
        
        OAuthMultiDictionary *dict = [OAuthMultiDictionary dictionaryWithQueryString: [[[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding] autorelease]];
        [self setToken: [dict objectForKey: @"oauth_token"]];
        [self setTokenSecret: [dict objectForKey: @"oauth_token_secret"]];
        
        [self setAuthenticated: YES];
        if ([delegate respondsToSelector: @selector( handshake:authenticatedToken:withSecret: )]) {
            [delegate handshake: self authenticatedToken: token withSecret: tokenSecret];            
        }
    }];
}

@end
