/* Copyright (c) 1011 Sven Weidauer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */


#import <Foundation/Foundation.h>

@class OAuthHandshake;
@class OAuthMutableURLRequest;

@protocol OAuthHandshakeDelegate <NSObject>

@required
- (void) handshake: (OAuthHandshake *) handshake requestsUserToAuthenticateToken: (NSString *) token;

@optional
- (void) handshake: (OAuthHandshake *) handshake failedWithError: (NSError *) error;
- (void) handshake: (OAuthHandshake *) handshake authenticatedToken: (NSString *) token withSecret: (NSString *) tokenSecret;

@end

@interface OAuthHandshake : NSObject {
@private
    NSURL *tokenRequestURL;
    NSURL *tokenAuthURL;
    
    NSString *consumerKey;
    NSString *consumerSecret;
    NSString *token;
    NSString *tokenSecret;
    NSString *callbackURL;
    BOOL isAuthenticated;
    
    id <OAuthHandshakeDelegate> delegate;
}


@property (copy, nonatomic) NSURL *tokenRequestURL;
@property (copy, nonatomic) NSURL *tokenAuthURL;
@property (copy, nonatomic) NSString *consumerKey;
@property (copy, nonatomic) NSString *consumerSecret;
@property (copy, nonatomic) NSString *token;
@property (copy, nonatomic) NSString *tokenSecret;
@property (copy, nonatomic) NSString *callbackURL;
@property (assign, nonatomic) id <OAuthHandshakeDelegate> delegate;
@property (assign, readonly, getter=isAuthenticated) BOOL authenticated;

- (void) beginHandshake;
- (void) continueHandshakeWithVerifier: (NSString *) verifier;

- (OAuthMutableURLRequest *) requestForURL: (NSURL *) url withMethod: (NSString *) method;

@end
