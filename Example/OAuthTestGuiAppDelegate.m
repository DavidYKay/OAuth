/* Copyright (c) 1011 Sven Weidauer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

#import "OAuthTestGuiAppDelegate.h"
#import "OAuthHandshake.h"
#import "NSString+URLEncoding.h"
#import "OAuthMultiDictionary.h"
#import "OAuthMutableURLRequest.h"
#import "NSURLConnection+AsyncBlock.h"

#import <WebKit/WebKit.h>

@interface OAuthTestGuiAppDelegate () <OAuthHandshakeDelegate>
@end

@implementation OAuthTestGuiAppDelegate

@synthesize window;
@synthesize webView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    handshake = [[OAuthHandshake alloc] init];
    [handshake setTokenRequestURL:[NSURL URLWithString: @"https://api.twitter.com/oauth/request_token"]];
    [handshake setTokenAuthURL: [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]];
    [handshake setCallbackURL: @"testauth://auth"];
    [handshake setDelegate: self];
    
    NSString *consumerKey = @"<insert your consumer key here>";
	NSString *consumerSecret = @"<insert your consumer secret here>";

    [handshake setConsumerKey: consumerKey];
    [handshake setConsumerSecret: consumerSecret];
}


- (void)handshake:(OAuthHandshake *)handshake requestsUserToAuthenticateToken:(NSString *)token;
{
    [webView setHidden: NO];
    [webView setMainFrameURL: [NSString stringWithFormat: @"https://api.twitter.com/oauth/authorize?oauth_token=%@", [token URLEncodedString]]];
}

- (void)handshake:(OAuthHandshake *)handshake authenticatedToken:(NSString *)token withSecret:(NSString *)tokenSecret;
{
    [webView setHidden: YES];
}

- (IBAction)beginAuth:(id)sender 
{
    [handshake beginHandshake];
}

- (IBAction)postTweet:(id)sender 
{
    if (![handshake isAuthenticated]) return;
    
    
    NSURL *url = [NSURL URLWithString: @"http://api.twitter.com/1/statuses/update.xml"];
    OAuthMutableURLRequest *req = [handshake requestForURL:url withMethod:@"POST"];

    NSString *tweet = @"<enter tweet here>";
    NSString *message = [NSString stringWithFormat: @"status=%@", [tweet URLEncodedString]];
    [req setHTTPBody: [message dataUsingEncoding: NSASCIIStringEncoding]];
    [req setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"content-type"];
    [req sign];
    
    [NSURLConnection sendAsyncRequest: req withBlock: ^( NSData *data, NSURLResponse *resp, NSError *error ) {
        NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
        NSLog( @"sent tweet, reply: %@", string );
    }];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener;
{
    NSURL *url = [actionInformation objectForKey: WebActionOriginalURLKey];
    if ([[url scheme] isEqualToString: @"testauth"]) {
        [listener ignore];
        OAuthMultiDictionary *dict = [OAuthMultiDictionary dictionaryWithQueryString: [url query]];
        NSString *verifier = [dict objectForKey: @"oauth_verifier"];
        [handshake continueHandshakeWithVerifier: verifier];
    } else {
        [listener use];
    }
}

@end
